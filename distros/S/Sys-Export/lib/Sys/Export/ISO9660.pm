package Sys::Export::ISO9660;

our $VERSION= 0; our $VERSION = '0.005'; # VERSION
# ABSTRACT: Write ISO9660 filesystems with Joliet filename and El Torrito boot catalog support


use v5.26;
use warnings;
use experimental qw( signatures );
use Fcntl qw( S_IFDIR S_ISDIR S_ISREG SEEK_SET SEEK_END );
use Scalar::Util qw( blessed dualvar refaddr weaken );
use List::Util qw( min max sum );
use Time::HiRes 'time';
use POSIX 'ceil';
use Sys::Export qw( isa_hash isa_handle isa_array write_file_extent expand_stat_shorthand );
use Sys::Export::LogAny '$log';
use Encode qw( encode decode );
use constant {
   FLAG_HIDDEN      => dualvar(0x01, 'FLAG_HIDDEN'),      # hidden file
   FLAG_DIRECTORY   => dualvar(0x02, 'FLAG_DIRECTORY'),   # directory
   FLAG_ASSOCIATED  => dualvar(0x04, 'FLAG_ASSOCIATED'),  # associated file
   FLAG_RECORD      => dualvar(0x08, 'FLAG_RECORD'),      # record format
   FLAG_PROTECTION  => dualvar(0x10, 'FLAG_PROTECTION'),  # permissions
   FLAG_MULTIEXTENT => dualvar(0x80, 'FLAG_MULTIEXTENT'), # continued in another extent
   LBA_SECTOR_SIZE  => 2048,
   LBA_SECTOR_POW2  => 11,
   BOOT_X86 => dualvar(   0, 'x86'),
   BOOT_PPC => dualvar(   1, 'PowerPC'),
   BOOT_MAC => dualvar(   2, 'Mac'),
   BOOT_EFI => dualvar(0xEF, 'EFI'),
   EMU_NONE      => dualvar(0, 'EMU_NONE'),
   EMU_FLOPPY12  => dualvar(1, 'EMU_FLOPPY12'),
   EMU_FLOPPY144 => dualvar(2, 'EMU_FLOPPY144'),
   EMU_FLOPPY288 => dualvar(3, 'EMU_FLOPPY288'),
   EMU_HDD       => dualvar(4, 'EMU_HDD'),
};
sub _sector_of($addr) { $addr >> LBA_SECTOR_POW2 }
sub _remaining_sector_bytes($pos) { -$pos & (LBA_SECTOR_SIZE-1) }
sub _round_to_whole_sector($len) { ($len + LBA_SECTOR_SIZE - 1) & ~(LBA_SECTOR_SIZE-1) }
require Sys::Export::ISO9660::File;
require Sys::Export::ISO9660::Directory;
use Carp;
our @CARP_NOT= qw( Sys::Export Sys::Export::Unix );
use Exporter 'import';
our @EXPORT_OK= qw(
   FLAG_HIDDEN FLAG_DIRECTORY FLAG_ASSOCIATED FLAG_RECORD FLAG_PROTECTION FLAG_MULTIEXTENT
   is_valid_shortname is_valid_joliet_name remove_invalid_shortname_chars
   LBA_SECTOR_SIZE LBA_SECTOR_POW2 BOOT_X86 BOOT_PPC BOOT_MAC BOOT_EFI
   EMU_NONE EMU_FLOPPY12 EMU_FLOPPY144 EMU_FLOPPY288 EMU_HDD
);


sub new($class, @attrs) {
   my %attrs= @attrs != 1? @attrs
            : isa_hash $attrs[0]? %{$attrs[0]}
            : isa_handle $attrs[0]? ( filehandle => $attrs[0] )
            : ( filename => $attrs[0] );
   my $self= bless {
      root => Sys::Export::ISO9660::Directory->new(name => '/'),
      # Sectors 0-15 are reserved
      # + one sector for Primary Volume Descriptor
      # + one sector for Secondary Volume Descriptor
      # + one sector for boot catalog descriptor, if used
      # + Volume Descriptor Set Terminator
      _free_invlist => [ 19 ], # add one when boot_catalog initialized
   }, $class;
   # apply other attributes
   $self->$_($attrs{$_}) for keys %attrs;
   $self;
}

# Create dir, and store a strong reference in ->{_subdirs}
sub _new_dir($self, $name, $parent, $file) {
   my $dir= Sys::Export::ISO9660::Directory->new(name => $name, parent => $parent, file => $file);
   $self->{_subdirs}{refaddr $dir}= $dir;
   $dir;
}
sub _new_file($self, $name, %attrs) {
   Sys::Export::ISO9660::File->new(name => $name, %attrs);
}


sub filename { @_ > 1? ($_[0]{filename}= $_[1]) : $_[0]{filename} }
sub filehandle { @_ > 1? ($_[0]{filehandle}= $_[1]) : $_[0]{filehandle} }


sub root { $_[0]{root} }


sub volume_label {
   @_ > 1? ($_[0]{volume_label}= _validate_volume_label($_[1])) : $_[0]{volume_label}
}
sub _validate_volume_label($label) {
   $label= uc $label;
   croak "Volume label must be 0..32 uppercase letters, digits, underscore, or space characters"
      unless $label =~ /^[A-Z0-9_ ]{0,32}\z/;
   $label;
}

