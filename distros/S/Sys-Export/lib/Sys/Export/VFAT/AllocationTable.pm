package Sys::Export::VFAT::AllocationTable;

# ABSTRACT: Track which FAT clusters are used, and by what
our $VERSION = '0.006'; # VERSION


# Element 0 of the FAT is used for an inversion list of which sectors are allocated.
# It's not as good as a tree, but should perform well when the typical use case is
# to pack files end to end without fragmentation.
use v5.26;
use warnings;
use experimental qw( signatures );
use Scalar::Util 'refaddr';
use Carp;
use Sys::Export qw( isa_int );
use Sys::Export::VFAT::Geometry qw( FAT12_MAX_CLUSTERS FAT16_MAX_CLUSTERS FAT32_MAX_CLUSTERS );


sub fat            { $_[0]{fat} }
sub _invlist       { $_[0]{_invlist} }
sub chains         { $_[0]{chains} }
sub max_cluster_id { @_ > 1? $_[0]->set_max_cluster_id($_[1]) : $_[0]{max_cluster_id} }
sub max_used_cluster_id { $_[0]{_invlist}[-1] - 1 }


sub first_free_cluster {
   my ($first_free, $max)= ($_[0]{_invlist}[1], $_[0]{max_cluster_id});
   defined $max && $first_free > $max? undef : $first_free;
}


sub set_max_cluster_id($self, $val) {
   if (defined $val) {
      my $min= $self->max_used_cluster_id;
      croak "Cannot set max_cluster_id less than max_used_cluster_id"
         if defined $min && $val < $min;
      croak "Cannot set max_cluster_id less than 2"
         if $val < 2;
   }
   $self->{max_cluster_id}= $val;
}


sub free_cluster_count($self) {
   my ($sum, $inv, $max)= (0, $self->{_invlist}, $self->{max_cluster_id});
   for (my $i= 1; $i < $#$inv; $i += 2) {
      $sum += $inv->[$i+1] - $inv->[$i];
   }
   $sum += $max - ($inv->[-1]-1) if defined $max;
   return $sum;
}


sub get_chain($self, $cl_id) {
   $self->{chains}{$cl_id};
}


sub new($class, @attrs) {
   my %attrs= @attrs == 1 && ref $attrs[0] eq 'HASH'? %{$attrs[0]} : @attrs;
   my $max_cluster_id= delete $attrs{max_cluster_id};
   croak "Invalid max_cluster_id"
      unless !defined $max_cluster_id or isa_int $max_cluster_id && $max_cluster_id >= 2;
   carp "Unrecognized attributes ".join(', ', keys %attrs)
      if keys %attrs;

   bless {
      max_cluster_id => $max_cluster_id,
      fat => [],
      _invlist => [ 0, 2 ], # mark 0-1 as allocated, to remove empty-list edge cases
      chains => {},
   }, $class;
}


sub alloc($self, $count) {
   return 0 unless $count;
   croak "Cluster count must be an unsigned integer"
      unless isa_int $count && $count > 0;
   my $inv= $self->{_invlist};
   my $lim= $self->{max_cluster_id}? $self->{max_cluster_id}+1 : undef;
   # If there are enough free sectors, this basically just removes gaps in the inversion list.
   for (my $i= 1; $i < @$inv; $i+= 2) {
      my ($from, $upto)= @{$inv}[$i,$i+1];
      my $n= defined $upto? ($upto - $from) : undef;
      if (!defined $n || $n >= $count) {
         my @result;
         if (!defined $n) { # allocate from final region up to max sector
            last if defined $lim && $lim - $from < $count;
            @result= (splice(@$inv, 1, $i, $from + $count), $from+$count);
         }
         elsif ($n == $count) { # result comes from exactly the gaps between other allocation
            @result= splice(@$inv, 1, $i+1);
         }
         else { # result comes from partial gap
            @result= (splice(@$inv, 1, $i-1), $from, $from+$count);
            $inv->[1]= $from + $count;
         }
         # and build the cluster chain in the FAT
         my $prev= 0;
         for (my $j= 0; $j < @result; $j += 2) {
            for ($result[$j] .. ($result[$j+1]-1)) {
               $self->{fat}[$prev]= $_ if $prev;
               $prev= $_;
            }
         }
         $self->{fat}[$prev]= 0x0FFFFFFF;
         $self->{chains}{$result[0]}{invlist}= \@result;
         return $result[0];
      }
      $count -= $n;
   }
   return undef; # not enough available
}


