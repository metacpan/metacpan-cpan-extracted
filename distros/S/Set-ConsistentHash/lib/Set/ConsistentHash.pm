package Set::ConsistentHash;
use strict;
use Digest::SHA1 qw(sha1);
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = '0.92';

=head1 NAME

Set::ConsistentHash - library for doing consistent hashing

=head1 SYNOPSIS

  my $set = Set::ConsistentHash->new;

=head1 OVERVIEW

Description, shamelessly stolen from Wikipedia:

  Consistent hashing is a scheme that provides hash table
  functionality in a way that the addition or removal of one slot does
  not significantly change the mapping of keys to slots. In contrast,
  in most traditional hash tables, a change in the number of array
  slots causes nearly all keys to be remapped.

  Consistent hashing was introduced in 1997 as a way of distributing
  requests among a changing population of web servers. More recently,
  it and similar techniques have been employed in distributed hash
  tables.

You're encouraged to read the original paper, linked below.

=head1 TERMINOLOGY

Terminology about this stuff seems to vary.  For clarity, this module
uses the following:

B<Consistent Hash> -- The object you work with.  Contains 0 or more
"targets", each with a weight.

B<Target> -- A member of the set.  The weight (an arbitrary number),
specifies how often it occurs relative to other targets.

=head1 CLASS METHODS

=head2 new

  $set = Set::ConsistentHash->new;

Takes no options.  Creates a new consistent hashing set with no
targets.  You'll need to add them.

=cut

# creates a new consistent hashing set with no targets.  you'll need to add targets.
sub new {
    my $class = shift;
    croak("Unknown parameters") if @_;
    my $self = bless {
        weights => {},  # $target => integer $weight
        points  => {},  # 32-bit value points on 'circle' => \$target
        order   => [],  # 32-bit points, sorted
        buckets      => undef, # when requested, arrayref of 1024 buckets mapping to targets
        total_weight => undef, # when requested, total weight of all targets
        hash_func    => undef, # hash function for key lookup
    }, $class;
    return $self;
}

############################################################################

=head1 INSTANCE METHODS

=cut

############################################################################

=head2 targets

Returns (alphabetically sorted) array of all targets in set.

=cut

sub targets {
    my $self = shift;
    return sort keys %{$self->{weights}};
}

############################################################################

=head2 reset_targets

Remove all targets.

=cut

sub reset_targets {
    my $self = shift;
    $self->modify_targets(map { $_ => 0 } $self->targets);
}
*clear = \&reset_targets;

############################################################################

=head2 set_targets

    $set->set_targets(%target_to_weight);
    $set->set_targets("foo" => 5, "bar" => 10);

Removes all targets, then sets the provided ones with the weightings provided.

=cut

sub set_targets {
    my $self = shift;
    $self->reset_targets;
    $self->modify_targets(@_);
}

############################################################################

=head2 modify_targets

    $set->modify_targets(%target_to_weight);

Without removing existing targets, modifies the weighting of provided
targets.  A weight of undef or 0 removes an item from the set.

=cut

# add/modify targets.  parameters are %weights:  $target -> $weight
sub modify_targets {
    my ($self, %weights) = @_;

    # uncache stuff:
    $self->{total_weight} = undef;
    $self->{buckets}      = undef;

    while (my ($target, $weight) = each %weights) {
        if ($weight) {
            $self->{weights}{$target} = $weight;
        } else {
            delete $self->{weights}{$target};
        }
    }
    $self->_redo_circle;
}

############################################################################

=head2 set_target

    $set->set_target($target => $weight);

A wrapper around modify_targets that sounds better for modifying a single item.

=cut

*set_target = \&modify_targets;

############################################################################

=head2 total_weight

Returns sum of all current targets' weights.

=cut

#'
sub total_weight {
    my $self = shift;
    return $self->{total_weight} if defined $self->{total_weight};
    my $sum = 0;
    foreach my $val (values %{$self->{weights}}) {
        $sum += $val;
    }
    return $self->{total_weight} = $sum;
}

############################################################################

=head2 percent_weight

   $weight = $set->percent_weight($target);
   $weight = $set->percent_weight("10.0.0.2");

Returns number in range [0,100] representing percentage of weight that provided $target has.

=cut

sub percent_weight {
    my ($self, $target) = @_;
    return 0 unless $self->{weights}{$target};
    return 100 * $self->{weights}{$target} / $self->total_weight;
}

############################################################################

=head2 set_hash_func

    $set->set_hash_func(\&your_hash_func);

Sets the function with which keys will be hashed before looking up
which target they will be mapped onto.

=cut

