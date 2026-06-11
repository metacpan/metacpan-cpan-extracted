package Sys::Export::VFAT;
# ABSTRACT: Write minimal FAT12/16/32 filesystems with control over stored file extents
our $VERSION = '0.006'; # VERSION

use v5.26;
use warnings;
use experimental qw( signatures );
use Fcntl qw( S_IFDIR S_ISDIR S_ISREG );
use Scalar::Util qw( blessed dualvar refaddr weaken );
use List::Util qw( min max );
use POSIX 'ceil';
use Sys::Export::LogAny '$log';
use Encode qw( encode decode );
use Carp;
our @CARP_NOT= qw( Sys::Export Sys::Export::Unix );
use constant {
   ATTR_READONLY  => dualvar(0x01, 'ATTR_READONLY'),
   ATTR_HIDDEN    => dualvar(0x02, 'ATTR_HIDDEN'),
   ATTR_SYSTEM    => dualvar(0x04, 'ATTR_SYSTEM'),
   ATTR_VOLUME_ID => dualvar(0x08, 'ATTR_VOLUME_ID'),
   ATTR_DIRECTORY => dualvar(0x10, 'ATTR_DIRECTORY'),
   ATTR_ARCHIVE   => dualvar(0x20, 'ATTR_ARCHIVE'),
   ATTR_LONG_NAME => dualvar(0x0F, 'ATTR_LONG_NAME'),
   ATTR_LONG_NAME_MASK => 0x3F,
};
use Exporter 'import';
our @EXPORT_OK= qw( FAT12 FAT16 FAT32 ATTR_READONLY ATTR_HIDDEN ATTR_SYSTEM ATTR_ARCHIVE
  ATTR_VOLUME_ID ATTR_DIRECTORY is_valid_longname is_valid_shortname is_valid_volume_label
  build_shortname remove_invalid_shortname_chars );
use Sys::Export qw( isa_hash isa_array isa_handle isa_int isa_pow2 expand_stat_shorthand write_file_extent );
use Sys::Export::VFAT::Geometry qw( FAT12 FAT16 FAT32 );
require Sys::Export::VFAT::AllocationTable;
require Sys::Export::VFAT::File;
require Sys::Export::VFAT::Directory;


sub new($class, @attrs) {
   my %attrs= @attrs != 1? @attrs
            : isa_hash $attrs[0]? %{$attrs[0]}
            : isa_handle $attrs[0]? ( filehandle => $attrs[0] )
            : ( filename => $attrs[0] );
   my $self= bless {}, $class;
   $self->{root}= $self->_new_dir('/', undef, undef);
   # keep root dir separate from subdirs
   delete $self->{_subdirs}{refaddr $self->{root}};
   # apply other attributes
   $self->$_($attrs{$_}) for keys %attrs;
   $self;
}

# Create dir, and store a strong reference in ->{_subdirs}
sub _new_dir($self, $name, $parent, $file) {
   my $dir= Sys::Export::VFAT::Directory->new(name => $name, parent => $parent, file => $file);
   $self->{_subdirs}{refaddr $dir}= $dir;
   $dir;
}


sub filename { @_ > 1? ($_[0]{filename}= $_[1]) : $_[0]{filename} }
sub filehandle { @_ > 1? ($_[0]{filehandle}= $_[1]) : $_[0]{filehandle} }


sub root($self) { $self->{root} }
sub geometry($self) { $self->{geometry} }
sub allocation_table($self) { $self->{allocation_table} }

sub volume_offset($self, @val) {
   if ($self->{geometry}) {
      croak "Geometry already decided" if @val;
      return $self->{geometry}->volume_offset;
   }
   if (@val) {
      croak "volume_offset must be a multiple of 512" if $val[0] & 511;
      return $self->{volume_offset}= $val[0];
   }
   $self->{volume_offset} // 0
}


sub min_bits($self, @val) {
   if (@val) {
      croak "Geometry already decided" if $self->{geometry};
      $self->{min_bits}= $val[0];
   }
   $self->{min_bits}
}

sub bytes_per_sector($self, @val) {
   if ($self->{geometry}) {
      croak "Geometry already decided" if @val;
      return $self->{geometry}->bytes_per_sector;
   }
   if (@val) {
      croak "bytes_per_sector must be a power of 2" unless isa_pow2 $val[0];
      return $self->{bytes_per_sector}= $val[0];
   }
   $self->{bytes_per_sector} // 512
}

sub sectors_per_cluster($self, @val) {
   if ($self->{geometry}) {
      croak "Geometry already decided" if @val;
      return $self->{geometry}->sectors_per_cluster;
   }
   if (@val) {
      croak "sectors_per_cluster must be a power of 2, and 128 or less" unless isa_pow2 $val[0] && $val[0] <= 128;
      return $self->{sectors_per_cluster}= $val[0];
   }
   $self->{sectors_per_cluster}
}

sub fat_count($self, @val) {
   if ($self->{geometry}) {
      croak "Geometry already decided" if @val;
      return $self->{geometry}->fat_count;
   }
   if (@val) {
      croak "fat_count must be positive" unless isa_int $val[0] && $val[0] > 0;
      return $self->{fat_count}= $val[0];
   }
   $self->{fat_count}
}

sub free_space($self, @val) {
   if (@val) {
      croak "Geometry already decided" if $self->{geometry};
      return $self->{free_space}= $val[0];
   }
   $self->{free_space} // 0
}

sub volume_label($self, @val) {
   if (@val) {
      croak "Invalid volume label '$val[0]'" unless is_valid_volume_label($val[0]);
      return $self->{volume_label}= $val[0];
   }
   $self->{volume_label}
}

