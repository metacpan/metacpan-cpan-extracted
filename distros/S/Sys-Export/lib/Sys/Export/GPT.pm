package Sys::Export::GPT;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Implementation of GUID Partition Table

use v5.26;
use warnings;
use experimental qw( signatures );
use Scalar::Util qw( blessed );
use List::Util qw( min max );
use Encode qw( encode );
use Sys::Export::LogAny '$log';
use Sys::Export qw( write_file_extent isa_array isa_pow2 isa_handle round_up_to_multiple );
use Sys::Export::GPT::Partition;
use Carp;


sub new($class, %attrs) {
   my $self= bless {
      block_size => 512,
      entry_size => 128,
      entry_table_lba => 2,
      partitions => [],
      partition_align => 4096,
   }, $class;
   # Some fields need to be initialized in a specific order:
   $self->block_size(delete $attrs{block_size}) if defined $attrs{block_size};
   # The rest have no interdependencies
   for (keys %attrs) {
      my $m= $self->can($_) or croak "Unknown attribute '$_'";
      $m->($self, $attrs{$_});
   }
   $self;
}


sub block_size($self, @v) {
   if (@v) {
      croak "Not a power of 2" unless isa_pow2 $v[0];
      $self->{block_size}= $v[0];
      $_->block_size($v[0]) for @{ $self->{partitions} // [] };
   }
   $self->{block_size};
}


sub device_size($self, @v) {
   if (@v) {
      croak "Not a multiple of block_size" if $v[0] & ($self->block_size - 1);
      $self->{device_size}= $v[0];
   }
   $self->{device_size}
}


sub entry_size($self, @v) {
   if (@v) {
      croak "Not a power of 2 >= 128" unless isa_pow2 $v[0] && $v[0] >= 128;
      $self->{entry_size}= $v[0];
   }
   $self->{entry_size};
}


sub partitions($self, @v) {
   if (@v) {
      croak "Not an arrayref" unless isa_array $v[0];
      $self->{partitions}= [ map $_ && Sys::Export::GPT::Partition->coerce($_), @{$v[0]} ];
      $_->block_size($self->block_size) for grep defined, $self->{partitions}->@*;
   }
   $self->{partitions} // [];
}

sub partition_align { @_ > 1? ($_[0]{partition_align}= $_[1]) : $_[0]{partition_align} }


sub guid              { @_ > 1? ($_[0]{guid}= $_[1])              : $_[0]{guid} }
sub entry_table_lba   { @_ > 1? ($_[0]{entry_table_lba}= $_[1])   : $_[0]{entry_table_lba} }
sub backup_header_lba { @_ > 1? ($_[0]{backup_header_lba}= $_[1]) : $_[0]{backup_header_lba} }
sub backup_table_lba  { @_ > 1? ($_[0]{backup_table_lba}= $_[1])  : $_[0]{backup_table_lba} }
sub first_block       { @_ > 1? ($_[0]{first_block}= $_[1])       : $_[0]{first_block} }
sub last_block        { @_ > 1? ($_[0]{last_block}= $_[1])        : $_[0]{last_block} }

# Generates a random GUID in the format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
# Tries to read from /dev/urandom first (or /dev/random as fallback), then falls back to
# Perl's rand() if those aren't available (e.g., on Windows).
sub _generate_guid {
   my @bytes;
   
   # Try /dev/urandom first (non-blocking), then /dev/random
   for my $dev ('/dev/urandom', '/dev/random') {
      if (open my $fh, '<:raw', $dev) {
         if (read($fh, my $bytes, 16) == 16) {
            @bytes= unpack 'C*', $bytes;
            last;
         }
      }
   }
   
   # Fallback to rand() if /dev/random not available (Windows, etc)
   @bytes= map int(rand 256), 1..16 unless @bytes;
   
   # Set version (4) and variant (RFC 4122) bits
   $bytes[6] = ($bytes[6] & 0x0f) | 0x40;  # Version 4
   $bytes[8] = ($bytes[8] & 0x3f) | 0x80;  # Variant 10xx
   
   # Format as GUID string
   sprintf '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x', @bytes;
}


sub choose_missing_geometry($self, $device_size= undef) {
   $device_size //= $self->device_size;
   my $pttn= $self->{partitions};
   my $bs= $self->block_size;
   # Determine number of partition entries.  128 ought to be the defaut, but Sys::Export is
   # all about generating minimal images, so just round up to a whole block.
   my $n_entries= max( scalar @$pttn, 1 );
   my $entries_per_block= $bs / $self->entry_size;
   $n_entries= round_up_to_multiple($n_entries, $entries_per_block)
      if $entries_per_block > 1;
   $#$pttn= $n_entries - 1; # update array length to match

   my $n_table_blocks= $n_entries / $entries_per_block;

   my $end_lba= int($device_size / $bs) - 1;

   # header is located at 1, so entries can begin at 2.
   $self->{entry_table_lba} //= 2;

   # first_block can start right after that
   $self->{first_block} //= $self->{entry_table_lba} + $n_table_blocks;

   # Assign position for any partition not yet defined
   my $lba_pos= $self->first_block;
   my $block_align= $self->partition_align / $bs;
   for (grep defined, @$pttn) {
      round_up_to_multiple($lba_pos, $block_align) if $block_align > 1;
      $_->block_size($self->block_size);
      if (defined $_->start_lba) {
         croak "Partition ".$_->name." start_lba ".$_->start_lba." < first_block ".$self->first_block
            if $_->start_lba < $self->first_block;
      } else {
         $_->start_lba($lba_pos);
      }
      unless (defined $_->end_lba) {
         # Choose based on data size, if available
         if ($_->data) {
            my $s= blessed($_->data)? $_->data->size : length ${$_->data};
            $_->size(round_up_to_multiple($s, $self->block_size));
            $log->debugf("set partition '%s' size to %d based on data length %d",
               $_->name, $_->size, $s);
         } else {
            croak "No end_lba for partition ".$_->name
         }
      }
      $log->debugf("partition '%s' start=0x%X end=0x%X", $_->name, $_->start_lba, $_->end_lba);
      $lba_pos= $_->end_lba + 1 if $_->end_lba >= $lba_pos;
   }
   my $max_part_lba= $lba_pos-1;

   # If building a minimal image, last_block ends at the maximum partition extent.
   # But if the handle is an actual block device, or a file larger than max partition,
   # then count backward from the actual end.
   my $min_end_lba= max($max_part_lba, $self->{last_block}//0) + 1 + $n_table_blocks;
   $log->debugf("end_lba = %s, max_part_lba = %s, last_block = %s, need end_lba >= %s",
      $end_lba, $max_part_lba, $self->{last_block}, $min_end_lba);
   if ($end_lba <= $min_end_lba) {
      $self->{last_block} //= $max_part_lba;
      $self->{backup_table_lba} //= $self->{last_block} + 1;
      $self->{backup_header_lba} //= $self->{backup_table_lba} + $n_table_blocks;
   } else {
      # work backward from end_lba
      $self->{backup_header_lba} //= $end_lba;
      $self->{backup_table_lba} //= $self->{backup_header_lba} - $n_table_blocks;
      $self->{last_block} //= $self->{backup_table_lba} - 1;
   }
   $end_lba= max($end_lba, $self->{backup_header_lba});
   $log->debugf("entry_table = %s, first_block = %s, last_block = %s, backup_table = %s, backup_header = %s, end_lba = %s",
      $self->{entry_table_lba}, $self->{first_block}, $self->{last_block}, $self->{backup_table_lba},
      $self->{backup_header_lba}, $end_lba);

   # Sanity checks
   $self->entry_table_lba + $n_table_blocks <= $self->first_block
      or croak "entry array collides with partition area";

   $self->last_block >= $self->first_block
      or croak "last_block less than first_block";

   !defined $pttn->[$_]
      || $self->first_block <= $pttn->[$_]->start_lba && $pttn->[$_]->end_lba <= $self->last_block
      || croak "partition $_ exceeds range of [first_block, last_block]"
      for 0..$#$pttn;

   $self->last_block < $self->backup_table_lba
      or croak "partition area collides with backup partition entry array";

   $self->backup_table_lba + $n_table_blocks <= $self->backup_header_lba
      or croak "backup_header_lba at lower LBA than end of backup partition entry array";
}


sub write_to_file($self, $fh) {
   croak "No filehandle provided" unless isa_handle $fh;
   my $partitions= $self->{partitions};
   my $bs= $self->block_size;

   # choose a GUID if not set
   defined $self->guid or $self->guid(_generate_guid);

   my $size= -s $fh;
   $self->choose_missing_geometry($size);

   my $max_lba= $self->backup_header_lba;
   my $need_size= ($max_lba + 1) * $bs;
   if ($size < $need_size) {
      truncate($fh, $need_size)
         or croak "Can't extend file handle to $need_size bytes";
   } else {
      $max_lba= int($size / $bs) - 1;
   }

   # Encode partition entries
   my $entries_data= join '', map $self->_pack_partition_entry($_), @$partitions;
   
   # Calculate partition entries CRC
   my $entries_crc= _crc32($entries_data);
   
   # Write protective MBR at LBA 0, but don't alter first 446 bytes of boot loader
   write_file_extent($fh, 446, $bs-446,
      \$self->_pack_protective_mbr($max_lba), 446, 'Protective MBR');
   
   # Write primary GPT header at LBA 1
   write_file_extent($fh, 1 * $bs, $bs,
      \$self->_pack_header(0, $entries_crc), 0, 'Primary GPT header');
   
   # Write primary partition entries (probably at LBA 2)
   write_file_extent($fh, $self->entry_table_lba * $bs, length $entries_data,
      \$entries_data, 0, 'Primary partition entries');

   # If any partition defined data, write that
   for (grep defined && defined $_->data, @$partitions) {
      write_file_extent($fh, $_->start_lba * $bs, $_->size,
         $_->data, 0, 'Partition '.$_->name);
   }

   # Write backup partition entries
   write_file_extent($fh, $self->backup_table_lba * $bs, length $entries_data,
      \$entries_data, 0, 'Backup partition entries');
   
   # Write backup GPT header at last LBA
   write_file_extent($fh, $self->backup_header_lba * $bs, $bs,
      \$self->_pack_header(1, $entries_crc), 0, 'Backup GPT header');
   
   return 1;
}

# Creates a protective MBR partiton that marks the entire disk as GPT.
# This gets written at offset 446 within the first block and overwrites all 4 partition entries.
# This also includes the final 2-byte boot signature.
sub _pack_protective_mbr($self, $max_lba) {
   pack '@446 C C C C C C C C V V @510 v',
      # Boot code area and disk ID uses first 446 bytes
      # Partition entry 1: Protective GPT partition
      0x00,                     # Status (inactive)
      0x00, 0x02, 0x00,         # CHS start (0/2/0)
      0xEE,                     # Type (GPT protective)
      0xFF, 0xFF, 0xFF,         # CHS end (max)
      1,                        # LBA start
      min($max_lba, 0xFFFFFFFF),# LBA end
      # skip to 510, pack automatically adds nul bytes for next 3 partitions
      # Boot signature
      0xAA55;
}

# Pure Perl implementation of CRC32 using the standard polynomial (0xEDB88320).
sub _crc32($data) {
   state @table= map {
         my $crc= $_;
         $crc= ($crc & 1)? (0xEDB88320 ^ ($crc >> 1)) : ($crc >> 1)
            for 1..8;
         $crc
      } 0..255;

   my $crc = 0xFFFFFFFF;
   $crc= $table[($crc ^ $_) & 0xFF] ^ ($crc >> 8)
      for unpack 'C*', $data;
   return $crc ^ 0xFFFFFFFF;
}

# Convert a hex-notation GUID to binary in the Microsoft encoding
sub _pack_guid($guid) {
   # Microsoft GUIDs are a LE 32-bit int, two LE 16 bit ints, 2 bytes and 6 bytes.
   # The 8 bytes can be processed as big-endian ints, making it appear mixed-endian.
   my @ints= (lc($guid) =~ /^([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})([0-9a-f]{8})\z/)
      or croak "Invalid GUID format '$guid'";
   pack 'VvvnnN', map hex, @ints;
}

# Encodes a single partition entry as a 128-byte binary structure.
sub _pack_partition_entry($self, $part) {
   return "\0" x $self->entry_size unless defined $part;
   # Only encode if partition has required fields
   defined $part->start_lba or croak "Undefined start LBA";
   defined $part->end_lba   or croak "Undefined end LBA";
   defined $part->type      or croak "Missing type attribute";
   defined $part->guid      or $part->guid(_generate_guid);
   my $name_max= $self->entry_size - 56;
   my $name_utf16= encode('UTF-16LE', $part->name // '');
   carp "Partition name '".part->name."' was truncated" if length $name_utf16 > $name_max;
   $part->block_size($self->block_size); # ensure accurate LBA numbers
   pack 'a16 a16 Q< Q< Q< a'.$name_max,
      _pack_guid($part->type), _pack_guid($part->guid), $part->start_lba, $part->end_lba,
      $part->flags // 0, $name_utf16
}

# Encodes a GPT header (primary or backup)
sub _pack_header($self, $is_backup, $entries_crc) {
   my $header_lba = $is_backup ? $self->backup_header_lba : 1;
   my $alt_header_lba = $is_backup ? 1 : $self->backup_header_lba;
   my $entries_lba = $is_backup ? $self->backup_table_lba : $self->entry_table_lba;
   my $num_entries = scalar @{$self->partitions};
   # Build header without CRC first
   my $header = pack('a8 V V V V Q< Q< Q< Q< a16 Q< V V V',
      'EFI PART',              # Signature
      0x00010000,              # Revision 1.0
      92,                      # Header size
      0,                       # CRC32 (placeholder)
      0,                       # Reserved
      $header_lba,             # Current LBA
      $alt_header_lba,         # Alternate LBA
      $self->first_block,      # First usable LBA
      $self->last_block,       # Last usable LBA
      _pack_guid($self->guid), # Disk GUID
      $entries_lba,            # Partition entries LBA
      $num_entries,            # Number of entries
      $self->entry_size,       # Size of entry
      $entries_crc             # Partition entries CRC32
   );
   
   # Calculate and insert header CRC
   my $header_crc = _crc32($header);
   substr($header, 16, 4) = pack('V', $header_crc);
   return $header;
}

# Avoiding dependency on namespace::clean
delete @{Sys::Export::GPT::}{qw(
   carp croak confess blessed min max encode write_file_extent round_up_to_multiple
   isa_array isa_handle isa_pow2
)};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::GPT - Implementation of GUID Partition Table

=head1 SYNOPSIS

  use Sys::Export::GPT;
  my $gpt= Sys::Export::GPT->new(
    partitions => [
      { type => $esp_guid,  start_lba => 42, end_lba => 12345 },
      { type => $grub_guid, start_lba => 12346, end_lba => 13579, data => \$grub_core },
    ],
  );
  $gpt->write_to_file($fh);

=head1 DESCRIPTION

This module writes a GUID Partition Table (GPT) into a file handle.  It is intended mainly for
writing disk images, not installing GPT onto an actual disk, but could be used for that purpose.
The defaults of this module deviate a bit from what a normal 'fdisk' would write; the default
partition alignment is 4KiB rather than 1MiB, and it sizes the partition table to hold only as
many partition entries as you supply rather than reserving space for the standard 128 entries.
Beware that the layout of GPT is dependent on the device's reported block size, and that GPT's
backup header should be located in the final block of the device which depends on the device
size.

When writing to a file, the file size is used if it is larger than the described data, but if
the file is too small the file is enlarged to exactly as many blocks as required.

=head1 CONSTRUCTORS

=head2 new

  my $gpt= Sys::Export::GPT->new(%attrs);

=head1 ATTRIBUTES

=head2 block_size

Size of disk blocks reported to BIOS by your drive.  The default is 512, which is what almost
all removable media will report.  Note that if a drive reports 4K to BIOS, the partition tables
need to use 4K LBA addresses instead of 512 LBA addresses, which this module will handle for
you.

=head2 device_size

If set, this must be a multiple of block_size.  It can be used to choose defaults for
C<backup_header_lba>, C<backup_table_lba>, and C<last_block>.  If not set, you need to set
values for all those other attributes.

=head2 entry_size

Default is 128 bytes, which is standard.  You can set it to a larger power of 2 if you want to
make room for longer partition text labels, but this is uncommon and BIOS support may vary.

=head2 guid

Hex notation GUID; unique identifier for this disk.  It will be chosen randomly (and using weak
rand() calls unless /dev/random exists) if you don't set it before calling L</write_to_file>.

=head2 partitions

Arrayref of L<Partition|Sys::Export::GPT::Partition> objects.  Hashrefs in the array will be
coerced to Partition objects. Undefined elements of the array are encoded as unused partition
entries.  Set the length of the partitions array to determine how many overall entries get
written.  (GPT normally has 128 entries, but permits fewer)

Partition objects will have their block_size set to match the L</block_size> of this object.
(If you modify the array afterward, you need to set block_size on them yourself, or write to
the L</block_size> attribute again)

=head2 partition_align

Power of 2 in bytes.  When automatically choosing partition locations during
L</choose_missing_geometry>, this aligns the C<start_lba> to a byte boundary.

=head2 entry_table_lba

LBA of the partition entries table.  This will default to 2.

=head2 backup_header_lba

LBA of a backup of the GPT header

=head2 backup_table_lba

LBA of a backup of the partition entries table.

=head2 first_block

Declares to other partitioning tools the first usable block for allocating a partition.
This will default to the first block after the partition entries table.

=head2 last_block

Declares to other partitioning tools the last usable block for allocating a partition.
This will default to the last block before the backup partition entries table.

=head2 choose_missing_geometry

  $gpt->choose_missing_geometry($device_size_in_bytes);

This calculates default values for the attributes C<entry_table_lba>, C<backup_header_lba>,
C<backup_table_lba>, C<first_block>, C<last_block>, and chooses the C<start_lba> of any
partition that didn't have one yet (aligned to C<partition_align>).

If the space required by your partitions and GPT structures is larger than
C<$device_size_in_bytes>, this will choose block addresses beyond C<$device_size_in_bytes>
under the assumption that we are writing a file that can be enlarged.  If you are writing to an
actual block device of fixed size, you can check whether C<backup_header_lba> is the last block
of the device before calling C<write_to_file>.

This makes the assumption that partitions are in ascending order, and does not check for
overlaps.  It does check if they exceed C<first_block> or C<last_block>.

=head2 write_to_file

  $gpt->write_to_file($fh);

Writes the complete GPT structure to the given filehandle, including:

  - Protective MBR (LBA 0, but excluding first 446 bytes of boot loader)
  - Primary GPT header (LBA 1)
  - Partition entry array (LBA 2+)
  - Any partition with defined ->data
  - Backup partition entry array (end of disk)
  - Backup GPT header (last LBA)

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
