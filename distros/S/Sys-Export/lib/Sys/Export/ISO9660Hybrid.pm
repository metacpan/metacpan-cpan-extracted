package Sys::Export::ISO9660Hybrid;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Write ISO9660 filesystem overlaid on MBR+GPT partition EFI filesystem

use v5.26;
use warnings;
use experimental qw( signatures );
use Carp;
use Sys::Export qw( isa_hash isa_handle isa_array write_file_extent expand_stat_shorthand round_up_to_multiple S_ISDIR );
use Sys::Export::LogAny '$log';
use Sys::Export::GPT;
use Sys::Export::ISO9660 qw( BOOT_EFI );
use Sys::Export::VFAT;
use constant {
   ISO_SECTOR_SIZE => Sys::Export::ISO9660::LBA_SECTOR_SIZE,
   GPT_TYPE_ESP    => 'C12A7328-F81F-11D2-BA4B-00A0C93EC93B',
   GPT_TYPE_GRUB   => '21686148-6449-6E6F-744E-656564454649', # 'Hah!IdontNeedEFI'
};
use Exporter 'import';
our @EXPORT_OK= qw( GPT_TYPE_ESP GPT_TYPE_GRUB );


sub new($class, @attrs) {
   my %attrs= @attrs != 1? @attrs
            : isa_hash $attrs[0]? %{$attrs[0]}
            : isa_handle $attrs[0]? ( filehandle => $attrs[0] )
            : ( filename => $attrs[0] );
   my $self= bless {
         iso => Sys::Export::ISO9660->new,
         esp => Sys::Export::VFAT->new,
         gpt => Sys::Export::GPT->new(
            block_size => 4096,
            partitions => [
               { type => GPT_TYPE_ESP, name => 'UEFI System Partition' },
            ],
         ),
         dual_files => [],
      }, $class;
   # apply other attributes
   $self->$_($attrs{$_}) for keys %attrs;
   $self;
}


sub filename { @_ > 1? ($_[0]{filename}= $_[1]) : $_[0]{filename} }
sub filehandle { @_ > 1? ($_[0]{filehandle}= $_[1]) : $_[0]{filehandle} }


sub iso($self) { $self->{iso} }
sub esp($self) { $self->{esp} }
sub gpt($self) { $self->{gpt} }


sub volume_label {
   if (@_ > 1) {
      $_[0]->iso->volume_label($_[1]);
      $_[0]->esp->volume_label($_[1]);
   }
   $_[0]->iso->volume_label;
}


sub mbr_boot_code($self, @v) {
   if (@v) {
      my $data= ref $v[0]? $v[0] : \$v[0];
      my $sector0= substr($$data, 0, 512);
      carp "boot_code contains nonzero bytes in partition table area"
         unless length($sector0) <= 446 || substr($sector0, 446, 64) =~ /^\0+\z/;
      $self->{mbr_boot_code}= \$sector0;
   }
   $self->{mbr_boot_code};
}


sub partitions { shift->gpt->partitions(@_) }


sub add($self, $fileinfo) {
   $fileinfo= { expand_stat_shorthand($fileinfo) }
      if isa_array $fileinfo;
   my $is_dir= S_ISDIR($fileinfo->{mode}||0);
   if ($is_dir) {
      $self->iso->add($fileinfo);
      return $self->esp->add($fileinfo);
   } else {
      my $vfile= $self->esp->add({ %$fileinfo, device_align => ISO_SECTOR_SIZE });
      # prevent ISO9660 from assigning a LBA to this file.
      my $ifile= $self->iso->add({ %$fileinfo, data => undef, device_offset => -1 });
      push @{$self->{dual_files}}, [ $vfile, $ifile ];
      return $vfile;
   }
}