# The smallest conceivable address where the data region could start
sub _minimum_offset_to_data {
   state $minimum_offset_to_data= Sys::Export::VFAT::Geometry->new(
      bytes_per_sector => 512,
      sectors_per_cluster => 1,
      fat_count => 1,
      root_dirent_count => 1,
      cluster_count => 1
   )->data_start_offset;
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

   my @path= grep length, split '/', $path;
   my $leaf= pop @path;

   # Walk through the tree based on the case-folded path
   my $parent= $self->root;
   for (@path) {
      my $ent= $parent->entry($_);
      if ($ent) {
         croak $ent->name." is not a directory, while attempting to add '$path'"
            unless $ent->{dir};
      } else { # Auto-create directory. Autovivication is indicated by ->{file} = undef
         $ent= $parent->add($_, undef);
         my $name= ($parent == $self->root? '' : $parent->name)."/$_";
         weaken($ent->{dir}= $self->_new_dir($name, $parent, undef));
      }
      $parent= $ent->{dir};
   }

   # did user supply FAT attribute bitmask?
   my $flags= $spec->{FAT_flags} // do {
      # readonly determined by user -write bit of 'mode'
      (!($spec->{mode} & 0400)? ATTR_READONLY : 0)
      # hidden determined by leading '.' in filename
      | (defined $leaf && $leaf =~ /^\./? ATTR_HIDDEN : 0)
   };
   my $file;
   if (S_ISREG($spec->{mode})) {
      my ($size, $offset, $align, $data_ref)
         = @{$spec}{qw( size device_offset device_align data )};
      $data_ref= do { my $x= $data_ref; \$x }
         if defined $data_ref && !ref $data_ref;
      if ($size) {
         # ensure data matches
         croak "File $path has size=$size but lacks 'data' attribute"
            unless defined $data_ref;
         croak "File $path ->{data} length disagrees with ->{size}"
            unless length($$data_ref) == $size;
      } elsif (defined $data_ref) {
         $size //= length($$data_ref);
      }
      # must be a power of 2
      croak "Invalid device_align $align for '$path', must be a power of 2"
         if defined $align && !isa_pow2 $align;
      # Sanity check device_offset before we get too far along
      if (defined $offset) {
         $align //= 512;
         # must fall in the data area
         $offset > $self->volume_offset + _minimum_offset_to_data
         # must be a multiple of at least 512 (probably more)
         && !($offset & ($align-1))
            or croak "Invalid device_offset '$offset' for file '$path'";
      }
      $file= Sys::Export::VFAT::File->new(
         name => "/$path", size => $size, flags => $flags,
         align => $align, device_offset => $offset, data => $data_ref,
         $spec->%{qw( atime btime mtime )},
      );
   } elsif (S_ISDIR($spec->{mode})) {
      $flags |= ATTR_DIRECTORY;
      # If adding this directory overtop a previous auto-vivified directory, the ->{file}
      # will be empty and we can just update it.
      my $cur= $parent->entry($leaf);
      croak "Attempt to add duplicate directory $leaf"
         if $cur && $cur->{file};
      $file= Sys::Export::VFAT::File->new(
         name => "/$path", size => 0, flags => $flags, $spec->%{qw( atime btime mtime )},
      );
      if ($cur) {
         $cur->{file}= $file;
         $cur->{dir}{file}= $file;
         $log->debugf("updated attributes of %s", $path);
         return $cur;
      }
      # otherwise, add this file to a directory entry
   }
   else {
      # TODO: add conditional symlink support via hardlinks
      croak "Can only export files or directories into VFAT"
   }

   # this also checks for name collisions on shortname
   my $ent= $parent->add($leaf, $file, shortname => $spec->{FAT_shortname});
   # If the dirent is a directory, also add a directory object to the dirent
   if ($file->is_dir) {
      # the directory object also gets a reference to its file object.
      weaken($ent->{dir}= $self->_new_dir("/$path", $parent, $file));
   }

   $log->debugf("added %s longname=%s shortname=%s %s",
      $path, $ent->{name}, $ent->{shortname}//'', join(' ',
         !$ent->{file}? ('size=0 (empty file)')
         : $ent->{file}->is_dir? ('DIR')
         : (
            (defined $ent->{file}->size? sprintf("size=0x%X", $ent->{file}->size) : 'size=<undef>'),
            (defined $ent->{file}->align? sprintf("device_align=0x%X", $ent->{file}->align) : ()),
            (defined $ent->{file}->device_offset? sprintf("device_offset=0x%X", $ent->{file}->device_offset) : ())
         )
      ))
      if $log->is_debug;

   $ent->{file};
}


sub finish($self) {
   my $root= $self->root;
   $log->debug('begin VFAT::finish');
   # Find out the size of every directory, and build ->{_allocs}, ->{_dir_allocs} and ->{_special_allocs}
   $self->_calc_dir_size($_) for $root, values $self->{_subdirs}->%*;
   # calculate what geometry gives us the best size, when rounding each file to that cluster
   # size vs. the size of the FAT it generates
   my ($geom, $alloc)= $self->_optimize_geometry
      or croak join("\n", "No geometry options can meet your device_offset / device_align requests:",
            map "$_: $self->{_optimize_geometry_fail_reason}{$_}",
               sort { $a <=> $b } keys $self->{_optimize_geometry_fail_reason}->%*
         );
   $self->{geometry}= $geom;
   $self->{allocation_table}= $alloc;
   $self->_commit_allocation; # copy cluster IDs into each of the File objects
   # Pack directories now that all file cluster ids are known
   $self->_pack_directory($_) for $root, values $self->{_subdirs}->%*;

   my $fh= $self->filehandle;
   if (!$fh) {
      defined $self->filename or croak "Must set filename or filehandle attributes";
      open $fh, '+>', $self->filename
         or croak "open: $!";
   }
   # check size
   if (-s $fh < $geom->volume_offset + $geom->total_size) {
      $log->debugf('resize output file to %s', $geom->volume_offset + $geom->total_size);
      truncate($fh, $geom->volume_offset + $geom->total_size)
         or croak "truncate: $!";
   }
   $self->_write_filesystem($fh, $geom, $alloc);
   unless ($self->filehandle) {
      $fh->close or croak "close: $!";
   }
   $log->debug('end VFAT::finish');
   1;
}

sub _log_hexdump($buf) {
   $log->tracef('%04X'.(" %02x"x16), $_, unpack 'C*', substr($buf, $_*16, 16))
      for 0..ceil(length($buf) / 16);
}

