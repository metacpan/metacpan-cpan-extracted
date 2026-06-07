package Sys::Export::VFAT::Geometry;

# ABSTRACT: Calculate addresses and sizes of structures within a FAT filesystem
our $VERSION = '0.005'; # VERSION


use v5.26;
use warnings;
use experimental qw( signatures );
use Sys::Export qw( isa_hash isa_int isa_pow2 round_up_to_pow2 round_up_to_multiple );
use Scalar::Util qw( dualvar );
use POSIX 'ceil';
use Carp;
our @CARP_NOT= qw( Sys::Export::VFAT );
use constant {
   FAT12 => dualvar(12, "FAT12"),
   FAT16 => dualvar(16, "FAT16"),
   FAT32 => dualvar(32, "FAT32"),
   FAT12_MAX_CLUSTERS       => 4085-1,
   FAT12_IDEAL_MAX_CLUSTERS => 4085-16,   # docs recommend 16 away from cutoff on either side
   FAT16_MIN_CLUSTERS       => 4085,
   FAT16_IDEAL_MIN_CLUSTERS => 4085+16,
   FAT16_MAX_CLUSTERS       => 65525-1,
   FAT16_IDEAL_MAX_CLUSTERS => 65525-16,
   FAT32_MIN_CLUSTERS       => 65525,
   FAT32_IDEAL_MIN_CLUSTERS => 65525+16,
   FAT32_MAX_CLUSTERS       => 0xFFFFFF5, # can't allow 0xFFFFFF7 to be allocatable ID
};
use Exporter 'import';
our @EXPORT_OK= qw( FAT12 FAT16 FAT32 FAT12_MAX_CLUSTERS FAT12_IDEAL_MAX_CLUSTERS
   FAT16_MIN_CLUSTERS FAT16_IDEAL_MIN_CLUSTERS FAT16_MAX_CLUSTERS FAT16_IDEAL_MAX_CLUSTERS
   FAT32_MIN_CLUSTERS FAT32_IDEAL_MIN_CLUSTERS FAT32_MAX_CLUSTERS );