sub system {
   @_ > 1? ($_[0]{system}= _validate_system_id($_[1])) : $_[0]{system}
}
sub _validate_system_id($label) {
   $label= uc $label;
   croak "System ID must be 0..32 uppercase ASCII characters (excluding several punctuation)"
      unless $label =~ m{^ [- !"%&'()*+,./0-9:;<=>?A-Z_]{0,32} \z}x;
   $label;
}

sub volume_set {
   @_ > 1? ($_[0]{volume_set}= _validate_volume_set_id($_[1])) : $_[0]{volume_set}
}
sub _validate_volume_set_id($label) {
   $label= uc $label;
   croak "Volume Set ID must be 0..64 uppercase letters, digits, underscore, or space characters"
      unless $label =~ /^[A-Z0-9_ ]{0,64}\z/; # 128, but Joliet encodes as UTF16
   $label;
}

for (qw( publisher preparer application )) {
   eval "sub $_ { \@_ > 1? (\$_[0]{$_}= _validate_meta_label(\$_[1], '$_')) : \$_[0]{$_} } 1" or die "$@";
}
sub _validate_meta_label($x, $field='Metadata label') {
   # Metadata labels can either be a text label of the "a-characters" (most of ascii)
   # or a file object to refer to a file containing the data.
   unless (blessed $x && $x->can('device_offset')) {
      $x= uc $x;
      croak "$field must be 0..64 uppercase ASCII characters (excluding some punctuation)"
         unless $x =~ m{^ [- !"%&'()*+,./0-9:;<=>?A-Z_]{0,64} \z}x;
   }
   $x;
}

for (qw( copyright_file abstract_file bibliographic_file )) {
   eval "sub $_ { \@_ > 1? (\$_[0]{$_}= _validate_meta_filename(\$_[1], '$_')) : \$_[0]{$_} } 1" or die "$@";
}
sub _validate_meta_filename($x, $field='Metadata filename') {
   unless (blessed $x && $x->can('device_offset')) {
      $x= uc $x;
      croak "$field must be a valid 8.3 filename"
         unless $x =~ m{^ [A-Z0-9_]{1,8} (\.[A-Z0-9_]{0,3})? (;[0-9]+)? \z}x;
   }
   $x;
}


sub boot_catalog { $_[0]{boot_catalog} }


sub add_boot_catalog_entry($self, %attrs) {
   my ($platform, $section_id, $bootable, $media_type, $load_segment, $system_type)
      = delete @attrs{qw( platform section_id bootable media_type load_segment system_type )};
   my ($extent, $device_offset, $size, $data)
      = delete @attrs{qw( extent device_offset size data )};
   croak "Unknown attribute ".join(', ', keys %attrs)
      if keys %attrs;
   croak "require platform"
      unless defined $platform;

   $extent //= Sys::Export::Extent->new(name => "Boot Catalog $platform Boot Image");
   $extent->device_offset($device_offset) if defined $device_offset;
   if (defined $data) {
      # Convert to scalar-ref if scalar
      $data= do { my $x= $data; \$x } unless ref $data;
      $size //= length $$data;
   }
   $extent->size($size) if defined $size;

   $bootable //= 0x88; # bootable by default
   $media_type //= $platform == BOOT_EFI? EMU_NONE
                 # If boot loader is larger than a floppy, probably doesn't rely on emulation
                 : ($extent->size//0) > 1474560? EMU_NONE
                 # standard floppy emulation
                 : EMU_FLOPPY144;
   # load segment is the memory address BIOS loads the image into before running the boot loader
   $load_segment //= $media_type == EMU_NONE? 0 : 0x7C0;
   # System type for floppy isn't relevant, and HDD emulation would have its own MBR with
   # the system types defined.
   $system_type //= $platform == BOOT_EFI? 0xEF : 0;
   $section_id //= $platform == BOOT_X86 ? 'x86'
                 : $platform == BOOT_PPC ? 'PowerPC'
                 : $platform == BOOT_MAC ? 'Mac'
                 : $platform == BOOT_EFI ? 'UEFI'
                 : "Platform $platform";

   if (!$self->{boot_catalog}) {
      # Ensure sector needed by boot catalog descriptor wasn't already reserved,
      # e.g. adding boot entries after calling allocate_extents
      # This logic needs enhanced if other descriptors become optional.
      croak "Cannot add boot_catalog after allocating sector 19"
         unless $self->{_free_invlist}[0] == 19;
      $self->{_free_invlist}[0]++;
   }

   my $sections= $self->{boot_catalog}{sections} //= [];
   my ($sec)= grep $_->{platform} == $platform && $_->{id_string} eq $section_id, @$sections;
   if (!defined $sec) {
      push @$sections, ($sec= {
         platform  => $platform,
         id_string => $section_id,
         entries   => []
      });
   }
   push $sec->{entries}->@*, {
      bootable     => $bootable,
      media_type   => $media_type,
      load_segment => $load_segment,
      system_type  => $system_type,
      extent       => $extent,
   };
   return $sec->{entries}[-1];
}


sub default_time {
   @_ > 1? ($_[0]{default_time}= $_[1]) : $_[0]{default_time}
}


sub volume_size($self) { $self->{_free_invlist}[-1] * 2048 }


sub is_valid_shortname($name) {
   !!($name =~ /^[A-Z0-9_~]{1,8} (\. [A-Z0-9_]{1,3} )? \z/x)
}

sub is_valid_joliet_name($name) {
   !!($name =~ m{^[^\x00-\x1F\\/;\x7F-\x9F]{1,127}\z}x)
}

sub remove_invalid_shortname_chars($name, $replacement='_') {
   $name =~ tr/a-z/A-Z/; # perform 'uc' but only for the ASCII range
   $name =~ s/[^A-Z0-9_]+/$replacement/gr;
}


sub add($self, $spec) {
   $spec= { expand_stat_shorthand($spec) }
      if isa_array $spec;

   defined $spec->{uname} or defined $spec->{name}
      or croak "Require 'uname' or 'name'";
   defined $spec->{mode} or croak "Require 'mode'";

   # If user supplied uname, use that as a more official source of Unicode
   my $path= $spec->{uname} // decode('UTF-8', $spec->{name}, Encode::FB_CROAK | Encode::LEAVE_SRC);
   $path =~ s,^/,,; # remove leading slash, if any

   croak "ISO9660 has a max path length of 255 (253 with ';1' version suffix), at '$path'"
      if length($path) > 253;
   my @path= grep length, split '/', $path;
   my $leaf= pop @path;
   croak "ISO9660 has a max subdirectory depth of 7, at '$path'"
      if @path > 7; # It's documented as 8, but includes the root directory

   # Walk through the tree based on the case-folded path
   my $parent= $self->root;
   for (@path) {
      my $ent= $parent->entry($_);
      if ($ent) {
         croak $ent->name." is not a directory, while attempting to add '$path'"
            unless $ent->{dir};
      } else { # Auto-create directory. Autovivication is indicated by ->{file} = undef
         $ent= $parent->add($_, undef);
         my $name= ($parent == $self->root? '' : $parent->name) . "/$_";
         weaken($ent->{dir}= $self->_new_dir($name, $parent, undef));
      }
      $parent= $ent->{dir};
   }

   my $flags= $spec->{ISO9660_flags};
   my $file;
   if (S_ISREG($spec->{mode})) {
      my ($size, $offset, $data_ref)
         = @{$spec}{qw( size device_offset data )};
      $data_ref= do { my $x= $data_ref; \$x }
         if defined $data_ref && !ref $data_ref;
      if ($size) {
         # ensure data matches
         croak "File $path ->{data} length disagrees with ->{size}"
            if $data_ref && length($$data_ref) != $size;
      } elsif (defined $data_ref) {
         $size //= length($$data_ref);
      }
      $file= $self->_new_file("/$path", size => $size, flags => $flags, mtime => $spec->{mtime},
                              device_offset => $offset, data => $data_ref);
   } elsif (S_ISDIR($spec->{mode})) {
      $flags |= FLAG_DIRECTORY;
      # If adding this directory overtop a previous auto-vivified directory, the ->{file}
      # will be empty and we can just update it.
      my $cur= $parent->entry($leaf);
      croak "Attempt to add duplicate directory $leaf"
         if $cur && $cur->{file};
      $file= $self->_new_file("/$path", size => 0, flags => $flags, mtime => $spec->{mtime});
      if ($cur) {
         $cur->{file}= $file;
         $cur->{dir}{file}= $file;
         $log->debugf("updated attributes of %s", $path);
         return $file;
      }
      # otherwise, add this file to a directory entry
   }
   else {
      # TODO: add conditional symlink support via hardlinks
      croak "Can only export files or directories into VFAT"
   }

   # this also checks for name collisions on shortname
   my $ent= $parent->add($leaf, $file, shortname => $spec->{ISO9660_shortname});
   # If the dirent is a directory, also add a directory object to the dirent
   if ($file->is_dir) {
      # the directory object also gets a reference to its file object.
      weaken($ent->{dir}= $self->_new_dir("/$path", $parent, $file));
   }

   $log->debugf("added %s longname=%s shortname=%s %s",
      $path, $ent->{name}, $ent->{shortname}, (
         !$ent->{file}? 'size=0 (empty file)'
         : $ent->{file}->is_dir? 'DIR'
         : sprintf("size=0x%X device_offset=0x%X",
            $ent->{file}->size, $ent->{file}->device_offset//0)
      ))
      if $log->is_debug;

   $file;
}


sub finish($self) {
   $self->{default_time} //= time;
   # Choose LBA extents for everything
   $self->allocate_extents;

   my $fh= $self->filehandle;
   if (!$fh) {
      defined $self->filename or croak "Must set filename or filehandle attributes";
      open $fh, '+>', $self->filename
         or croak "open: $!";
   }
   # check size / truncate larger
   my $size= $self->volume_size;
   if (-s $fh < $size) {
      truncate($fh, $size) or croak "truncate(iso, $size): $!";
   }
   $self->_write_filesystem($fh);
   unless ($self->filehandle) {
      $fh->close or croak "close: $!";
   }
   1;
}

# Write a ISO9660::File object to its configured extent, and clear its ->{data}
sub _write_file($fh, $file) {
   defined $file->size || defined $file->data or die "BUG: file $file->{name} has no size or data";
   my $size= _round_to_whole_sector($file->size // length ${$file->data});
   write_file_extent($fh, $file->device_offset, $size, $file->data, 0, $file->name)
      if $size && defined $file->data;
   $file->data(undef); # free up memory as we go, also deallocates mmaps
}

# Write all descriptors, path tables, directories, and any file with ->{data}.
# Note that _write_file removes ->data form the file as it is written.
sub _write_filesystem($self, $fh) {
   my $boot_catalog= $self->boot_catalog;
   my $lba= 16;
   # Write Primary Volume Descriptor
   write_file_extent($fh, $lba++ * LBA_SECTOR_SIZE, LBA_SECTOR_SIZE,
      \$self->_pack_primary_volume_descriptor, 0, 'Primary Volume Descriptor');
   # Write Secondary Volume Descriptor (Joliet)
   write_file_extent($fh, $lba++ * LBA_SECTOR_SIZE, LBA_SECTOR_SIZE,
      \$self->_pack_joliet_volume_descriptor, 0, 'Joliet Volume Descriptor');
   # Write boot catalog if present
   write_file_extent($fh, $lba++ * LBA_SECTOR_SIZE, LBA_SECTOR_SIZE,
      \$self->_pack_boot_catalog_descriptor, 0, 'Boot Catalog Descriptor')
      if $boot_catalog;
   # Volume Set Terminator
   write_file_extent($fh, $lba++ * LBA_SECTOR_SIZE, LBA_SECTOR_SIZE,
      \"\xFFCD001\x01", 0, 'Volume Set Terminator');

   # Boot catalog
   if ($boot_catalog) {
      $self->_pack_boot_catalog;
      _write_file($fh, $boot_catalog->{extent});
      
      # Write any supplied data for boot entry
      for my $sec ($boot_catalog->{sections}->@*) {
         $_->{extent} && _write_file($fh, $_->{extent}) for $sec->{entries}->@*;
      }
   }

   # Write path tables
   $self->_pack_path_tables;
   _write_file($fh, $_) for $self->{path_tables}->@{qw( le be jle jbe )};

   # Write directory entries
   my @dirs= sort { $a->file->device_offset <=> $b->file->device_offset }
      $self->root, values $self->{_subdirs}->%*;
   for (@dirs) {
      $self->_pack_directory($_);
      $_ && _write_file($fh, $_) for $_->file, $_->joliet_file;
   }

   # Add any non-directory files that have data defined
   for my $dir (@dirs) {
      $_->{file} && _write_file($fh, $_->{file}) for $dir->entries->@*;
   }
}


sub allocate_extents {
   my $self= shift;
   my $assign_lba= sub {
      my $sec_size= ceil(($_->size // 0) / LBA_SECTOR_SIZE);
      if ($sec_size && !defined $_->device_offset) {
         # Allocate sectors for this file.  Can't assign via lba attribute because the
         # boot_catalog entry extents are 512-byte blocks
         $_->device_offset($self->_allocate_sectors($sec_size) * LBA_SECTOR_SIZE);
      } elsif ($sec_size && $_->device_offset > 0) {
         # make sure these sectors are reserved
         $self->_mark_sectors_reserved($_->device_offset >> LBA_SECTOR_POW2, $sec_size);
      }
      $log->debugf("File %s at LBA (%d) %d +%d", $_->name, $_->block_size, $_->start_lba, $sec_size);
   };

   if (my $boot_catalog= $self->boot_catalog) {
      $self->_calc_boot_catalog_size;
      &$assign_lba for $boot_catalog->{extent};
      for my $sec ($boot_catalog->{sections}->@*) {
         &$assign_lba for grep defined, map $_->{extent}, $sec->{entries}->@*;
      }
   }

   # Add the 4 path tables here
   $self->_calc_dir_sizes;
   $self->_calc_path_table_size;
   &$assign_lba for $self->{path_tables}->@{qw( le be jle jbe )};

   # Add the directories here
   my @dirs= ( $self->root, values $self->{_subdirs}->%* );
   for my $dir (@dirs) {
      &$assign_lba for $dir->file, $dir->joliet_file;
   }
   # Add any files that didn't get assigned yet
   for my $dir (@dirs) {
      &$assign_lba for grep defined, map $_->{file}, $dir->entries->@*;
   }
   return $self->{_free_invlist}[-1] * 2048;
}

# Find an available range of sectors to allocate from the free list
sub _allocate_sectors($self, $sector_count) {
   my $inv= $self->{_free_invlist};
   # Iterate the inversion list looking for a range large enough
   # The end of the list has lim=undef.
   for (my $i= 0; $i <= @$inv; $i+= 2) {
      my ($start, $lim)= $inv->@[$i,$i+1];
      if (!$lim || $lim - $start > $sector_count) {
         $inv->[$i] += $sector_count;
         return $start;
      }
      if ($lim - $start == $sector_count) {
         splice(@$inv, $i, 2);
         return $start;
      }
   }
   die "BUG"; # should never get here, as long as list is odd length.
}

# Mark a range of sectors as unavailable for allocation
sub _mark_sectors_reserved($self, $reserve_lba, $sector_count) {
   my $reserve_lim= $reserve_lba + $sector_count;
   my $inv= $self->{_free_invlist};
   for (my $i= 0; $i < @$inv; $i += 2) {
      my ($start, $lim)= $inv->@[$i,$i+1];
      # If this free range is entirely beyond the $lba+$count, request is already reserved
      return if $start >= $reserve_lim;
      # If this free range is entirely less than the request, continue loop
      next if $lim && $lim <= $reserve_lba;
      # If start == lba, move start forward, possibly consuming it
      if ($start >= $reserve_lba) {
         if (!$lim || $reserve_lim < $lim) {
            $inv->[$i]= $reserve_lim;
            return;
         } else {
            splice(@$inv, $i, 2);
            return if $reserve_lim == $lim;
            $i -= 2; # keep looping until free range is beyond reserve_lim
         }
      } else { # start < lba, truncate current range
         $inv->[$i+1]= $reserve_lba;
         # end of the loop? add a new open-ended range
         $inv->[$i+2]= $reserve_lim if $i+1 == $#$inv;
      }
   }
}

sub _calc_dir_sizes($self) {
   # First, ensure every directory has file and joliet_file and shortname defined
   my @dirs= ( $self->root, values $self->{_subdirs}->%* );
   for (@dirs) {
      $_->{file}        //= $self->_new_file($_->name, flags => FLAG_DIRECTORY);
      $_->{joliet_file} //= $self->_new_file($_->name . ' [J]', flags => $_->file->flags);
      # Need the 8.3 name in order to know whether it matches the long name
      $_->build_shortnames;
   }
   for my $dir (@dirs) {
      my $size= 34; # '.' entry
      $size += 34 unless $dir->is_root; # '..' entry
      my $joliet= $size;
      for ($dir->entries->@*) {
         my $is_dir= $_->{dir} || ($_->{file} && $_->{file}->is_dir);
         my $shortname_len= length $_->{shortname};
         my $pos= $size;
         $size += 33 + (($shortname_len + ($is_dir? 0 : 2))|1);
         $size += _remaining_sector_bytes($pos) if _sector_of($pos) != _sector_of($size); # round to next sector
         $pos= $joliet;
         my $joliet_name= encode('UTF-16BE', $_->{name}, Encode::FB_CROAK | Encode::LEAVE_SRC);
         $joliet += 33 + (length($joliet_name)|1);
         $joliet += _remaining_sector_bytes($pos) if _sector_of($pos) != _sector_of($joliet); # round to next sector
         # directory entries get added to a top-level "path table".
         # while we have the name available, calculate the size of those, too.
         if ($is_dir) {
            # gets padded to even length
            $_->{path_table_size}= 8 + $shortname_len + ($shortname_len & 1);
            # utf-16 will always be even length
            $_->{path_table_jsize}= 8 + length($joliet_name);
         }
      }
      $dir->{file}->size(_round_to_whole_sector($size));
      $dir->{joliet_file}->size(_round_to_whole_sector($joliet));
   }
}

sub _pack_iso_datetime($epoch) {
   my @t = gmtime($epoch);
   # year since 1900
   my $tz = 0; # UTC offset in 15min intervals
   return pack('C7', $t[5], $t[4]+1, $t[3], $t[2], $t[1], $t[0], $tz);
}

our @dirent_fields = (
  [ dir_len       =>  0, 1, 'C' ],
  [ ext_attr_len  =>  1, 1, 'C', 0 ],
  [ extent_lba    =>  2, 4, 'V' ],
  [ extent_lba    =>  6, 4, 'N' ],
  [ size          => 10, 4, 'V' ],
  [ size          => 14, 4, 'N' ],
  [ packed_mtime  => 18, 7, 'a7' ],
  [ flags         => 25, 1, 'C', 0 ],
  [ unit_size     => 26, 1, 'C', 0 ],
  [ gap_size      => 27, 1, 'C', 0 ],
  [ seq           => 28, 2, 'v', 1 ], # 'seq' only used for multi-disc sets
  [ seq           => 30, 2, 'n', 1 ], # will always be '1' for a single image.
  [ name_len      => 32, 1, 'C' ],
  # name_len and name appended after 33+
);
sub _encode_dirent($self, $name, $file, $ent= {}) {
   my $name_len=     length $name;
   my $dir_len=      33 + ($name_len|1);
   my $extent_lba=   $ent->{extent_lba} // $file && $file->start_lba // 0;
   my $size=         $ent->{size} // $file && $file->size // 0;
   my $seq=          $ent->{seq} // 1;
   pack 'C C V N V N a7 C C C v n C a'.($name_len|1),
      $dir_len, $ent->{ext_attr_len} // 0,
      $extent_lba, $extent_lba,
      $size, $size,
      _pack_iso_datetime($ent->{mtime} // $file && $file->mtime // $self->{default_time}),
      $ent->{flags} // $file && $file->flags // 0,
      $ent->{unit_size} // 0,
      $ent->{gap_size} // 0,
      $seq, $seq,
      $name_len, $name;
}

sub _pack_directory($self, $dir) {
   # dot and dotdot
   my $data= $self->_encode_dirent("\x00", $dir->file);
   my $joliet= $self->_encode_dirent("\x00", $dir->joliet_file);
   if (my $parent= $dir->parent) {
      $data .= $self->_encode_dirent("\x01", $parent->file);
      $joliet .= $self->_encode_dirent("\x01", $parent->joliet_file);
   }
   # real entries
   for (sort { lc $a->{name} cmp lc $b->{name} } $dir->entries->@*) {
      my $is_dir= $_->{dir} || $_->{file}->is_dir;
      my $shortname= $_->{shortname} . (!$is_dir && ';1');
      my $pos= length $data;
      $data .= $self->_encode_dirent($shortname, $_->{file}, $_);
      # If it crossed a sector boundary, move it fully into the next sector
      substr($data, $pos, 0, "\0"x _remaining_sector_bytes($pos))
         if _sector_of($pos) != _sector_of(length $data);
      my $jname= encode('UTF-16BE', $_->{name}, Encode::FB_CROAK | Encode::LEAVE_SRC);
      my $jfile= $_->{dir}? $_->{dir}->joliet_file # live dir holds reference to joliet_file
         : $is_dir? $_->{joliet_file}              # dirent could also reference the joliet_file
         : $_->{file};                             # else it's a plain file with no alt encoding
      $pos= length $joliet;
      $joliet .= $self->_encode_dirent($jname, $jfile, $_);
      # If it crossed a sector boundary, move it fully into the next sector
      substr($joliet, $pos, 0, "\0"x _remaining_sector_bytes($pos))
         if _sector_of($pos) != _sector_of(length $joliet);
   }
   # verify correct size
   _round_to_whole_sector(length $data) == $dir->file->size
      or die "BUG: encoded directory is ".length($data)." bytes but should be ".$dir->file->size;
   _round_to_whole_sector(length $joliet) == $dir->joliet_file->size
      or die "BUG: encoded joliet directory is ".length($data)." bytes but should be ".$dir->joliet_file->size;
   $dir->file->{data}= \$data;
   $dir->joliet_file->{data}= \$joliet;
}

# The path_table encoding algorithm performs a depth-first iteration because the entries refer
# to the parent using a index into the table, so the entry needs to already exist.
# This depth-first traversal also supports the feature of allowing directories to form an
# acyclic graph, in which case one directory could get traversed multiple times; the path table
# needs to have every distinct path indexed.

sub _calc_path_table_size($self) {
   my @paths= ( [ $self->root, 0 ] );
   my $i= 0;
   my ($size, $jsize)= (10, 10); # start with root dir, always 10 bytes
   while ($i < @paths) {
      my ($dir, $parent_id)= @{ $paths[$i++] };
      for my $ent ($dir->entries->@*) {
         if ($ent->{dir}) {
            defined $ent->{path_table_size} && defined $ent->{path_table_jsize}
               or die join(' ', %$ent);
            $size += $ent->{path_table_size};
            $jsize+= $ent->{path_table_jsize};
            push @paths, [ $ent->{dir}, $i ]; # 1-based index, which works because ++ above
         }
      }
   }
   my sub path_table_extent($name) {
      Sys::Export::Extent->new(block_size => 2048, name => $name)
   }
   ($self->{path_tables}{le}  //= path_table_extent('Path Table [LE]'))->size($size);
   ($self->{path_tables}{be}  //= path_table_extent('Path Table [BE]'))->size($size);
   ($self->{path_tables}{jle} //= path_table_extent('Path Table [LE,J]'))->size($jsize);
   ($self->{path_tables}{jbe} //= path_table_extent('Path Table [BE,J]'))->size($jsize);
}

sub _pack_path_tables($self) {
   # Need packed for both 8.3 filenames and Joliet filenames, and encoded both little-endian
   # and big-endian, for 4 total path tables.
   my ($le, $be, $jle, $jbe);
   $le= $jle= pack 'C C V v a2', 10, 0, $self->root->file->lba, 1, '';
   $be= $jbe= pack 'C C N n a2', 10, 0, $self->root->file->lba, 1, '';
   my @paths= ( [ $self->root, 1 ] );
   my $i= 0;
   my ($size, $jsize)= (0, 0);
   while ($i < @paths) {
      my ($dir, $parent_id)= @{ $paths[$i++] };
      for my $ent ($dir->entries->@*) {
         if ($ent->{dir}) {
            my @vals= ( $ent->{path_table_size}, 0, $ent->{dir}->file->lba, $parent_id, $ent->{shortname} );
            $le .= pack 'C C V v a'.($ent->{path_table_size}-8), @vals;
            $be .= pack 'C C N n a'.($ent->{path_table_size}-8), @vals;
            my $jname= encode('UTF-16BE', $ent->{name}, Encode::FB_CROAK | Encode::LEAVE_SRC);
            @vals= ( $ent->{path_table_jsize}, 0, $ent->{dir}->joliet_file->lba, $parent_id, $jname );
            $jle .= pack 'C C V v a*', @vals;
            $jbe .= pack 'C C N n a*', @vals;
            push @paths, [ $ent->{dir}, $i ]; # 1-based index, which works because ++ above
         }
      }
   }
   my $path_tables= $self->{path_tables};
   die "BUG: wrong encoded path_table size"
      unless length $le == $path_tables->{le}->size && length $be == $path_tables->{be}->size
      && length $jle == $path_tables->{jle}->size && length $jbe == $path_tables->{jbe}->size;
   $path_tables->{le}->data(\$le);
   $path_tables->{be}->data(\$be);
   $path_tables->{jle}->data(\$jle);
   $path_tables->{jbe}->data(\$jbe);
}

sub _pack_iso_volume_datetime($epoch) {
   my @t = gmtime($epoch); # UTC
   my $year = $t[5] + 1900;
   my $mon  = $t[4] + 1;
   my $mday = $t[3];
   my $hour = $t[2];
   my $min  = $t[1];
   my $sec  = $t[0];
   my $centi = ($epoch * 100 % 100);  # hundredths of seconds
   my $tz = 0;     # UTC → offset=0, units of 15 min
   return sprintf("%04d%02d%02d%02d%02d%02d%02d%c",
      $year, $mon, $mday, $hour, $min, $sec,
      $centi, $tz,
   );
}

our @vol_desc_fields = (
   # field_name | offset | size | pack-code | default
   [ type_code        => 0x000,   1, 'C',  1 ],
   [ std_id           => 0x001,   5, 'A', 'CD001' ],
   [ version          => 0x006,   1, 'C',  1 ],
   #[ unused1         => 0x007,   1, 'C',   0 ],
   [ system_id        => 0x008,  32, 'E', '' ], # system which uses sectors 0-15
   [ volume_id        => 0x028,  32, 'E', '' ],
   #[ unused2         => 0x048,   8, 'a8',  '' ],
   [ volume_space     => 0x050,   4, 'V' ],
   [ volume_space     => 0x054,   4, 'N' ],
   [ escape_sequences => 0x058,  32, 'a', '' ],
   [ vol_set_sz       => 0x078,   2, 'v', 1 ],
   [ vol_set_sz       => 0x07A,   2, 'n', 1 ],
   [ seq_no           => 0x07C,   2, 'v', 1 ],
   [ seq_no           => 0x07E,   2, 'n', 1 ],
   [ blk_sz           => 0x080,   2, 'v', 2048 ],
   [ blk_sz           => 0x082,   2, 'n', 2048 ],
   [ path_sz          => 0x084,   4, 'V' ],
   [ path_sz          => 0x088,   4, 'N' ],
   [ path_le          => 0x08C,   4, 'V' ],
   [ path_le_opt      => 0x090,   4, 'V', 0 ],
   [ path_be          => 0x094,   4, 'N' ],
   [ path_be_opt      => 0x098,   4, 'N', 0 ],
   [ root_dirent      => 0x09C,  34, 'a' ],
   [ vol_set_id       => 0x0BE, 128, 'E', '' ],
   [ pub_id           => 0x13E, 128, 'E', '' ],
   [ prep_id          => 0x1BE, 128, 'E', '' ],
   [ app_id           => 0x23E, 128, 'E', '' ],
   [ copy_id          => 0x2BE,  37, 'E', '' ],
   [ abs_id           => 0x2E3,  37, 'E', '' ],
   [ bib_id           => 0x308,  37, 'E', '' ],
   [ creation_ts      => 0x32D,  17, 'a', '0'x16 ],
   [ modification_ts  => 0x33E,  17, 'a', '0'x16 ],
   [ expiration_ts    => 0x34F,  17, 'a', '0'x16 ],
   [ effective_ts     => 0x360,  17, 'a', '0'x16 ],
   [ file_struct      => 0x371,   1, 'C', 1 ],
   #[ unused3         => 0x372,   1, 'C', 0 ],
);

# Given fields and an offset, add all the pack args to the first 2 params.
# The optional '$charset' performs character encoding on any field of type 'E'.
sub _append_pack_args($pack, $vals, $ofs, $fields, $attrs, $charset=undef) {
   for (@$fields) {
      my ($name, $field_ofs, $size, $code, $default)= @$_;
      my $val= $attrs->{$name} // $default
         // croak "No value supplied for $name, and no default";
      if ($code eq 'E') { # 'E' is a virtual code I'm using to mean "Encoded space-padded string"
         if ($charset) {
            # pad with encoded spaces
            $val= substr(encode($charset, $val.(' 'x$size), Encode::FB_CROAK), 0, $size);
         }
         $code= 'A';
      }
      if (uc $code eq 'A') {
         utf8::is_utf8($val) or utf8::downgrade($val, 1)
            or croak "Wide character supplied for attribute $name";
         carp "$name will be truncated" if length($val) > $size;
         $code .= $size;
      }
      push @$pack, '@'.($ofs+$field_ofs).$code;
      push @$vals, $val;
   }
}

# Helper for packing a single list of fields in one function call
sub _pack_fields($field_array, $attrs, $charset=undef) {
   my (@pack, @vals);
   _append_pack_args(\@pack, \@vals, 0, $field_array, $attrs, $charset);
   pack join(' ', @pack), @vals;
}

sub _pack_primary_volume_descriptor($self, $attrs={}) {
   $attrs->{root_file}= $self->root->file;
   $attrs->{path_le}= $self->{path_tables}{le};
   $attrs->{path_be}= $self->{path_tables}{be};
   $self->_pack_volume_descriptor($attrs);
}

sub _pack_joliet_volume_descriptor($self, $attrs={}) {
   $attrs->{type_code}= 2;
   $attrs->{escape_sequences} = "%/E"; # Level 3 of Joliet, UCS-2BE
   $attrs->{root_file}= $self->root->joliet_file;
   $attrs->{path_le}= $self->{path_tables}{jle};
   $attrs->{path_be}= $self->{path_tables}{jbe};
   $self->_pack_volume_descriptor($attrs);
}

# Packs a primary or secondar volume descriptor
sub _pack_volume_descriptor($self, $attrs) {
   my $is_joliet= ($attrs->{type_code}//0) == 2;
   # The pub_id, prep_id, and app_id fields can either be literal text, or they can be a
   # reference to a file in the root dir by starting with a '_' character.
   my $maybe_file_ref= sub($thing) {
      return '_'.$self->_get_metadata_filename($thing, $is_joliet)
         if blessed($thing) && $thing->can('device_offset');
      return $thing;
   };
   $attrs->{system_id}    //= $self->system // uc($^O);
   $attrs->{volume_id}    //= $self->volume_label // 'CDROM';
   $attrs->{volume_space} //= $self->{_free_invlist}[-1];
   $attrs->{path_sz}      //= $attrs->{path_le}->size;
   $attrs->{path_le}      //= $attrs->{path_le}->lba;
   $attrs->{path_be}      //= $attrs->{path_be}->lba;
   $attrs->{root_dirent}  //= $self->_encode_dirent("\0", $attrs->{root_file});
   $attrs->{creation_ts}     //= _pack_iso_volume_datetime($attrs->{btime} // $self->{default_time});
   $attrs->{modification_ts} //= _pack_iso_volume_datetime($attrs->{mtime} // $self->{default_time});
   #$attrs->{effective_ts}    //= _pack_iso_volume_datetime($self->{default_time});
   # Find the filenames of the metadata files
   $attrs->{vol_set_id}   //= $self->volume_set;
   $attrs->{pub_id}       //= $maybe_file_ref->($self->publisher);
   $attrs->{prep_id}      //= $maybe_file_ref->($self->preparer) // "PERL SYS::EXPORT::ISO9660 $VERSION";
   $attrs->{app_id}       //= $maybe_file_ref->($self->application);
   $attrs->{copy_id}      //= $self->_get_metadata_filename($self->copyright_file, $is_joliet);
   $attrs->{abs_id}       //= $self->_get_metadata_filename($self->abstract_file, $is_joliet);
   $attrs->{bib_id}       //= $self->_get_metadata_filename($self->bibliographic_file, $is_joliet);

   return _pack_fields(\@vol_desc_fields, $attrs, $is_joliet? 'UTF16-BE' : undef);
}

sub _get_metadata_filename($self, $spec, $is_joliet) {
   my $ent;
   # Find the root directory entry which refers to this file
   if (blessed($spec) && $spec->can('device_offset')) { # file object
      ($ent)= grep $_->{file} == $spec, $self->root->entries->@*
         or croak "Can't find ".$spec->name." in root directory";
   } else {
      return '' unless length $spec;
      $ent= $self->root->entry($spec) // croak "Can't find $spec in root directory";
   }
   # Return the name as it exists in this directory entry
   !$is_joliet? $ent->{shortname}.';1' : $ent->{name};
}

our @boot_catalog_descriptor= (
   [ type_code        => 0x000,   1, 'C', 0 ],
   [ std_id           => 0x001,   5, 'A', 'CD001' ],
   [ version          => 0x006,   1, 'C',  1 ],
   [ system_id        => 0x007,  32, 'A', 'EL TORRITO SPECIFICATION' ],
   [ boot_id          => 0x027,  32, 'A', '' ],
   [ extent_lba       => 0x047,   4, 'V' ]
);

# Boot Catalog Validation Entry (first 32 bytes)
#our @boot_catalog_validation_entry = (
#   [ header_id   => 0x00,  1, 'C', 0x01 ],       # must be 0x01
#   [ platform    => 0x01,  1, 'C', 0x00 ],       # 0=x86, 1=PPC, 2=Mac, 0xEF=EFI
#   #[ reserved1   => 0x02, 2, 'v', 0 ],
#   [ id_string   => 0x04, 24, 'A', 'EL TORITO SPECIFICATION' ],
#   [ checksum    => 0x1C,  2, 'v', 0 ],          # to be filled in later
#   [ key         => 0x1E,  2, 'v', 0xAA55 ],
#);

# Section Header (32 bytes)
our @boot_catalog_section_header = (
   [ header_id   => 0x00,  1, 'C', 0x91 ],    # 0x91=section, 0x90=final section
   [ platform    => 0x01,  1, 'C', 0x00 ],
   [ entries_cnt => 0x02,  2, 'v' ],          # number of entries following
   [ id_string   => 0x04, 28, 'A', '' ],
);

# Boot Entry (32 bytes)
our @boot_catalog_entry = (
   [ bootable     => 0x00, 1, 'C', 0x88 ],      # 0x88 bootable, 0x00 not
   [ media_type   => 0x01, 1, 'C', 0x00 ],      # 0=no-emul, 1=1.2M, 2=1.44M, 3=2.88M, 4=HDD
   [ load_segment => 0x02, 2, 'v', 0x0000 ],    # 0x0000=no-emul, 0x07C0=floppy
   [ system_type  => 0x04, 1, 'C', 0x00 ],      # MBR partition type byte, 0xEF for EFI ESP
   #[ reserved1    => 0x05, 1, 'C', 0 ],
   [ sector_count => 0x06, 2, 'v', 0 ],         # size in 512-byte sectors
   [ sector_start => 0x08, 4, 'V', 0 ],         # LBA of boot image
   [ reserved2    => 0x0C, 20, 'a', '' ],
);

sub _calc_boot_catalog_size($self) {
   my $boot_catalog= $self->boot_catalog
      or return 0;
   my $extent= $boot_catalog->{extent}
      //= Sys::Export::Extent->new(name => 'El Torrito Boot Catalog', block_size => 2048);
   my $size= 32;
   for my $s ($boot_catalog->{sections}->@*) {
      $size += 32 + 32 * $s->{entries}->@*;
   }
   $extent->size($size);
   $size;
}

# The boot catalog is one (or more, unlikely) sector containing a list of 32-byte entries
# divided into "sections".
sub _pack_boot_catalog($self) {
   my $boot_catalog= $self->boot_catalog;
   my $sections= $boot_catalog->{sections};
   my $catalog= pack 'C C @4 A24',
      1, # header_id = 1
      $sections->[0]{platform}, # copy section0's platform
      'EL TORITO SPECIFICATION';
   
   $catalog .= pack 'v v',
      sum(unpack 'v*', $catalog), # Checksum
      0xAA55; # key bytes

   for my $s (@$sections) {
      $catalog .= _pack_fields(\@boot_catalog_section_header, {
         %$s,
         header_id => ($s == $sections->[-1] ? 0x90 : 0x91), # indicates last section
         entries_cnt => scalar($s->{entries}->@*), # num entries in section
      });
      for ($s->{entries}->@*) {
         $catalog .= _pack_fields(\@boot_catalog_entry, {
            %$_,
            # The lba and sector count are measured in 512-byte sectors like BIOS,
            # rather than 2048 sectors like the rest of ISO9660
            sector_start => $_->{extent}->lba,
            sector_count => ceil($_->{extent}->size / 512),
         });
      }
   }
   die "BUG: encoded size doesn't match file->size"
      if length($catalog) != $boot_catalog->{extent}->size;
   $boot_catalog->{extent}->data(\$catalog);
}

# The boot catalog descriptor is one of the descriptors at the start of the image which
# tells the extent where the boot catalog can be found.
sub _pack_boot_catalog_descriptor($self) {
   my $boot_catalog= $self->boot_catalog;
   my %attrs= ( %$boot_catalog, extent_lba => $boot_catalog->{extent}->lba );
   return _pack_fields(\@boot_catalog_descriptor, \%attrs);
}

# Avoiding dependency on namespace::clean
delete @{Sys::Export::ISO9660::}{qw(
   carp croak confess blessed dualvar refaddr weaken min max sum time ceil encode decode
   S_IFDIR S_ISDIR S_ISREG SEEK_SET SEEK_END
   write_file_extent expand_stat_shorthand isa_handle isa_array isa_hash
)};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::ISO9660 - Write ISO9660 filesystems with Joliet filename and El Torrito boot catalog support

=head1 SYNOPSIS

  my $dst= Sys::Export::ISO9660->new(
    filename => $path,
  );
  # Basic files and directories
  $dst->add([ file => "README.TXT", "Hello World\r\n" ]);
  
  use Sys::Export 'filedata';
  $dst->add([ file => 'EFI/BOOT/BOOTIA32.EFI', filedata($loader) ]);
  
  # Point to a file at an absolute offset from the start of the device
  # The data is assumed to already exist in $dst->filename
  $dst->add([ file => 'initrd', { device_offset => 0x110000 }]);
  
  $dst->finish;

=head1 DESCRIPTION

ISO9660 is the original standard for filesystems on CDROM or DVDROM.  The original standard is
fairly limited in what characters and directory structure it allows.  It has been extended in
numerous ways since then, including allowing longer filenames, unicode filenames, or Unix
permissions.  This module is focused on authoring boot media, so it only supports the Joliet
filename extension (similar to Microsoft VFAT unicode filenames) and "El Torrito" boot catalog
for describing boot loaders for various architectures.

The basic naming rules for the original ISO9660 are that files are limited to C<< [A-Z0-9_] >>,
and at most 8 characters before a 3-character extension, and then a version
number.  Directories may only be 8 characters without extension or version number, and the tree
has a max depth of 8.  For widest compatibility, you should try to stay within those
constraints.  Files have very little in the way of metadata - just a modified-time and 'hidden'
flag.  File data may refer to ANY 2KiB-aligned extent on the entire media.

The Joliet system for long filenames encodes an entire second copy of the directroy structure,
and uses Microsoft's 16-bit litte-endian Unicode, like VFAT.  Permitted characters are much more
relaxed, and filenames can be much longer.

The El Torrito boot catalog is essentially a menu of boot options, grouped per platform.  Each
can reference an extent of data that should be executed as a boot loader.  If there is only one
boot option for a platform, it will be used automatically.  (But, this is all dependent on BIOS
of the host being booted - El Torrito can describe a menu of boot options for the user to choose
from, but BIOS needs to support rendering that menu.  You're probably better off just using one
option that launches GRUB)

=head1 CONSTRUCTORS

=head2 new

  $fat= Sys::Export::ISO9660->new($filename_or_handle);
  $fat= Sys::Export::ISO9660->new(%attrs);
  $fat= Sys::Export::ISO9660->new(\%attrs);

This takes a list of attributes as a hashref or key/value list.  If there is exactly one
argument, it is treated as the filename attribute.

=head1 ATTRIBUTES

=head2 filename

Name of file (or device) to write.  If the file exists it will be truncated before writing.
If you want to write the filesystem amid existing data (like a partition table), pass a file
handle as C<filehandle>.

=head2 filehandle

Output filehandle to write.  The file will be enlarged if it is not big enough.

=head2 root

The root L<Directory|Sys::Export::ISO9660::Directory> object.

=head2 volume_label

Text label for the filesystem image, limited to uppercase letters, digits, and underscore.

=head2 volume_set

Name for a multi-volume collection

=head2 system

Name of the system for which the filesystem is intended.  (i.e. the system what will be
interpreting sectors 0..15 which are defined as "system" sectors)  Limited to uppercase
ASCII.

=head2 publisher

Text label (or reference to a File object in the root directory) of the entity publishing this
image.  Limited to uppercase ASCII.

=head2 preparer

Text label (or reference to a File object in the root directroy) of the entity writing this
image.  Defaults to C<< PERL SYS::EXPORT::ISO9660 $VERSION >>

=head2 application

Text label (or reference to a File object in the root directory) of the application for which
this image is used.  Limited to uppercase ASCII.

=head2 copyright_file

Name of a file (or reference to File object) in the root directory where a copyright is stored.

=head2 abstract_file

Name of a file (or reference to File object) in the root directory where a copyright is stored.

=head2 bibliographic_file

Name of a file (or reference to File object) in the root directory where bibliographic
information is stored.

=head2 boot_catalog

The El Torrito catalog of boot options.  See L</add_boot_catalog_entry> for a convenient way to
build this structure.  It starts undefined until the first entry is added.  If undefined, no
boot catalog is written into the ISO image.

Structure:

  {
    system_id => $ascii32,
    boot_id   => $ascii32,
    sections  => [
      {
        platform    => # BOOT_X86, BOOT_PPC, BOOT_MAC, BOOT_EFI
        id_string   => $ascii28,
        entries => [
          {
            bootable     => # 0 (false) or 0x88 (true)
            media_type   => # EMU_NONE, EMU_FLOPPY12, EMU_FLOPPY144, EMU_FLOPPY288, EMU_HDD
            load_segment => # 0x0000=no-emul, 0x07C0=floppy
            system_type  => # MBR partition type byte, 0xEF for EFI ESP
            extent       => # Sys::Export::Extent object, holds device_offset and size and data
          },
          ...
        ]
      },
      ...
    ],
    file => $iso9660_file_obj, # lazy-built
  }

=head2 default_time

This unix timestamp will be used for any date field that wasn't specified elsewhere.  If not set
when C</finish> is called, it will default to the current time().

=head2 volume_size

Only valid after calling L</finish> or L</allocate_extents>.
Total size of volume, including any extent seen in boot catalog entries.
This will always be a multiple of the 2048 sector size.

=head1 METHODS

=head2 add_boot_catalog_entry

  my $entry= $iso->add_boot_catalog_entry(
    platform          => # BOOT_X86, BOOT_PPC, BOOT_MAC, BOOT_EFI
    section_id        => # ASCII name of section
    bootable          => # boolean, default true
    media_type        => # EMU_NONE, EMU_FLOPPY12, EMU_FLOPPY144, EMU_FLOPPY288, EMU_HDD
    load_segment      => # address for floppy emulation, default 0x7C0 for floppy types
    system_type       => # MBR partition type code, default 0xEF for EFI
    extent            => # Sys::Export::Extent object
    device_offset     => # initialize extent->device_offset
    size              => # initialize extent->size
    data              => # initialize extent->data
  );

This function is a convenient way to build the C<boot_catalog> data structure.  C<platform> is
required, and triggers creation of a new section if there isn't a section for that platform yet.
The C<extent> is also required to be defined before L</finish> is called, but you can delay
initializing it if you don't know what extent you'll be using, yet.

=head2 add

  $fat->add(\%file_attrs);
  # Attributes:
  # {
  #   name               => $path_bytes,
  #   uname              => $path_unicode_string,
  #   ISO9660_shortname  => "8CHARATR.EXT",
  #   mode               => $unix_stat_mode,
  #   ISO9660_flags      => FLAG_HIDDEN,
  #   mtime              => $unix_epoch,
  #   size               => $data_size,
  #   data               => $scalar_or_scalarref_or_LazyFileData,
  #   device_offset      => $desired_byte_offset,
  # }

This add method takes the same file objects as used by Sys::Export, but with some optional
extras:

=over

=item ISO9660_shortname

Any file name not conforming to the 8.3 name limitation of FAT will get an auto-generated
"short" filename, in addition to its "long" filename.  If you want control over what short name
is generated, you can specify it with this attribute.

=item ISO9660_flags

An ORed combination of L<flags|/FILE FLAGS>.  The C<FLAG_DIRECTORY> is still automatically added
based on the C<mode> flags.

=item device_offset

For integration with ISOHybrid, you may specify C<device_offset> to request the file be placed
at an exact location, and as a single un-fragmented extent.  This accounts for the
L</device_offset> of the whole filesystem.  If you supply C<device_offset> and do not supply
C<data> it is assumed the data already exists at that address.

C<device_offset> must align to 2KiB boundaries of the LBA sectors.

=back

=head2 finish

This method performs all the actual work of building the filesystem.  This module writes the
entire filesystem in one pass after calculating all the metdata that needs encoded and where to
place all the files and directories.

You may get exceptions during this call if there isn't a way to write your files as requested.

=head2 allocate_extents

  my $max_used= $iso->allocate_extents;

Assign C<device_offset> to every file (and data structure represented by a File object) where
C<device_offset> is undefined and C<< size > 0 >>.  This assumes we have an open-ended number of
free sectors.  This should only be called after every file and boot entry have been added.

The return value is the total size (bytes) of everything seen.  This includes partitions
referenced by the L</boot_catalog>.  You can exclude boot_catalog entries by setting
C<< start_lba = -1 >> before the call, then updating to the real value before L</finish>.

ISO9660Hybrid calls this with all the files owned by VFAT set to C<< start_lba = -1 >> so that
it can determine how many initial sectors are used, and know where to start the VFAT
filesystem, after which it revises all the shared files to point to extents within
the VFAT filesystem.

=head1 EXPORTS

=head2 is_valid_shortname

Returns true if string meets the very restricted 8.3 notation of a file, with the added
exception of allowing '~' in filenames.  (Windows name mangling generates these and writes
them into iso9660 images, so it's expected to work everywhere)

=head2 is_valid_joliet_name

Returns true as long as string is less than 127 unicode characters and doesn't contain
forbidden characters.

=head2 remove_invalid_shortname_chars

  $str= remove_invalid_shortname_chars($name, '_');

Returns a string with any invalid characters replaced with the supplied replacement character.

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