sub set_hash_func {
    my ($self, $hash_func) = @_;
    $self->{hash_func} = $hash_func;
}

############################################################################

=head2 get_target

    $selected_target = $set->get_target(your_hash_func($your_key));

    - or -

    $set->set_hash_func(\&your_hash_func);
    $selected_target = $set->get_target($your_key);

Given a key, select the target in the set to which that key is mapped.

If you find the target (say, a server) to be dead or otherwise
unavailable, remove it from the set, and get the target again.

=cut

sub get_target {
    my ($self, $key) = @_;
    _compute_buckets($self) unless $self->{buckets};
    $key = $self->{hash_func}->($key) if $self->{hash_func};
    return $self->{buckets}->[$key % 1024];
}

=head2 buckets

    $selected_target = $set->buckets->[your_hash_func($your_key) % 1024];

Returns an arrayref of 1024 selected items from the set, in a consistent order.

This is what you want to use to actually select items quickly in your
application.

If you find the target (say, a server) to be dead, or otherwise
unavailable, remove it from the set, and look at that index in the
bucket arrayref again.

=cut

# returns arrayref of 1024 buckets.  each array element is the $target for that bucket index.
sub buckets {
    my $self = shift;
    _compute_buckets($self) unless $self->{buckets};
    return $self->{buckets};
}

############################################################################

=head1 INTERNALS

=head2 _compute_buckets

Computes and returns an array of 1024 selected items from the set,
in a consistent order.

=cut

# Computes and returns array of 1024 buckets.  Each array element is the
# $target for that bucket index.
sub _compute_buckets {
    my $self = shift;
    my @buckets = ();
    my $by = 2**22;  # 2**32 / 2**10 (1024)
    my $pt = 0;
    for my $n (0..1023) {
        $buckets[$n] = $self->target_of_point($pt);
        $pt += $by;
    }
    return $self->{buckets} = \@buckets;
}

=head2 target_of_point

   $target = $set->target_of_point($point)

Given a $point, an integer in the range [0,2**32), returns (somewhat
slowly), the next target found, clockwise from that point on the circle.

This is mostly an internal method, used to generated the 1024-element
cached bucket arrayref when needed.  You probably don't want to use this.
Instead, use the B<buckets> method, and run your hash function on your key,
generating an integer, modulous 1024, and looking up that bucket index's target.

=cut

# given a $point [0,2**32), returns the $target that's next going around the circle
sub target_of_point {
    my ($self, $pt) = @_;  # $pt is 32-bit unsigned integer

    my $order = $self->{order};
    my $circle_pt = $self->{points};

    my ($lo, $hi) = (0, scalar(@$order)-1);  # inclusive candidates

    while (1) {
        my $mid           = int(($lo + $hi) / 2);
        my $val_at_mid    = $order->[$mid];
        my $val_one_below = $mid ? $order->[$mid-1] : 0;

        # match
        return ${ $circle_pt->{$order->[$mid]} } if
            $pt <= $val_at_mid && $pt > $val_one_below;

        # wrap-around match
        return ${ $circle_pt->{$order->[0]} } if
            $lo == $hi;

        # too low, go up.
        if ($val_at_mid < $pt) {
            $lo = $mid + 1;
            $lo = $hi if $lo > $hi;
        }
        # too high
        else {
            $hi = $mid - 1;
            $hi = $lo if $hi < $lo;
        }

        next;
    }
};

############################################################################
#  Internal...
############################################################################

sub _redo_circle {
    my $self = shift;

    my $pts = $self->{points} = {};
    while (my ($target, $weight) = each %{$self->{weights}}) {
        my $num_pts = $weight * 100;
        foreach my $ptn (1..$num_pts) {
            my $key = "$target-$ptn";
            my $val = unpack("L", substr(sha1($key), 0, 4));
            $pts->{$val} = \$target;
        }
    }

    $self->{order} = [ sort { $a <=> $b } keys %$pts ];
}


=head1 REFERENCES

L<http://en.wikipedia.org/wiki/Consistent_hashing>

L<http://www8.org/w8-papers/2a-webserver/caching/paper2.html>

=head1 AUTHOR

Brad Fitzpatrick -- brad@danga.com

=head1 CONTRIBUTING

Bug, performance, doc, feature patch?  See
L<http://contributing.appspot.com/set-consistenthash-perl>

=head1 COPYRIGHT & LICENSE

Copyright 2007, Six Apart, Ltd.

You're granted permission to use this code under the same terms as Perl itself.

=head1 WARRANTY

This is free software.  It comes with no warranty of any kind.

=cut

1;