sub alloc_range($self, $cluster_id, $count) {
   return 0 unless $count;
   croak "Cluster count must be an unsigned integer"
      unless isa_int $count && $count > 0;
   croak "Invalid cluster id '$cluster_id'"
      unless isa_int $cluster_id && $cluster_id >= 2;
   return $self->_alloc_range($cluster_id, $cluster_id + $count);
}


sub alloc_contiguous($self, $count, $align=1, $align_ofs=0) {
   return 0 unless $count;
   croak "Cluster count must be an unsigned integer"
      unless isa_int $count && $count > 0;
   my $inv= $self->{_invlist};
   for (my $i= 1; $i < @$inv; $i+=2) {
      my ($from, $upto)= @{$inv}[$i, $i+1];
      my $start= $from;
      # Align start addr
      if ($align > 1) {
         my $remainder= ($start - $align_ofs) & ($align-1);
         $start += $align - $remainder if $remainder;
      }
      # Is the range large enough?
      next if defined $upto && $upto - $start < $count;
      return $self->_alloc_range($start, $start+$count, $i);
   }
   return undef;
}

# add the range ($start, $lim) to an inversion list where idx is pointed at
# the first range that wasn't entirely before $start
sub _invlist_alloc($inv, $start, $lim, $idx=undef) {
   unless (defined $idx) {
      for ($idx= 0; $idx < $#$inv && $inv->[$idx+1] <= $start; $idx++) {}
      # here, [idx] is less/eq start, and [idx+1] is not (or doesn't exist)
      # If idx is even, it means start fell within an allocated range
      return 0 unless $idx & 1;
   }
   my $from_edge= $inv->[$idx] == $start;
   # allocating at the end
   if ($idx == $#$inv) {
      # max_cluster_id was checked by caller
      $from_edge? ($inv->[$idx]= $lim)
      : push(@$inv, $start, $lim);
   }
   else {
      # does 'lim' exceed the gap between allocations?
      return 0 if $lim > $inv->[$idx+1];
      my $to_edge= $lim == $inv->[$idx+1];
      $from_edge && $to_edge? splice(@$inv, $idx, 2)
      : $from_edge?           ($inv->[$idx]= $lim)
      : $to_edge?             ($inv->[$idx+1]= $start)
      : splice(@$inv, $idx+1, 0, $start, $lim);
   }
   return 1;
}

sub _alloc_range($self, $cl_start, $cl_lim, $invlist_idx=undef) {
   return undef if $self->max_cluster_id && $cl_lim-1 > $self->max_cluster_id;
   return undef unless _invlist_alloc($self->{_invlist}, $cl_start, $cl_lim, $invlist_idx);
   # Build the cluster chain in the FAT
   $self->{fat}[$_]= $_+1
      for $cl_start .. $cl_lim-2;
   $self->{fat}[$cl_lim-1]= 0x0FFFFFFF;
   # An allocation inversion list of one segment
   $self->{chains}{$cl_start}{invlist}= [ $cl_start, $cl_lim ];
   return $cl_start;
}


sub pack($self, $bits=undef) {
   my $fat= $self->fat;
   my $max= $self->max_cluster_id // $self->max_used_cluster_id;
   my $cl_count= $max-1; # excluding clusters 0 and 1
   croak "Max cluster ID exceeds FAT32 max" if $cl_count > FAT32_MAX_CLUSTERS;
   carp "Truncating table to cluster id $max" if $max < $#$fat;
   $#$fat= $max;
   $fat->[$_]= 0x0FFFFFFF for 0,1;
   $fat->[$_] //= 0 for 2..$max;   # prevent warnings in pack
   if ($cl_count > FAT16_MAX_CLUSTERS) {
      return pack 'V*', @$fat;
   } elsif ($cl_count > FAT12_MAX_CLUSTERS) {
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

# Avoiding dependency on namespace::clean
delete @{Sys::Export::VFAT::AllocationTable::}{qw( carp confess croak refaddr isa_int )};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::VFAT::AllocationTable - Track which FAT clusters are used, and by what

=head1 SYNOPSIS

  $alloc= Sys::Export::VFAT::AllocationTable->new();
  $alloc->alloc_file(\%file_attrs);

=head1 DESCRIPTION

This module manages an allocation table for a FAT filesystem.  The allocation table is an array
with one element per disk cluster (aside from index 0 and 1 which do not have a cluster
allocated), which acts like a linked list.  The value of each element says whether the cluster
is used (>0), what cluster follows it, and whether it is the final cluster in the chain.
For FAT32, it also has bits to flag clusters with disk errors.

This module can also pair file/directory metadata with the starting cluster of each chain.

=head1 CONSTRUCTORS

=head2 new

  $at= Sys::Export::VFAT::AllocationTable->new(%attrs);

Currently the only attribute that can actually be set in the constructor is C<max_cluster_id>.

=head1 ATTRIBUTES

=head2 fat

Direct access to the allocation table array.  Don't modify it directly.

=head2 chains

Hash keyed by starting-cluster ID which holds metadata about what is stored there.
The metadata may include C<invlist> which is an inversion-list representation of the chain,
or C<dir> which is an unpacked directory.

=head2 max_cluster_id

The maximum value for a cluster ID, which is also the maximum element of the L</fat> array.
This may be C<undef> to avoid exceptions while sizing up your data.

=head2 max_used_cluster_id

The maximum cluster number which was allocated so far.

=head2 first_free_cluster

When dynamically growing the table (undef max_cluster_id) this is always defined as the next
unallocated cluster number.  When there is a defined max_cluster_id, this becomes undef after
all clusters have been allocated.

=head2 free_cluster_count

When dynamically growing the table (undef max_cluster_id) this only reports free "holes" in
the allocations so far, and 0 otherwise.  When max_cluster_id is defined, this gives the actual
number of unallocated clusters.

=head1 METHODS

=head2 set_max_cluster_id

This can change the allocation between dynamically-growing (C<undef>) and fixed-length.
The number must be 2 or greater, and cannot be less than max_used_cluster_id.

=head2 get_chain

  $metadata= $self->get_chain($cluster_id);

Returns the metadata associated with the head cluster of a cluster chain.
Clusters which are not the heads of chains return nothing.

=head2 alloc

  $cl_head= $at->alloc($cl_count);

Create a cluster chain of C<$cl_count> clusters from anywhere in the table and return the
cluster ID of the head of the chain.  C<$cl_count> must be an integer.
A request for 0 clusters returns cluster ID 0.

=head2 alloc_range

  $cl_head= $at->alloc_range($cl_id, $cl_count);

Create a cluster chain from a specific extent of clusters.  If any cluster was already allocated
this fails and returns false.  C<$cl_id> must be 2 or larger.
A request for 0 clusters returns cluster ID 0.

=head2 alloc_contiguous

  $cl_head= $at->alloc_contiguous($cl_count, $align=1, $align_ofs=0);

Allocate the first available contiguous span of C<$cl_count> clusters, optionally restricted to
the cluster ID being a multiple of a power-of-two alignment, when offset by C<$align_ofs>.

See L<Sys::Export::VFAT::Geometry/get_cluster_alignment_of_device_alignment>.

=head2 pack

  $buf= $at->pack

Pack the allocation table into bytes.  This selects FAT12/FAT16/FAT32 by the total number of
clusters.  Make sure you set L</max_cluster_id> correctly before calling this.

=head1 VERSION

version 0.006

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