sub finish($self) {
   my $fh= $self->filehandle;
   if (!$fh) {
      defined $self->filename or croak "Must set filename or filehandle attributes";
      open $fh, '+>', $self->filename
         or croak "open: $!";
   }
   my ($iso, $esp, $gpt4k)= ($self->iso, $self->esp, $self->gpt);
   $iso->filehandle($fh);
   $esp->filehandle($fh);
   # Add the El Torrito ESP entry, but we don't know the offset yet
   # This lets ISO9660 know that it needs to reserve a boot catalog.
   my $esp_catalog_entry= $iso->add_boot_catalog_entry(
      platform => BOOT_EFI,
      device_offset => 0,
      size => 0,
   );
   # Choose LBA extents for all the directory structures and files other than the shared ones
   # we marked as device_offset => -1
   $iso->allocate_extents;
   # Now we know how much space the ISO structures and filesystem occupy, and can place all
   # partitions after that.
   my $ofs= $iso->volume_size;
   # ISO9660 leaves the first 16 2K blocks empty.  We need to fit a GPT512 header @512, a GPT4K
   # header @4K, and a partition table for each from the remaining 24K, so 12K each, 24 entries
   # with the default entry_size.
   my $gpt512= Sys::Export::GPT->new(
      %$gpt4k,
      block_size => 512,
      partitions => [ map +{ %$_, block_size => 512 }, $gpt4k->partitions->@* ]
   );
   my $table_bytes_needed= $gpt4k->entry_size * $gpt4k->partitions->@*;
   if ($table_bytes_needed <= 3*1024) {
      $gpt512->entry_table_lba(2); # block immediately after the header, ofs=1K
      $gpt4k->entry_table_lba(2);  # block immediately after the header, ofs=8K
   } elsif ($table_bytes_needed <= 12*1024) {
      $gpt512->entry_table_lba(16); # block following 4K header, ofs=8K
      $gpt4k->entry_table_lba(5);   # block following 512table, ofs=20K
   } else { # no room, so tables need to go after the ISO data
      $gpt512->entry_table_lba($ofs / 512);
      $ofs= round_up_to_multiple($ofs + $table_bytes_needed, 4096);
      $gpt4k->entry_table_lba($ofs / 4096);
      $ofs+= $table_bytes_needed;
   }

   # Now choose locations for all the partitions
   $ofs= round_up_to_multiple($ofs, 4096);
   $gpt512->first_block($ofs/512);
   $gpt4k->first_block($ofs/4096);
   for my $i (0 .. $#{$gpt4k->partitions}) {
      my $p= $gpt4k->partitions->[$i];
      $ofs= round_up_to_multiple($ofs, $gpt4k->partition_align // 4096);
      # This algorithm doesn't currently account for partitons that the user
      # placed manually.
      croak "partion $i already has start_lba defined" if defined $p->start_lba;
      $p->device_offset($ofs);
      if ($p->type eq GPT_TYPE_ESP && !$esp->volume_offset) {
         # Now we know the device offset for the partition containing VFAT
         $esp->volume_offset($p->device_offset);
         # Now we can write the VFAT and get device addresses for all its files
         $esp->finish;
         $p->size(round_up_to_multiple($esp->geometry->total_size, 4096));
         $esp_catalog_entry->{extent}->device_offset($p->device_offset);
         $esp_catalog_entry->{extent}->size($p->size);
      } elsif (!$p->size) {
         # was data supplied?
         if ($p->data) {
            $p->size(round_up_to_multiple(length ${$p->data}, 4096));
         } else {
            croak "Partiton $i lacks size" unless $p->size;
         }
      }
      $gpt512->partitions->[$i]->device_offset($p->device_offset);
      $gpt512->partitions->[$i]->size($p->size);
      $ofs= $p->device_offset + $p->size;
   }
   $ofs= round_up_to_multiple($ofs, 4096);
   # Is the file already sized larger than the amount of remaining space we need?
   my $table_size_in_4k= round_up_to_multiple($table_bytes_needed, 4096);
   my $need_size= $ofs + $table_size_in_4k * 2 + 4096;
   my $size= -s $fh;
   if ($size < $need_size) {
      truncate($fh, $need_size) || croak "Can't resize file";
      $size= $need_size;
   }
   # work backward from end of device
   $gpt512->backup_header_lba(int($size / 512) - 1);
   $gpt4k->backup_header_lba(int($size / 4096) - 1);
   $ofs= $gpt4k->backup_header_lba * 4096 - $table_size_in_4k;
   $gpt4k->backup_table_lba($ofs / 4096);
   $ofs -= $table_size_in_4k;
   $gpt512->backup_table_lba($ofs / 512);
   $gpt512->last_block($ofs / 512 - 1);
   $gpt4k->last_block($ofs / 4096 - 1);

   # Now point all the ISO and VFAT files to the same extents
   for ($self->{dual_files}->@*) {
      my ($vfile, $ifile)= @$_;
      die "BUG: unaligned file" if $vfile->device_offset % ISO_SECTOR_SIZE;
      $ifile->size($vfile->size);
      $ifile->device_offset($vfile->device_offset);
   }
   # Now we can write the ISO9660
   $iso->finish;
   # Now write the partition tables.  Write the 4K one first because the 512 will overwrite
   # the tail of 4k's backup header.
   $gpt4k->write_to_file($fh);
   $gpt512->write_to_file($fh);
   # Last, write the 440 bytes of boot loader if supplied by the user
   if ($self->mbr_boot_code) {
      write_file_extent($fh, 0, 440, $self->mbr_boot_code, 0, 'Boot Code');
   }
}

# Avoiding dependency on namespace::clean
delete @{Sys::Export::ISO9660Hybrid::}{qw(
   carp croak confess write_file_extent expand_stat_shorthand round_up_to_multiple
   isa_hash isa_handle isa_array S_ISDIR BOOT_EFI
)};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::ISO9660Hybrid - Write ISO9660 filesystem overlaid on MBR+GPT partition EFI filesystem

=head1 SYNOPSIS

  my $dst= Sys::Export::ISO9660Hybrid->new(
    output => $filename_or_handle,
  );   
  $dst->add(...); # add directory entries, cached in memory
  $dst->finish;   # builds ISO9660 & VFAT filesystem, and GPT partitions

=head1 DESCRIPTION

This module helps you generate a "isohybrid" image which is both an iso9660 image and a
GPT-labeled disk image (with both 4K and 512b GPT tables) with one VFAT EFI partition.
Unlike with the C<xorriso> tool, your files are visible in both filesystems simultaneously,
and the files point to the same disk extents.

This image is also capable of booting in four different modes (assuming you provide appropriate
boot loaders):

=over

=item Legacy BIOS, Disk

Legacy i386 BIOS executes the first 440 bytes of the first sector as i386 instructions.  Those
instructions are free to do whatever they want.  GRUB 2 uses them to read a GPT partition label
and locate a partition where "stage 1.5" of the boot loader is found.  The rest of the grub boot
loader then locates the EFI partition, and finds the main boot loader files in C<< boot/grub >>
of that volume.

=item Legacy BIOS, CDROM

Legacy i386 BIOS looks through the CDROM Volume Descriptor entries looking for an entry that
describes an extent which is a virtual floppy disk image.  It then loads that extent as if it
were a floppy disk, which means it essentially just starts executing it.
This image is large enough that it doesn't require GRUB stage 1 to be split into two parts.
GRUB then loads stage 2 from the ISO filesystem, which are the same files described by the
ESP VFAT filesystem.

=item UEFI, Disk

UEFI expects a GPT-labeled disk with a special EFI System Partition which is formatted as VFAT
and which contains a file C<< \EFI\BOOT\BOOTX64.EFI >>.  It executes this file as an EFI
application.

=item UEFI, CDROM

UEFI looks through the CDROM Volume Descriptors for an entry that lists an extent of sectors
containing a EFI VFAT filesystem.  This extent is essentially the same as a partition.
It then loads C<< \EFI\BOOT\BOOTX64.EFI >> the same as if it were a disk.

=back

All the specifications above can co-exist in the same image.  CDROM images leave the first
16 sectors empty, which is enough for a GPT partition data structure, and GPT leaves the first
sector empty which is enough for the 440 bytes of legacy boot code.  The GPT label can list
partitions that exist anywhere in the image, and the CDROM Volume Descriptors can refer to
extents anywhere in the image, so the EFI partition can be referenced by each of them.
Additionally, the CDROM's filesystem can refer to extents anywhere on the image, so it can
refer to the bodies of VFAT files as long as they are aligned to 2KiB boundaries and not
fragmented.  This module takes care of all of that alignment.

=head1 CONSTRUCTORS

=head2 new

  $fat= Sys::Export::ISO9660Hybrid->new($filename_or_handle);
  $fat= Sys::Export::ISO9660Hybrid->new(%attrs);
  $fat= Sys::Export::ISO9660Hybrid->new(\%attrs);

This takes a list of attributes as a hashref or key/value list.  If there is exactly one
argument, it is treated as the C<filename> or C<filehandle> attribute.

=head1 ATTRIBUTES

=head2 filename

Name of file (or device) to write.  If the file exists it will be truncated before writing.
If you want to write the filesystem amid existing data (like a partition table), pass a file
handle as C<filehandle>.

=head2 filehandle

Output filehandle to write.  The file will be enlarged with C<truncate> if needed.

=head2 iso

An instance of L<Sys::Export::ISO9660>.

=head2 esp

An instance of L<Sys::Export::VFAT> for the EFI System Partition (ESP).

=head2 gpt

An instance of L<Sys::Export::GPT> aligned for 4K block sizes.  A GPT for 512b block size
matching the 4K one is generated during L</finish>.  It must have one partition defined as
C<< { type => GPT_TYPE_ESP } >>, but you may add any number of others.

If you define other partitions, you must assign the size and leave the start_lba undefined,
so that this module can choose the placement.  (After L</finish> you can come back to inspect
the location of your partition and make other changes to the disk image.)

=head2 volume_label

Returns ISO volume_label.  If written, sets both C<iso> and C<esp> volume label attributes to
the new value.  Note that while ESP is usually given a volume label like "ESP", for a removable
read-only image you probably want to give it a distinct name to avoid being confused with the
ESP of your installed OS on your main drive.

=head2 mbr_boot_code

File data (scalar-ref or C<LazyFileData|Sys::Export::LazyFileData>) which will be written to
the first 440 bytes of sector 0.  The data can be any length; only the first 440 bytes will be
used.

=head2 partitions

Shortcut for C<< ->gpt->partitions >>.

=head1 METHODS

=head2 add

  $dst->add(\%fileinfo);

Adds a file or directory to both VFAT and ISO filesystems.  Returns the VFAT file/directroy
object.

=head2 finish

  $dst->finish;

Calculates the size of the ISO filesystem directories, then calculates the size of the VFAT
filesystem, then updates the ISO filesystem to refer to extents within VFAT, then writes GPT
and MBR partition tables.

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