sub new($class, @attrs) {
   my %attrs= @attrs == 1 && isa_hash $attrs[0]? %{$attrs[0]} : @attrs;
   my ($bytes_per_sector, $sectors_per_cluster,   $fat_count,     $reserved_sector_count,
       $fat_sector_count, $root_dirent_count,     $cluster_count, $total_sector_count,
       $min_bits,         $volume_offset,         $align_clusters
      ) = delete @attrs{qw(
        bytes_per_sector   sectors_per_cluster     fat_count       reserved_sector_count
        fat_sector_count   root_dirent_count       cluster_count   total_sector_count
        min_bits           volume_offset           align_clusters
      )};
   !defined $align_clusters or isa_pow2($align_clusters)
      or croak "align_clusters must be a power of 2 (was $align_clusters)";
   $volume_offset //= 0;
   isa_int($volume_offset) && $volume_offset >= 0
      or croak "volume_offset must be a non-negative integer";

   $bytes_per_sector //= 512;
   isa_pow2($bytes_per_sector) && 512 <= $bytes_per_sector && $bytes_per_sector <= 4096
      or croak "Invalid bytes_per_sector $bytes_per_sector";

   # Default sectors_per_cluster to whatever makes 4K
   $sectors_per_cluster //= ($bytes_per_sector >= 4096? 1 : 4096 / $bytes_per_sector);
   isa_pow2($sectors_per_cluster) && $sectors_per_cluster <= 128 
      or croak "Invalid sectors_per_cluster $sectors_per_cluster";
   my $cluster_size= $bytes_per_sector * $sectors_per_cluster;
   $cluster_size <= 32*1024
      or carp "Warning: bytes_per_sector * sectors_per_cluster > 32KiB which is not valid for some drivers";

   # Default fat_count to 2 unless specified otherwise
   $fat_count //= 2;
   isa_int $fat_count && 0 < $fat_count && $fat_count <= 255
      or croak "Invalid fat_count $fat_count";

   my $self= bless {
      bytes_per_sector      => $bytes_per_sector,
      sectors_per_cluster   => $sectors_per_cluster,
      fat_count             => $fat_count,
      volume_offset         => $volume_offset,
   };
   
   # From here down, we are either determining cluster_count from other properties,
   # or deriving other properties from cluster_count.
   my $bits;
   if (defined $reserved_sector_count && defined $fat_sector_count
    && defined $root_dirent_count && defined $total_sector_count
   ) {
      # All main properties of the geometry are defined.
      my $root_sector_count= int(($root_dirent_count + ($self->dirent_per_sector-1)) / $self->dirent_per_sector);
      my $data_sectors= $total_sector_count - $reserved_sector_count - $fat_count * $fat_sector_count - $root_sector_count;
      my $calc_cluster_count= int($data_sectors / $sectors_per_cluster);
      croak "Supplied cluster_count disagrees with computed value"
         if defined $cluster_count && $cluster_count != $calc_cluster_count;
      $cluster_count //= $calc_cluster_count;
      $bits= $cluster_count < FAT16_MIN_CLUSTERS? FAT12
           : $cluster_count < FAT32_MIN_CLUSTERS? FAT16
           : FAT32;
   }
   elsif (defined $cluster_count) {
      isa_int $cluster_count && $cluster_count > 0
         or croak "Invalid cluster_count '$cluster_count'";
      # FAT docs recommend avoiding numbers near the boundary of FAT12/FAT16/FAT32 to avoid
      # other people's math errors.  But, allow the caller to disable this adjustment.
      unless (delete $attrs{exact_cluster_count}) {
         if ($cluster_count >= FAT12_IDEAL_MAX_CLUSTERS && $cluster_count < FAT16_IDEAL_MIN_CLUSTERS) {
            $cluster_count= FAT16_IDEAL_MIN_CLUSTERS;
         } elsif ($cluster_count >= FAT16_IDEAL_MAX_CLUSTERS && $cluster_count < FAT32_IDEAL_MIN_CLUSTERS) {
            $cluster_count= FAT32_IDEAL_MIN_CLUSTERS;
         }
      }
      # These are the official boundary numbers that determine the filesystem type
      $min_bits //= FAT12;
      $bits= $cluster_count < FAT16_MIN_CLUSTERS? FAT12
              : $cluster_count < FAT32_MIN_CLUSTERS? FAT16
              : FAT32;
      if ($bits < $min_bits) {
         $bits= $min_bits;
         # Increase to the minimum number of clusters if a specific number of bits
         # was requested.
         $cluster_count= ($bits == FAT16)? FAT16_IDEAL_MIN_CLUSTERS : FAT32_IDEAL_MIN_CLUSTERS;
      }
   }
   else {
      croak "Not enough attributes supplied to determine geometry";
   }
   $self->{cluster_count}= $cluster_count;
   $self->{bits}= $bits;

   # Check how many sectors are occupied by each allocation table
   my $fat_byte_count= ( ($cluster_count + 2) * $bits + 7 ) >> 3; # round up to bytes
   if (defined $fat_sector_count) {
      $fat_sector_count * $bytes_per_sector >= $fat_byte_count
         or croak "Invalid fat_sector_count, smaller than $fat_byte_count bytes";
   } else {
      $fat_sector_count= int(($fat_byte_count + ($bytes_per_sector - 1)) / $bytes_per_sector);
   }
   $self->{fat_sector_count}= $fat_sector_count;

   # Check how many sectors are occupied by root directory entries
   # For fat12/16, The FAT spec document suggests 512 as a good default
   # Allow the user to supply the actual number of root entries and then we round that.
   my $used_root_dirent_count= delete $attrs{used_root_dirent_count};
   if ($bits < FAT32) {
      if (defined $root_dirent_count) {
         $root_dirent_count >= 1 && $root_dirent_count < 0xFFFF
            or croak "Invalid root_dirent_count for FAT12/16";
      } else {
         $root_dirent_count= $used_root_dirent_count // 512;
         # Round up to as many as fit in this number of sectors
         my $remainder= ($root_dirent_count & ($self->dirent_per_sector - 1));
         $root_dirent_count += ($self->dirent_per_sector - $remainder)
            if $remainder;
      }
      
      ($reserved_sector_count //= 1) == 1
         or croak "reserved_sector_count should be 1 for FAT12/16";
   } else {
      ($root_dirent_count //= 0) == 0
         or croak "root_dirent_count must be zero for FAT32";

      $reserved_sector_count //= 32;
      isa_int $reserved_sector_count && $reserved_sector_count >= 2
         or croak "reserved_sector_count must be greater than 2 for FAT32";
   }

   # If caller requested alignment of clusters, figure that out
   if (defined $align_clusters && $align_clusters > $bytes_per_sector) {
      # there's a method for this, but avoid caching things yet
      my $data_addr= $volume_offset + $bytes_per_sector * (
         $reserved_sector_count
         + ($fat_count*$fat_sector_count)
         + ceil($root_dirent_count / $self->dirent_per_sector)
      );
      # If the cluster size is greater or equal to the requested alignment, ensure the
      # data start falls on that boundary.
      # If the cluster size is smaller than the requested alignment, ensure the data start
      # falls on a cluster boundary so that some number of clusters will equal the alignment.
      my $align= ($cluster_size >= $align_clusters)? $align_clusters : $cluster_size;
      if (my $ofs= $data_addr & ($align-1)) {
         my $shift_n_sectors= ($align - $ofs) / $bytes_per_sector;
         #say sprintf "# remainder=0x%X, cluster_size=$cluster_size align_clusters=$align_clusters $align-$ofs=".($align-$ofs)." shift %d sectors", $ofs, $shift_n_sectors;
         if ($bits < FAT32) {
            # Reserved sectors should be 1, so expand number of root entries
            $root_dirent_count += $shift_n_sectors * $self->dirent_per_sector;
         } else {
            # Add however many reserved sectors we need
            $reserved_sector_count += $shift_n_sectors;
         }
      }
   }
   $self->{root_dirent_count}= $root_dirent_count;
   $self->{reserved_sector_count}= $reserved_sector_count;
   
   carp "Unused constructor parameters: ".join(' ', keys %attrs)
      if keys %attrs;
   $self;
}


sub volume_offset($self)  { $self->{volume_offset} }

sub bytes_per_sector($self)    { $self->{bytes_per_sector} }
sub sectors_per_cluster($self) { $self->{sectors_per_cluster} }
sub bytes_per_cluster($self)   { $self->{bytes_per_sector} * $self->{sectors_per_cluster} }
sub dirent_per_sector($self)   { $self->{bytes_per_sector} / 32 }
sub dirent_per_cluster($self)  { $self->{bytes_per_sector} * $self->{sectors_per_cluster} / 32 }


sub bits($self)                  { $self->{bits} }
sub reserved_sector_count($self) { $self->{reserved_sector_count} }
sub reserved_size($self)         { $self->{reserved_sector_count} * $self->bytes_per_sector }
sub fat_count($self)             { $self->{fat_count} }
sub fat_sector_count($self)      { $self->{fat_sector_count} }
sub fat_size($self)              { $self->{fat_sector_count} * $self->bytes_per_sector }
sub cluster_count($self)         { $self->{cluster_count} }
sub min_cluster_id($self)        { 2 }
sub max_cluster_id($self)        { $self->cluster_count + 1 }
sub root_dirent_count($self)     { $self->{root_dirent_count} }
sub root_dir_sector_count($self) { ceil($self->root_dirent_count / $self->dirent_per_sector) }
sub root_dir_size($self)         { $self->root_dir_sector_count * $self->bytes_per_sector }

sub root_dir_start_sector($self) {
   $self->reserved_sector_count + $self->fat_count * $self->fat_sector_count
}
sub root_dir_offset($self) { $self->root_dir_start_sector * $self->bytes_per_sector }
sub data_start_sector($self) {
   $self->{data_start_sector} //= $self->root_dir_start_sector + $self->root_dir_sector_count;
}
sub data_limit_sector($self) {
   $self->data_start_sector + $self->cluster_count * $self->sectors_per_cluster
}
sub data_start_offset($self) { $self->data_start_sector * $self->bytes_per_sector }
sub data_limit_offset($self) { $self->data_limit_sector * $self->bytes_per_sector } 
sub data_start_device_offset($self) { $self->volume_offset + $self->data_start_offset }
sub data_limit_device_offset($self) { $self->volume_offset + $self->data_limit_offset }

sub data_sector_count($self) {
   $self->total_sector_count - $self->data_start_sector;
}

sub total_sector_count($self) {
   $self->{total_sector_count} //= $self->data_start_sector
      + $self->cluster_count * $self->sectors_per_cluster;
}
sub total_size($self) { $self->total_sector_count * $self->bytes_per_sector }


sub get_cluster_start_sector($self, $cluster_id) {
   croak "Cluster 0 and 1 are reserved" if $cluster_id < 2;
   croak "Cluster $cluster_id beyond end of volume" if $cluster_id > $self->max_cluster_id;
   return $self->data_start_sector + ($cluster_id-2) * $self->sectors_per_cluster;
}
sub get_cluster_offset($self, $cluster_id) {
   $self->get_cluster_start_sector($cluster_id) * $self->bytes_per_sector;
}
sub get_cluster_device_offset($self, $cluster_id) {
   $self->volume_offset + $self->get_cluster_offset($cluster_id);
}

sub get_cluster_of_sector($self, $sector_idx) {
   return undef if $sector_idx < $self->data_start_sector;
   my $cluster= int(($sector_idx - $self->data_start_sector) / $self->sectors_per_cluster);
   return undef if $cluster >= $self->cluster_count;
   return $cluster + 2;
}
sub get_cluster_of_offset($self, $offset) {
   $self->get_cluster_of_sector(int($offset / $self->bytes_per_sector));
}
sub get_cluster_of_device_offset($self, $addr) {
   $self->get_cluster_of_offset($addr - $self->volume_offset);
}


sub get_cluster_extent_of_volume_extent($self, $offset, $size) {
   my $cl_start= $self->get_cluster_of_offset($offset);
   $cl_start
      or croak "Offset $offset falls outside of cluster data region";
   $self->get_cluster_offset($cl_start) == $offset
      or croak "FAT_offset not aligned to a cluster boundary";
   my $cl_cnt= ceil($size / $self->bytes_per_cluster);
   $cl_start + $cl_cnt <= $self->max_cluster_id+1
      or croak "byte range ($offset, $size) exceeds final cluster of volume";
   return ($cl_start, $cl_cnt);
}


sub get_cluster_extent_of_device_extent($self, $addr, $size) {
   $self->get_cluster_extent_of_volume_extent($addr - $self->volume_offset, $size);
}


sub get_cluster_alignment_of_device_alignment($self, $align) {
   my $cluster_size= $self->bytes_per_cluster;
   # If the cluster size is greater or equal to the requested alignment, verify that the
   # data start (plus the volume offset that was implicitly added to every volume address)
   # meets that alignment.  If so, every cluster is aligned and the return value is (1,0)
   if ($cluster_size >= $align) {
      croak "Clusters are not aligned to $align"
         if $self->data_start_device_offset & ($align-1);
      return (1,0);
   }
   # Otherwise, make sure the data_start (plus implied volume offset) is aligned to
   # cluster_size, so then some multiple of clusters will reach the requested alignment.
   croak "Clusters are not aligned to $cluster_size"
      if $self->data_start_device_offset & ($cluster_size-1);
   # The cluster alignment will be whatever multiple of clusters equals the byte alignment.
   # This will be at least 2.
   my $cl_align= $align / $cluster_size;
   # How many bytes away from alignment is the beginning of ficticious cluster 0?
   my $ofs_of_cl0= ($self->data_start_device_offset - ($cluster_size*2)) & ($align-1);
   # If not aligned, add the rest of the distance to the next alignment.
   my $cl_ofs= !$ofs_of_cl0? 0 : ($align - $ofs_of_cl0) / $cluster_size;
   return ($cl_align, $cl_ofs);
}


sub unpack {
   my $class= shift;
   my $buf_ref= ref $_[0] eq 'SCALAR'? $_[0] : \$_[0];
   my %attrs= ref $_[1] eq 'HASH'? %{$_[1]} : @_[1..$#_];
   length($$buf_ref) >= 512 or croak "Pass at least the entire first sector to 'unpack'";
   # According to the official spec, the only way to know whether you have FAT32 or FAT16
   # is to calculate the count of clusters available in the data region, which this module
   # implements in the constructor.  However, in order to unpack all of the fields of
   # sector0, you have to know whether it is FAT16 or FAT32 because FAT32 moves some of the
   # fields.  But you need those extended fields to calculate whether it is FAT32 or not...
   # It's sort of a bullshit circular dependency when clearly you could use the
   # BPB_RootEntCnt to know whether it was FAT32 or not, since FAT32 will *always* be 0 and
   # the previous generations *can't* be 0.
   # Anyway, instead of uniform single-pass field unpacking, we get this:
   state %fields= qw(
      bytes_per_sector      @11v
      sectors_per_cluster   @13C
      reserved_sector_count @14v
      fat_count             @16C
      root_dirent_count     @17v
      fat_sector_count      @22v
      fat_sector_count32    @36V
      total_sector_count    @19v
      total_sector_count32  @32V
   );
   state @fields= keys %fields;
   state $packstr= join ' ', values %fields;

   @attrs{@fields}= unpack $packstr, $$buf_ref;
   for (qw( fat_sector_count total_sector_count )) {
      my $_32= delete $attrs{$_.'32'};
      $attrs{$_} ||= $_32;
   }
   return $class->new(%attrs);
}

# Avoiding dependency on namespace::clean
delete @{Sys::Export::VFAT::Geometry::}{qw(
   carp confess croak ceil dualvar
   isa_hash isa_int isa_pow2 round_up_to_multiple round_up_to_pow2
)};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::VFAT::Geometry - Calculate addresses and sizes of structures within a FAT filesystem

=head1 SYNOPSIS

From an existing filesystem:

  open my $fh, '<', '/dev/sda1';
  local $/= 4096;
  my $boot_sector= <$fh>;
  my $geom= Sys::Export::VFAT::Geometry->unpack($boot_sector);

Calculate a filesystem sized to hold N clusters of data:

  my $geom= Sys::Export::VFAT::Geometry->new(
    bytes_per_Sector => 512,
    sectors_per_cluster => 8,
    fat_count => 1,
    align_clusters => 4096,
    cluster_count => 12345,
  );

=head1 DESCRIPTION

The goal of Sys::Export::VFAT is to be able to create filesystems where you have dictated the
location or alignment of specific files within the filesystem.  Since it is fairly difficult
to calculate this, it helps to be able to iterate through different filesystem size parameters
until one is found that meets your specification.  This module allows you to construct a
theoretical filesystem based on your parameters, and then query how the clusters line up with
the absolute byte offsets you care about.

This module can also pack and unpack these parameters from a boot sector.

Note that all the defaults in this module aim for B<minimum-sized read-only FAT filesystems>,
not the sensible defaults that would provide free space to add new files at runtime.

The math within is derived from the official published formulas in

  Microsoft Extensible Firmware Initiative
  FAT32 File System Specification
  FAT: General Overview of On-Disk Format
  Version 1.03, December 6, 2000
  Microsoft Corporation

=head2 FAT Structure

To understand the attributes of this module, it helps to first understand how FAT is structured.

FAT defines a Sector as some number of bytes (generally 512) and then a Cluster as a number of
Sectors.  The overall image consists of a header ("reserved clusters"), one or more allocation
tables, and then the data area.
The allocation table is essentially an array of cluster pointers, the optional additional
allocation tables are backup copies of the first, and the data area is an array of clusters.
The allocation table is sized so that it has one cluster pointer per data-area cluster.
This forms a linked list of clusters, so for any file or directory larger than one cluster,
you consult that cluster's entry in the allocation table to find the next cluster.
All files and directories are rounded up to the cluster size when they are stored.  The size of
the cluster pointers depends on the total number of clusters in the filesystem, so for a total
cluster count that fits in 12 bits you get FAT12, if it fits in 16 bits you get FAT16, and up
to 28 bits uses FAT32.  This means that if you specifically need "FAT32" for interoperability
resons (such as badly written BIOSes), there is a minimum filesystem size of ~32MB, because the
selection of 12/16/32 is driven by the cluster count you specify in the header.

The "V" in VFAT refers to the long file name support that Microsoft added with Windows 95.
The directory encoding for FAT only has 11 characters available for each file name, with the
last 3 interpreted as a file extension separated from the name with a dot. (the dot is not
stored)  Rather than inventing a new directory entry encoding, in VFAT they store longer file
names (or any name not conforming to the 8.3 notation) in one or more hidden directory entries
right before the visible one that actually references the file.  This is backward compatible,
so it applies equally well to all the FAT bit-widths.

The newer exFAT format (not supported by this module) is a completely different format, more
similar to modern filesystems which store variable-length directory entries and which describe
file data locations with "extents" (offset and length) rather than an awkward linked list of
cluster numbers.

=head1 CONSTRUCTORS

=head2 new

  $geom= Sys::Export::VFAT::Geometry->new(%options);

There are two officially supported sets of options.  The first is when you know the geometry
parameters from the boot sector of an existing filesystem:

=over

=item bytes_per_sector

=item sectors_per_cluster

=item reserved_sector_count

=item fat_count

=item fat_sector_count

=item root_dirent_count

=item total_sector_count

=back

The second is when you want to to choose parameters for a new filesystem to hold a known number
of clusters:

=over

=item cluster_count

The desired count of usable data clusters for file and directory data.  This may be rounded
upward slightly if it is near a FAT16/FAT32 cutoff.

=item exact_cluster_count

Set this to a true value if you want to prevent rounding upward to a larger bit filesystem
for a cluster_count near the boundary.

=back

Without any further options, you will get 512 byte sectors, 4K clusters, 2 allocation tables,
512 root entries (for FAT12/16), and clusters aligned to 4K.  You may also specify any of the
following options to override those defaults:

=over

=item volume_offset

If you know that this logical volume starts at a nonzero device address, specify this to get
alignments from the start of the device rather than alignments from the start of the volume.

=item align_clusters

Request power-of-2 alignment of device addresses of clusters.  This number is in bytes.
If the number is larger than the size of a cluster, it ensures that at least every Nth cluster
is aligned.  If the number is equal or smaller than the size of a cluster, it ensures that
every cluster has that alignment.

For instance, if you set this to 4096, and the C<volume_offset> is C<512*3> (which would
normally be a poor choice for partition alignment), and the cluster size is also 4096, then
every cluster will have a device address with 0 in the low 12 bits, while having a volume offset
ending with C<512*5> in the low 12 bits.

=item min_bits

One of 12, 16, or 32.  Note that setting this forces a minimum cluster_count, because the
selection of FAT bits is based on number of clusters.  For instance, FAT32 cannot have fewer
than 65525 clusters, which is at least 32MB.

=item bytes_per_sector

The default is 512.

=item sectors_per_cluster

The default is C<4096 / bytes_per_sector>.

=item fat_count

Only one allocation table is required - the rest are backups in case a sector of the first one
is unreadable.  The default is 2, which is more common/compatible (but wastes space if you don't
need to worry about media errors)

=item reserved_sector_count

This allocates extra sectors at the start of the volume.  It must be at least 1 for the boot
sector, and higher on FAT32 for the additional free list and boot sector backup copy.

=item used_root_dirent_count

If you happen to know the exact number of directory entries of your root directory (including
any long filename entries) you can set this to get automatic minimal sizing of the root
directory.

=back

=head2 unpack

  $geom= Sys::Export::VFAT::Geometry->unpack($scalar_or_scalar_ref, %options);

This reads the geometry from a FAT boot sector.  The scalar must be at least the first 512 bytes
of the filesystem.  You should leave most options un-set so that they derive from the boot
sector values, but you might choose to set:

=over

=item volume_offset

If you know the device offset of the FAT volume, setting this lets you use the various
<*_device_offset> attributes and methods accurately.

=back

=head1 ATTRIBUTES

=head2 volume_offset

The device address at which this volume begins.  You must supply this to get meaningful values
from the various C<*_device_*> methods.

=head2 bytes_per_sector

Number of bytes in one disk sector, must be a power of 2 between 512 and 4096.

=head2 sectors_per_cluster

Number of sectors that make one cluster.  Must be a power of 2 between 1 and 128.

=head2 bytes_per_cluster

C<< bytes_per_sector * sectors_per_cluster >>

=head2 dirent_per_sector

Number of 32-byte directory entries in one sector.

=head2 dirent_per_cluster

Number of 32-byte directory entries in one cluster.

=head2 bits

FAT12, FAT16, or FAT32, derived from number of clusters

=head2 reserved_sector_count

Number of sectors at start of volume before FAT tables begin

=head2 reserved_size

C<< reserved_sector_count * bytes_per_sector >>

=head2 fat_count

Number of allocation tables (clones for redundancy)

=head2 fat_sector_count

Number of sectors required to hold each FAT (based on number of clusters and C<bits>).

=head2 fat_size

C<< fat_sector_count * bytes_per_sector >>

=head2 cluster_count

Total number of clusters available for storage (starting from cluster id 2)

=head2 min_cluster_id

Lowest cluster id which can store data.  Always 2.

=head2 max_cluster_id

Highest cluster id which can store data.  C<< cluster_count + 1 >>.

=head2 root_dir_start_sector

First sector of the Fat12/Fat16 root directory.  (Fat32 stores the root dir in the data area)

=head2 root_dir_offset

The byte offset of the Fat12/Fat16 root directory from start of volume.

=head2 root_dir_sector_count

Total number of sectors required to hold the root directory entries.  0 for FAT32, which stores
the root dir in the clusters with everything else.

=head2 root_dir_size

  root_dir_sector_count * bytes_per_sector

=head2 data_start_sector

Sector offset within the volume where the data clusters begin.

=head2 data_start_offset

The byte offset from the start of the volume to the start of the data area.

  data_start_sector * bytes_per_sector

=head2 data_start_device_offset

The start of the data area as an absolute device address.

=head2 data_sector_count

Total number of sectors available for data.

=head2 data_limit_sector

Sector number following the final data sector, such that

  data_limit_sector - data_start_sector = data_sector_count

=head2 data_limit_offset

The byte offset from start of the volume to immediately following the data area.

=head2 data_limit_device_offset

The limit of the data area as an absolute device address.

=head2 total_sector_count

Total number of sectors in the volume.

=head2 total_size

Returns the total size in bytes of the volume.  C<< total_sector_count * bytes_per_sector >>.

=head1 METHODS

=head2 get_cluster_start_sector

  $sector= $geom->get_cluster_start_sector($cluster_id);

Return the sector (from start of volume) where the cluster begins.
Croaks if you pass an invalid cluster ID.

=head2 get_cluster_offset

Same as C<get_cluster_start_sector> but as bytes from start of volume.

=head2 get_cluster_device_offset

Same as C<get_cluster_start_sector> but as an absolute device address based on
L</volume_offset>.

=head2 get_cluster_of_sector

  $cl= $geom->get_cluster_of_sector($sector_idx);

For a sector index (from the start of the volume), return which cluster, if any, contains that
sector.  Returns undef if it doesn't fall within a cluster.

=head2 get_cluster_of_offset

Same as C<get_cluster_of_sector> but from a volume byte offset.

=head2 get_cluster_of_device_offset

Same as C<get_cluster_of_sector> but from an absolute device address based on
L</volume_offset>.

=head2 get_cluster_extent_of_volume_extent

  ($cl_start, $cl_count)= $geom->get_cluster_extent_of_volume_extent($vol_offset, $size);

The caller supplies a range of bytes as an absolute offset from the start of the volume and
a size in bytes.  The offset must also match the start of a cluster, or this dies.
Size does not need to end at a cluster boundary.
This returns the starting cluster number count of clusters occupied (rounding up).
It dies if this range overflows the available clusters.  

=head2 get_cluster_extent_of_device_extent

Like C<get_cluster_extent_of_volume_extent> but specifies the byte range in terms of the device,
factoring in L</volume_offset>.

=head2 get_cluster_alignment_of_device_alignment

  ($mult, $offset)= $geom->get_cluster_alignment_of_device_alignment($align);

The caller supplies a power-of-2 device alignment (such as 4096), and this returns the
multiplier and offset for cluster numbers that will land on that device alignment.

This dies if the specified alignment dosn't fall on any cluster boundary.

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