sub _write_filesystem($self, $fh, $geom, $alloc) {
   ($alloc->max_cluster_id//-1) == ($geom->max_cluster_id//-1)
      or croak "Max element of 'fat_entries' should be ".$geom->max_cluster_id.", but was ".$alloc->max_cluster_id;
   # Pack the boot sector and other reserved sectors
   my $buf= $self->_pack_reserved_sectors;
   my $ofs= $self->volume_offset;
   write_file_extent($fh, $ofs, $geom->reserved_size, \$buf, 0, 'reserved sectors');
   $ofs += $geom->reserved_size;
   # Pack the allocation tables
   $buf= $self->_pack_allocation_table($alloc);
   # store a copy of this into each of the regions occupied by fats
   for (my $i= 0; $i < $geom->fat_count; $i++) {
      write_file_extent($fh, $ofs, $geom->fat_size, \$buf, 0, "fat table $i");
      $ofs += $geom->fat_size;
   }
   # For FAT12/FAT16, write the root directory entries
   if ($geom->bits < FAT32) {
      my $rootf= $self->root->file;
      die "BUG: mis-sized FAT16 root directory"
         if !$rootf->size || ($rootf->size & 31)
            || length ${$rootf->data} != $rootf->size
            || $rootf->size > $geom->root_dir_size;
      write_file_extent($fh, $ofs, $geom->root_dir_size, $rootf->data, 0, 'root dir');
   }
   # The files and dirs have all been assigned clusters by _optimize_geometry
   for my $cl (sort { $a <=> $b } keys $alloc->chains->%*) {
      my ($invlist, $file)= $alloc->chains->{$cl}->@{'invlist','file'};
      my $data= $file->data;
      # Given an inversion list describing the allocated clusters for this file,
      # write the relevant chunks of the file to those cluster data areas.
      $log->debugf("writing '%s' at cluster %s", $file->name, _render_invlist($invlist))
         if $log->is_debug;
      my $data_ofs= 0;
      for (my $i= 0; $i < @$invlist; $i += 2) {
         my ($cl_start, $cl_lim)= @{$invlist}[$i, $i+1];
         my $size= ($cl_lim-$cl_start) * $geom->bytes_per_cluster;
         write_file_extent($fh, $geom->get_cluster_device_offset($cl_start), $size, $data, $data_ofs);
         $data_ofs += $size;
      }
   }
}
sub _render_invlist($il) {
   join ',',
      map +($il->[$_*2] == $il->[$_*2+1]-1? $il->[$_*2] : $il->[$_*2] . '-' . $il->[$_*2+1]),
      0 .. int($#$il/2)
}


sub is_valid_longname($name) {
   # characters permitted for LFN are all letters numbers and $%'-_@~`!(){}^#&+,;=[].
   # and space and all codepoints above 0x7F.
   # they may not begin with space, and cannot exceed 255 chars.
   !!($name !~ /^(\.+\.?)\z/ # dot and dotdot are reserved
   && $name =~ /^
      [^\x00-\x20\x22\x2A\x2F\x3A\x3C\x3E\x3F\x5C\x7C\x7F]
      [^\x00-\x1F\x22\x2A\x2F\x3A\x3C\x3E\x3F\x5C\x7C]{0,254}
      \z/x);
}

sub is_valid_shortname($name) {
   !!($name eq uc $name
   && $name =~ /^
      [\x21\x23-\x29\x2D\x30-\x39\x40-\x5A\x5E-\x7B\x7D\x7E\x80-\xFF]
      [\x20\x21\x23-\x29\x2D\x30-\x39\x40-\x5A\x5E-\x7B\x7D\x7E\x80-\xFF]{0,7}
      (?: \.
         ( [\x21\x23-\x29\x2D\x30-\x39\x40-\x5A\x5E-\x7B\x7D-\xFF]
           [\x20\x21\x23-\x29\x2D\x30-\x39\x40-\x5A\x5E-\x7B\x7D-\xFF]{0,2}
         )?
      )?
      \z/x);
}

sub is_valid_volume_label($name) {
   # same as shortname but no '.' and space is allowed
   !!($name =~ /^
      [\x21\x23-\x29\x2D\x30-\x39\x40-\x5A\x5E-\x7B\x7D-\xFF]
      [\x20\x21\x23-\x29\x2D\x30-\x39\x40-\x5A\x5E-\x7B\x7D-\xFF]{0,10}
      \z/x);
}

sub remove_invalid_shortname_chars($name, $replacement='_') {
   $name =~ tr/a-z/A-Z/; # perform 'uc' but only for the ASCII range
   $name =~ s/[^\x20\x21\x23-\x29\x2D\x30-\x39\x40-\x5A\x5E-\x7B\x7D\x7E\x80-\xFF]+/$replacement/gr;
}

sub _optimize_geometry($self) {
   # calculate what geometry gives us the best size, when rounding each file to that cluster
   # size vs. the size of the FAT it generates, and also meting the needs of alignment requests
   my $root= $self->root;
   my (@offsets, @aligned, @others);
   my %seen= ( refaddr($root) => 1 );
   for my $dir ($root, values $self->{_subdirs}->%*) {
      for my $ent ($dir->entries->@*) {
         # entry may have a directory ref and not a direct file ref
         my $file= $ent->{file} //= $ent->{dir} && $ent->{dir}->file;
         next unless $file && !$seen{refaddr $file}++;
         push @{$file->device_offset? \@offsets : $file->align? \@aligned : \@others}, $file;
      }
   }
   $log->debugf("_optimize_geometry offsets=%d aligned=%d others=%d",
      scalar @offsets, scalar @aligned, scalar @others);
   # provide stable results
   @offsets= sort { $a->device_offset <=> $b->device_offset } @offsets;
   @aligned= sort { fc $a->name cmp fc $b->name } @aligned;
   @others=  sort { fc $a->name cmp fc $b->name } @others;
   my $min_ofs= min(map $_->device_offset, @offsets);
   my $max_ofs= max(map $_->device_offset + $_->size, @offsets);
   my $max_align= max(0, map $_->align, @aligned);
   my $root_dirent_used= $root->file->size / 32;
   isa_int $root_dirent_used && $root_dirent_used >= 1
      or die "BUG: root must always have one entry";
   my $bytes_per_sector= $self->bytes_per_sector;
   my %fail_reason;
   my $best;
   # If the user defined sectors_per_cluster, we only have one option.
   # Otherwise iterate through all of them to find the best.
   my @spc= defined $self->sectors_per_cluster? ( $self->sectors_per_cluster )
      : (1,2,4,8,16,32,64,128);
   cluster_size: for my $sectors_per_cluster (@spc) {
      my $cluster_size= $sectors_per_cluster * $bytes_per_sector;
      isa_pow2 $cluster_size or die "BUG: cluster_size not a power of 2";
      # Avoid triggering warning about incompatible cluster sizes if a good cluster size was
      # already found.
      last if $best && $cluster_size > 32*1024;
      # Count total sectors used by ->{size} of files and dirs.
      # Don't add root dir until we know it will be FAT32
      my $clusters= 0;
      for (@offsets, @aligned, @others) {
         $clusters += ceil($_->size / $cluster_size);
      }
      $log->tracef("with sectors_per_cluster=%d, would require at least %d clusters",
         $sectors_per_cluster, $clusters);
      $clusters ||= 1;
      my ($reserved, $root_clusters_added);
      # If file alignment is a larger power of 2 than cluster_size, then as long as data_start
      # is aligned to cluster_size there will be a cluster that can satisfy the alignment.
      # If file alignment is a smaller power of 2 than cluster_size, then as long as
      # data_start is aligned to the file alignment, every cluster can satisfy the alignment.
      my $align= min($cluster_size, $max_align);
      if ($align) {
         # But wait, does every device_offset meet this alignment?  If not, give up.
         for (@offsets) {
            if ($_->device_offset & ($align-1)) {
               $fail_reason{$sectors_per_cluster}= "device_offset ".$_->device_offset
                  ." of ".$_->name." conflicts with your alignment request of $align";
               next cluster_size;
            }
         }
      }
      elsif (@offsets) {
         # If not aligning clusters to pow2, might need to align to device_offset.
         # First, every device_offset must have the same remainder modulo cluster_size.
         my ($remainder, $prev);
         for (@offsets) {
            my $r= $_->device_offset & ($cluster_size-1);
            if (!defined $remainder) {
               $remainder= $r;
               $prev= $_;
            } elsif ($remainder != $r) {
               $fail_reason{$sectors_per_cluster}= "file $_->{name} device_offset "
                  .$_->device_offset." modulo cluster_size $cluster_size conflicts with"
                  ." file ".$prev->name." device_offset ".$prev->device_offset;
               next cluster_size;
            }
         }
         if ($remainder) {
            $align= [ $cluster_size, $remainder ];
         } else {
            $align= $cluster_size;
         }
      }
      again_with_more_clusters: {
         # If this number of clusters pushes us into FAT32, also need to add the root directory
         # clusters to the count.
         if (!$root_clusters_added
            && $clusters > Sys::Export::VFAT::Geometry::FAT16_IDEAL_MAX_CLUSTERS()
         ) {
            $root_clusters_added= ceil($root->file->size / $cluster_size);
            $clusters += $root_clusters_added;
            $log->tracef("reached FAT32 threshold, adding %s clusters for root dir", $root_clusters_added);
         }
         my $geom= Sys::Export::VFAT::Geometry->new(
            volume_offset          => $self->volume_offset,
            (align_clusters        => $align)x!!$align,
            bytes_per_sector       => $bytes_per_sector,
            sectors_per_cluster    => $sectors_per_cluster,
            fat_count              => $self->fat_count,
            cluster_count          => $clusters,
            used_root_dirent_count => $root_dirent_used,
            min_bits               => $self->min_bits,
         );
         $log->debugf("testing clusters=%d size=0x%X data_region=0x%X-%X min_ofs=0x%X max_ofs=0x%X",
            $clusters, $cluster_size, $geom->data_start_device_offset, $geom->data_limit_device_offset,
            $min_ofs, $max_ofs);
         if (@offsets || @aligned) {
            # tables are too large? Try again with larger clusters.
            if (defined $min_ofs && $min_ofs < $geom->data_start_device_offset) {
               $fail_reason{$sectors_per_cluster}= "FAT tables too large for requested device_offset $min_ofs";
               next cluster_size;
            }
            # Not enough clusters?  Try again with more.
            if (defined $max_ofs && $max_ofs > $geom->data_limit_device_offset) {
               # This might overshoot a bit since the tables also grow and push forward the
               # whole data area.
               $clusters= ceil(($max_ofs - $geom->data_start_device_offset) / $cluster_size);
               goto again_with_more_clusters;
            }
         }
         # Now verify we have enough clusters by actually alocating them
         my $alloc= Sys::Export::VFAT::AllocationTable->new;
         my %assignment;
         unless (eval {
            $self->_alloc_file($geom, $alloc, $_)
               for @offsets, @aligned, @others, ($geom->bits == FAT32? ($root->file) : ());
            1
         }) {
            chomp($fail_reason{$sectors_per_cluster}= "$@");
            next cluster_size;
         }
         if ($alloc->max_used_cluster_id > $geom->max_cluster_id) {
            $clusters= $alloc->max_used_cluster_id-1;
            goto again_with_more_clusters;
         }
         # Allocation worked, so clamp the allocator to this nmber of sectors
         $alloc->max_cluster_id($geom->max_cluster_id);
         # Is this the smallest option so far?
         if (!$best || $best->{geom}->total_sector_count > $geom->total_sector_count) {
            $best= { geom => $geom, alloc => $alloc, cluster_assignment => \%assignment };
         }
      }
   } continue {
      $log->tracef("%s", $fail_reason{$sectors_per_cluster})
         if defined $fail_reason{$sectors_per_cluster};
   }
   if (!$best) {
      $log->debug("no cluster size works");
      $self->{_optimize_geometry_fail_reason}= \%fail_reason;
      return;
   }
   $log->debugf("best cluster_size is %d", $best->{geom}->bytes_per_cluster);
   return @{$best}{'geom','alloc'};
}

# reserve clusters for a file according to the align/offset needs of that file
sub _alloc_file($self, $geom, $alloc, $file) {
   my $sz= $file->size or do { carp "Attempt to allocate zero-length file"; return };
   my $cl_count= POSIX::ceil($sz / $geom->bytes_per_cluster);
   my $cl_start;
   if ($file->device_offset) {
      my ($cl, $n)= $geom->get_cluster_extent_of_device_extent($file->device_offset, $sz);
      $cl_start= $alloc->alloc_range($cl, $cl_count)
         // croak "Can't allocate $cl_count clusters from offset ".$file->device_offset;
   } elsif ($file->align) {
      my ($mul, $ofs)= $geom->get_cluster_alignment_of_device_alignment($file->align);
      $cl_start= $alloc->alloc_contiguous($cl_count, $mul, $ofs)
         // croak "Can't allocate $cl_count clusters aligned to ".$file->align;
   } else {
      $cl_start= $alloc->alloc($cl_count)
         // croak "Can't allocate $cl_count clusters";
   }
   $alloc->{chains}{$cl_start}{file}= $file;
   $cl_start;
}

# store the cluster and device offset into the File objects
sub _commit_allocation($self) {
   my $alloc= $self->allocation_table;
   my $geom= $self->geometry;
   # Apply file cluster IDs to the File objects
   for (values $alloc->chains->%*) {
      my $file= $_->{file};
      $file->{cluster}= $_->{invlist}[0];
      # Only set offset if file is contiguous
      $file->{device_offset} //= $geom->get_cluster_device_offset($file->{cluster})
         if 2 == @{$_->{invlist}};
   }
}

our @sector0_fields_common= (
   [ BS_jmpBoot     =>    0,  3, 'a3', '' ],
   [ BS_OEMName     =>    3,  8, 'a8', 'MSWIN4.1' ],
   [ BPB_BytsPerSec =>   11,  2, 'v' ],
   [ BPB_SecPerClus =>   13,  1, 'C' ],
   [ BPB_RsvdSecCnt =>   14,  2, 'v' ],
   [ BPB_NumFATs    =>   16,  1, 'C' ],
   [ BPB_RootEntCnt =>   17,  2, 'v' ],
   [ BPB_TotSec16   =>   19,  2, 'v' ],
   [ BPB_Media      =>   21,  1, 'C', 0xF8 ],
   [ BPB_FATSz16    =>   22,  2, 'v' ],
   [ BPB_SecPerTrk  =>   24,  2, 'v', 0 ],
   [ BPB_NumHeads   =>   26,  2, 'v', 0 ],
   [ BPB_HiddSec    =>   28,  4, 'V', 0 ],
   [ BPB_TotSec32   =>   32,  4, 'V'  ]
);
our @sector0_fat16_fields= (
   @sector0_fields_common,
   [ BS_DrvNum      =>   36,  1, 'C', 0x80 ],
   [ BS_Reserved1   =>   37,  1, 'C', 0 ],
   [ BS_BootSig     =>   38,  1, 'C', 0x29 ],
   [ BS_VolID       =>   39,  4, 'V' ],
   [ BS_VolLab      =>   43, 11, 'A11', 'NO NAME' ],
   [ BS_FilSysType  =>   54,  8, 'A8' ],
   [ _signature     =>  510,  2, 'v', 0xAA55 ],
);
our @sector0_fat32_fields= (
   @sector0_fields_common,
   [ BPB_FATSz32    =>   36,  4, 'V' ],
   [ BPB_ExtFlags   =>   40,  2, 'v', 0 ],
   [ BPB_FSVer      =>   42,  2, 'v', 0 ],
   [ BPB_RootClus   =>   44,  4, 'V' ],
   [ BPB_FSInfo     =>   48,  2, 'v' ],
   [ BPB_BkBootSec  =>   50,  2, 'v', 0 ],
   [ BPB_Reserved   =>   52, 12, 'a12', '' ],
   [ BS_DrvNum      =>   64,  1, 'C', 0x80 ],
   [ BS_Reserved1   =>   65,  1, 'C', 0 ],
   [ BS_BootSig     =>   66,  1, 'C', 0x29 ],
   [ BS_VolID       =>   67,  4, 'V' ],
   [ BS_VolLab      =>   71, 11, 'A11', 'NO NAME' ],
   [ BS_FilSysType  =>   82,  8, 'A8' ],
   [ _signature     =>  510,  2, 'v', 0xAA55 ],
);
our @fat32_fsinfo_fields= (
   [ FSI_LeadSig    =>    0,  4, 'V', 0x41615252 ],
   [ FSI_Reserved1  =>    4,480, 'a480', '' ],
   [ FSI_StrucSig   =>  484,  4, 'V', 0x61417272 ],
   [ FSI_Free_Count =>  488,  4, 'V', 0xFFFFFFFF ],
   [ FSI_Nxt_Free   =>  492,  4, 'V', 0xFFFFFFFF ],
   [ FSI_Reserved2  =>  496, 12, 'a12', '' ],
   [ FSI_TrailSig   =>  508,  4, 'V', 0xAA550000 ],
);
sub _append_pack_args($pack, $vals, $ofs, $fields, $attrs) {
   for (@$fields) {
      push @$pack, '@'.($ofs+$_->[1]).$_->[3];
      push @$vals, $attrs->{$_->[0]} // $_->[4]
         // croak "No value supplied for $_->[0], and no default";
   }
}

sub _epoch_to_fat_date_time($epoch) {
   my @lt = localtime($epoch);
   my $year = $lt[5] + 1900;
   my $mon  = $lt[4] + 1;
   my $mday = $lt[3];
   my $hour = $lt[2];
   my $min  = $lt[1];
   my $sec  = int($lt[0] / 2); # 2-second resolution

   $year = 1980 if $year < 1980;
   my $fat_date = (($year - 1980) << 9) | ($mon << 5) | $mday;
   my $fat_time = ($hour << 11) | ($min << 5) | $sec;
   my $fat_frac = ($epoch * 100) % 200;
   return ($fat_date, $fat_time, $fat_frac);
}

# This packs the boot sector and all the "reserved" sectors that appear before the
# beginning of the allocation tables.
sub _pack_reserved_sectors($self, %attrs) {
   my (@pack, @vals);
   my $geom= $self->geometry;
   $attrs{BPB_BytsPerSec}= $geom->bytes_per_sector;
   $attrs{BPB_SecPerClus}= $geom->sectors_per_cluster;
   $attrs{BPB_RsvdSecCnt}= $geom->reserved_sector_count;
   $attrs{BPB_NumFATs}=    $geom->fat_count;
   $attrs{BPB_RootEntCnt}= $geom->root_dirent_count;
   $attrs{BS_VolLab} //= $self->volume_label;
   $attrs{BS_VolID} //= time & 0xFFFFFFFF;
   if ($geom->bits < FAT32) {
      $attrs{BPB_FATSz16}= $geom->fat_sector_count < 0x10000? $geom->fat_sector_count : 0;
      $attrs{BPB_FATSz32}= $geom->fat_sector_count < 0x10000? 0 : $geom->fat_sector_count;
      $attrs{BPB_TotSec16}= $geom->total_sector_count < 0x10000? $geom->total_sector_count : 0;
      $attrs{BPB_TotSec32}= $geom->total_sector_count < 0x10000? 0 : $geom->total_sector_count;
      $attrs{BS_FilSysType}= $geom->bits == 12? 'FAT12' : 'FAT16';
      _append_pack_args(\@pack, \@vals, 0, \@sector0_fat16_fields, \%attrs);
   } else {
      # Did the user specify location of fsinfo?  If not, default to sector 1
      $attrs{BPB_FSInfo} //= 1;
      $attrs{BPB_BkBootSec} //= 2;
      $attrs{BPB_FATSz16}= 0;
      $attrs{BPB_FATSz32}= $geom->fat_sector_count;
      $attrs{BPB_RootClus}= $self->root->file->cluster;
      $attrs{BPB_TotSec16}= 0;
      $attrs{BPB_TotSec32}= $geom->total_sector_count;
      $attrs{BS_FilSysType}= "FAT";
      _append_pack_args(\@pack, \@vals, 0, \@sector0_fat32_fields, \%attrs);
      
      # FSInfo struct, location is configurable
      my $fsi_ofs= $attrs{BPB_FSInfo} * $attrs{BPB_BytsPerSec};
      $attrs{FSI_Free_Count} //= $self->allocation_table->free_cluster_count;
      $attrs{FSI_Nxt_Free}   //= $self->allocation_table->first_free_cluster;
      _append_pack_args(\@pack, \@vals, $fsi_ofs, \@fat32_fsinfo_fields, \%attrs);

      # Backup copy of boot sector
      my $bk_ofs= $attrs{BPB_BkBootSec} * $attrs{BPB_BytsPerSec};
      _append_pack_args(\@pack, \@vals, $bk_ofs, \@sector0_fat32_fields, \%attrs);
      _append_pack_args(\@pack, \@vals, $bk_ofs+$fsi_ofs, \@fat32_fsinfo_fields, \%attrs);
   }
   pack join(' ', @pack), @vals;
}

# This packs one allocation table and returns the buffer
sub _pack_allocation_table($self, $alloc) {
   my $fat= [ $alloc->fat->@* ];
   croak "Allocation table used more clusters than configured in geometry"
      if $self->geometry->max_cluster_id < ($alloc->max_cluster_id // $alloc->max_used_cluster_id);
   my $max= $self->geometry->max_cluster_id;
   $#$fat= $max;
   $fat->[$_]= 0x0FFFFFFF for 0,1;
   $fat->[$_] //= 0 for 2..$max;   # prevent warnings in pack
   if ($self->geometry->bits == 32) {
      return pack 'V*', @$fat;
   } elsif ($self->geometry->bits == 16) {
      return pack 'v*', @$fat;
   } else {
      # 12 bits per entry, pack in groups of 3 bytes, little-endian
      my $buf= "\xFF\xFF\xFF";
      for (my $i= 2; $i+1 <= $max; $i+= 2) {
         my $v= ($fat->[$i] & 0xFFF) | ( ($fat->[$i+1] & 0xFFF) << 12 );
         $buf .= pack 'vC', $v, ($v >> 16);
      }
      $buf .= pack 'v', $fat->[$max] & 0xFFF unless $max & 1;
      return $buf;
   }
}

# This calculates the encoded size of one directory
sub _calc_dir_size($self, $dir) {
   # If an autovivified directoy lacks a ->{file}, create it.
   $dir->{file} //= Sys::Export::VFAT::File->new(name => $dir->name, flags => ATTR_DIRECTORY);
   my $ents= $dir->entries;
   # Need the 8.3 name in order to know whether it matches the long name
   $dir->build_shortnames;
   # root dir has a volume label ent, and all other dirs have '.' and '..'
   my $n= @$ents + ($dir->is_root? 1 : 2);
   for (@$ents) {
      # Add LFN entries
      if ($_->{name} ne $_->{shortname}) {
         my $utf16= encode('UTF-16LE', $_->{name}, Encode::FB_CROAK|Encode::LEAVE_SRC);
         $n += ceil(length($utf16) / 26);
      }
   }
   $log->debugf("dir %s has %d real entries, %d LFN entries, size=%d ents=%s",
      $dir->name, scalar(@$ents), $n-scalar @$ents, $n*32,
      [ map +( $_->{name} eq $_->{shortname}? $_->{name} : [ @{$_}{'name','shortname'} ] ), @$ents ])
      if $log->is_debug;
   croak "Directory ".$dir->name." exceeds maximum entry count ($n >= 65536)"
      if $n >= 65536;
   $dir->file->{size}= $n * 32;  # always 32 bytes per dirent
}

# Pack one directory and return the buffer
sub _pack_directory($self, $dir) {
   my $data= '';
   my @special= $dir->is_root? (
      { short11 => $self->volume_label // 'NO NAME    ', flags => ATTR_VOLUME_ID },
   ) : (
      { short11 => ".",  flags => ATTR_DIRECTORY, file => $dir->file },
      { short11 => '..', flags => ATTR_DIRECTORY, file => $dir->parent->file },
   );
   for my $ent (@special, sort { lc $a->{name} cmp lc $b->{name} } $dir->entries->@*) {
      my ($name, $file, $shortname, $short11)= @{$ent}{qw( name file shortname short11 )};
      $log->tracef("encoding dirent short=%-12s long=%s cluster=%s",
         $shortname//$short11, $name, $file && $file->cluster);

      unless (length $short11) {
         my ($base, $ext)= split /\./, $shortname;
         $short11= pack 'A8 A3', $base, ($ext//'');
      }
      $short11 =~ s/^\xE5/\x05/; # \xE5 may occur in some charsets, and needs escaped

      # Need Long-File-Name entries?
      if (defined $name && $name ne $shortname) {
         # Checksum for directory shortname, used to verify long name parts
         my $cksum= 0;
         $cksum= ((($cksum >> 1) | ($cksum << 7)) + $_) & 0xFF
            for unpack 'C*', $short11;
         # Each dirent holds up to 26 bytes (13 chars) of the long name
         my @chars= unpack 'v*', encode('UTF-16LE', $name, Encode::FB_CROAK|Encode::LEAVE_SRC);
         # short final chunk is padded with \0\uFFFF*
         if (my $remainder= @chars % 13) {
            push @chars, 0;
            push @chars, (0xFFFF)x(12 - $remainder);
         }
         my $last= ceil(@chars/13) - 1;
         for my $i (reverse 0..$last) {
            my $ofs= $i*13;
            my $seq= ($i + 1) | (($i == $last) ? 0x40 : 0x00);
            $data .= pack('C v5 C C C v6 v v2',
               $seq,                      # sequence and end-flag
               @chars[$ofs .. $ofs+4],    # first 5 chars
               0x0F, 0x00, $cksum,        # attr = LFN, type = 0
               @chars[$ofs+5 .. $ofs+10], # next 6 chars
               0,                         # no cluster number
               @chars[$ofs+11 .. $ofs+12] # last 2 chars
            );
         }
      }

      my $mtime= $ent->{mtime} // ($file && $file->mtime) // time;
      my $atime= $ent->{atime} // ($file && $file->atime) // $mtime;
      my $btime= $ent->{btime} // ($file && $file->btime) // $mtime;
      my ($wdate, $wtime)             = _epoch_to_fat_date_time($mtime);
      my ($cdate, $ctime, $ctime_frac)= _epoch_to_fat_date_time($btime);
      my ($adate)                     = _epoch_to_fat_date_time($atime);
      my $flags= $ent->{flags} // ($file && $file->flags) // 0;
      # References to the root dir are always encoded as cluster zero, even on FAT32
      # where the root dir actually lives at a nonzero cluster.
      # Volume label also doesn't need a cluster id.  Nor do empty files.
      my $cluster= 0;
      if ($file && $file != $self->root->file) {
         $cluster= $file->cluster // croak "File ".$file->name." lacks a defined cluster id";
      }
      # Directories always written as size = 0
      my $size= !$file? 0 : $file->is_dir? 0 : $file->size;
      $log->tracef(" with encoded size=%d cluster=%d", $size, $cluster);
      $data .= pack('A11 C C C v v v v v v v V',
         $short11, $flags, 0, #NT_reserved
         $ctime_frac, $ctime, $cdate, $adate,
         $cluster >> 16, $wtime, $wdate, $cluster, $size);
   }
   die "BUG: calculated dir size ".$dir->file->size." != data length ".length($data)
      unless $dir->file->size == length $data;
   # Dir must be padded to length of sector/cluster with entries whose name begins with \x00
   # but that will happen automatically later as the data is appended to the file.
   $dir->file->{data}= \$data;
}

# Avoiding dependency on namespace::clean
delete @{Sys::Export::VFAT::}{qw(
   carp croak confess encode decode min max ceil blessed dualvar refaddr weaken S_ISDIR S_ISREG
   expand_stat_shorthand isa_array isa_handle isa_hash isa_int isa_pow2 write_file_extent
)};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::VFAT - Write minimal FAT12/16/32 filesystems with control over stored file extents

=head1 SYNOPSIS

  my $dst= Sys::Export::VFAT->new(
    filename => $path,
    volume_label => 'ESP'
    volume_offset => 2048*512, # inform VFAT of your partition layout
  );
  # Basic files and directories
  $dst->add([ file => "README.TXT", "Hello World\r\n" ]);
  $dst->add([ file => 'EFI/BOOT/BOOTIA32.EFI', { data_path => $loader }]);
  
  # Request file 'initrd' have its bytes stored at exactly disk offset 0x110000
  $dst->add([ file => 'initrd', { data_path => $initrd, device_offset => 0x110000 }]);
  
  # Request file 'vmlinuz' have its bytes stored aligned to 2048 disk address,
  #  and capture the location that was chosen into $kernel_ofs
  $dst->add(
    name => 'vmlinuz',
    mode => S_IFREG, # stat constant
    data_path => $path_to_kernel,
    device_align => 2048,
    device_offset => \my $kernel_ofs,
  );
  
  $dst->finish;

=head1 DESCRIPTION

This module can be used as an export destination to build a FAT32/16/12 filesystem by directly
encoding your files into a very compact VFAT layout.  The generated filesystem has no
fragmentation and no free space (unless you specified device_offset/device_align in a way that
created "holes" in your cluster array).

This implementation caches all files in memory, and then chooses FAT parameters that result in
the smallest image.

This implementation also has some fun features intended to work together with the
L<ISOHybrid|Sys::Export::ISOHybrid> module, which can (on the assumption that the filesystem will
never be written) encode hardlinks, encode symlinks as hard-linked directories, and place files
at specific offsets within the generated image.

=head2 FAT Geometry

This was complicated enough it became its own module.  See L<Sys::Export::VFAT::Geometry>.

=head2 Algorithm

This module chooses the optimal cluster size and count for the files you provide.
That choice affects the starting offset of the first cluster, so this module buffers all
directories into memory until the decisions are made, and then writes the whole filesystem in
one pass during L</finish>.

The cluster size/count are chosen by scanning over all the files and directories you have added
and total up the number of clusters required, under each of the possible cluster sizes.  It also
adds in the size of the FAT, which is based on the cluster count.  It also calculates a complete
assignment of files to clusters, to verify it can meet requests for device_offset or
device_align.  It then selects whichever successful configuration had the smallest overall size.
The calculated cluster assignment is then applied to the files and directory entries, and then
the directories get encoded now that the cluster refs are resolved.  Finally, each component
of the filesystem is written to the destination filename or filehandle.

=head1 CONSTRUCTORS

=head2 new

  $fat= Sys::Export::VFAT->new($filename_or_handle);
  $fat= Sys::Export::VFAT->new(%attrs);
  $fat= Sys::Export::VFAT->new(\%attrs);

This takes a list of attributes as a hashref or key/value list.  If there is exactly one
argument, it is treated as the filename attribute.

=head1 ATTRIBUTES

=head2 filename

Name of file (or device) to write.  If the file exists it will be truncated before writing.
If you want to write the filesystem amid existing data (like a partition table0, pass a file
handle as C<filehandle>.

=head2 filehandle

Output filehandle to write.  The file will be enlarged if it is not big enough.

=head2 root

The root L<Directory|Sys::Export::VFAT::Directory> object.

=head2 geometry

An instance of L<Sys::Export::VFAT::Geometry> that describes the size and location of VFAT
structures.  This is generated during L</finish>, but if you have very rigid ideas about how
the filesystem should be laid out, you can pass it to the constructor.

=head2 allocation_table

An instance of L<Sys::Export::VFAT::AllocationTable> used to track which clusters have been
allocated.

=head2 volume_offset

This value causes the entire volume to be written at an offset from the start of the file or
device.  This value is part of the calculation for methods like L</get_file_device_extent> and
alignment of files to device addresses.  If you are writing this filesystem within a partition
of a larger device, set this attribute to get correct device alignments.

If not set, it defaults to 0, so alignments will be performed relative to the start of the
volume, and methods like L</get_file_device_extent> will return ofsets relative to the volume.

=head2 min_bits

Setting this to 32 enforces the generated filesystem will be FAT32 rather than FAT16 or FAT12.
FAT32 has a minimum disk size of about 32MiB, so this has the side effect of forcing a minimum
number of clusters, which may result in a lot of unused space in the generated filesystem.
But, FAT32 is structurally different from FAT12/16 (such as having arbitrary number of reserved
sectors at the start of the image, used for things like boot loaders) and you might require
that even at the expense of wasted space.

=head2 bytes_per_sector

Force a sector size other than the default 512.

=head2 sectors_per_cluster

Force a number of sectors per cluster.  The default is to try different sizes to see which
results in the smallest filesystem.

=head2 fat_count

Force a number of allocation tables.  Two is standard (for redundancy in case of disk errors)
but setting this to C<1> saves some space.

=head2 free_space

By default, the filesystem is created with zero free clusters.  Specify this (in bytes) to add
some free space to the generated filesystem.

=head2 volume_label

Volume label of the generated filesystem

=head1 METHODS

=head2 add

  $fat->add(\%file_attrs);
  # Attributes:
  # {
  #   name               => $path_bytes,
  #   uname              => $path_unicode_string,
  #   FAT_shortname      => "8CHARATR.EXT",
  #   mode               => $unix_stat_mode,
  #   FAT_flags          => ATTR_READONLY|ATTR_HIDDEN|ATTR_SYSTEM|ATTR_ARCHIVE,
  #   atime              => $unix_epoch,
  #   mtime              => $unix_epoch,
  #   btime              => $unix_epoch,
  #   size               => $data_size,
  #   data               => $literal_data_or_scalarref,
  #   device_offset      => $desired_byte_offset,
  #   device_align       => $desired_byte_alignment_pow2,
  # }

This add method takes the same file objects as used by Sys::Export, but with some optional
extras:

=over

=item FAT_shortname

Any file name not conforming to the 8.3 name limitation of FAT will get an auto-generated
"short" filename, in addition to its "long" filename.  If you want control over what short name
is generated, you can specify it with C<FAT_shortname>.

=item FAT_attrs

An ORed combination of L</ATTR_READONLY>, L</ATTR_HIDDEN>, L</ATTR_SYSTEM>, or L</ATTR_ARCHIVE>.
This lets you directly specify the FAT attributes instead of this module guessing them for you.
If not defined, this module guesses C<ATTR_READONLY> based on the unix mode user-write bit,
and guesses C<ATTR_HIDDEN> if there is a leading "." on C<name>.

=item device_offset

For integration with L<ISOHybrid|Sys::Export::ISO9660Hybrid>, you may specify C<device_offset>
to request the file be placed at an exact disk location, and as a single un-fragmented extent.
This accounts for the L</device_offset> of the whole filesystem.  If you did not set that
attribute, this becomes a byte offset from the start of this filesystem.

This offset must fall on the address of one of the clusters of the data region, and will
generate an exception if it can't be honored.  It must also agree with any C<device_align> you
requested on other files.
Unfortunately you won't get that exception until L</finish> is called, as this module looks for
workable cluster layouts.

You may also set this to a scalar-ref which will I<receive> the device_offset once the file's
location is decided.

=item device_align

Like C<device_offset>, but if you just want to request the file be aligned to the device rather
than needing it to exist at a specific offset.  This is a power of 2 measured in bytes, such as
'2048'.  This takes attribute L</volume_offset> into account, possibly providing alignment that
is a multiple of a power-of-2 from the start of the device but not from the start of the volume.

=back

=head2 finish

This method performs all the actual work of building the filesystem.  This module writes the
entire filesystem in one pass after deciding the best geometry and minimal number of clusters
to hold the data you've supplied.

You may get exceptions during this call if there isn't a way to write your files as requested.

=head1 EXPORTS

=head2 is_valid_longname

  $bool= is_valid_longname($name)

C<$name> should be a unicode string

=head2 is_valid_shortname

  $bool= is_valid_shortname($name)

C<$name> should be encoded as platform-native bytes, with no codepoints above 0xFF.
Allows space characters in the name, even though most DOS tools can't handle that.

=head2 is_valid_volume_label

  $bool= is_valid_volume_label($name)

C<$name> should be encoded as platform-native bytes, with no codepoints above 0xFF.

=head2 remove_invalid_shortname_chars

  $name= remove_invalid_shortname_chars($name, $replacement='_')

Coerce an arbitrary string to characters valid as a FAT short name, uppercasing any
lowercase ASCII and replacing illegal characters with '_' or the character of your choice.

=head1 VERSION

version 0.006

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
