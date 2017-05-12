# Set::Partition.pm
#
# Copyright (c) 2006 David Landgren
# All rights reserved

package Set::Partition;
use strict;

use vars qw/$VERSION/;
$VERSION = '0.03';

use constant DEBUG => 0; # if you want to see what's going on

=head1 NAME

Set::Partition - Enumerate all arrangements of a set in fixed subsets

=head1 VERSION

This document describes version 0.03 of Set::Partition,
released 2006-10-11.

=head1 SYNOPSIS

  use Set::Partition;

  my $s = Set::Partition->new(
    list      => [qw(a b c d e)],
    partition => [2, 3],
  );
  while (my $p = $s->next) {
    print join( ' ', map { "(@$_)" } @$p ), $/;
  }
  # produces
  (a b) (c d e)
  (a c) (b d e)
  (a d) (b c e)
  (a e) (b c d)
  (b c) (a d e)
  (b d) (a c e)
  (b e) (a c d)
  (c d) (a b e)
  (c e) (a b d)
  (d e) (a b c)

  # or with a hash
  my $s = Set::Partition->new(
    list      => { b => 'bat', c => 'cat', d => 'dog' },
    partition => [2, 1],
  );
  while (my $p = $s->next) {
    ...
  }

=head1 DESCRIPTION

C<Set::Partition> takes a list or hash of elements  and a list
numbers that represent the sizes of the partitions into which the
list of elements should be arranged.

The resulting object can then be used as an iterator which returns
a reference to an array of lists, that represents the original list
arranged according to the given partitioning. All possible arrangements
are returned, and the object returns C<undef> when the entire
combination space has been exhausted.

=head1 METHODS

=over 8

=item new

Creates a new C<Set::Partition> object. A set of key/value parameters
can be supplied to control the finer details of the object's
behaviour.

B<list>, the list of elements in the set.

B<partition>, the list of integers representing the size of the
partitions used to arrange the set. The sum should be equal to the
number of elements given by B<list>. If it less than the number of
elements, a dummy partition will be added to equalise the count.
This partition will be returned during iteration. If the sum is
greater than the number of elements, C<new()> will C<croak> with a
fatal error.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $part = $args{partition} || [];
    my $in   = $args{list};
    my $list;
    my $val;
    if ($in) {
        if (ref($in) eq 'HASH') {
            $list = [keys %$in];
            $val  = [values %$in];
        }
        else {
            $list = $in;
        }
    }
    else {
        $list = [];
    }
    my $sum  = 0;
    $sum += $_ for @$part;
    if ($sum > @$list) {
        my $list_nr = @$list;
        require Carp;
        Carp::croak("sum of partitions ($sum) exceeds available elements ($list_nr)\n");
    }
    elsif ($sum < @$list) {
        push @$part, @$list - $sum;
    }

    bless {
        list => $list,
        val  => $val,
        part => $args{partition},
        num  => [0..$#$list],
    },
    $class;
}

=item next

Returns the next arrangement of subsets, or C<undef> when all arrangements
have been enumerated.

=cut

sub next {
    my $self  = shift;
    my $list  = $self->{list};
    my $state = $self->{state};
    if ($state) {
        return unless $self->_bump();
    }
    else {
        my $s = 0;
        push @$state, ($s++) x $_ for @{$self->{part}};
        $state ||= [(0) x (@$list)] if @$list; # if no partition was given
        $self->{state} = $state;
    }
    my $out;
    if ($self->{val}) {
        $out->[$state->[$_]]{$list->[$_]} = $self->{val}[$_] for @{$self->{num}};
    }
    else {
        push @{$out->[$state->[$_]]}, $list->[$_] for @{$self->{num}};
    }
    DEBUG and print "@{$self->{state}}\n";
    return $out;
}

sub _bump {
    my $self = shift;
    my $in   = $self->{state};
    my $end  = $#$in;
    my $off  = $end-1;
    my $inc  = 0;
    while ($off >= 0) {
        my $sib = $off+1;
        ++$inc if $in->[$off] > $in->[$sib];
        if ($in->[$off] < $in->[$sib]) {
            if ($in->[$sib] > 1+$in->[$off]) {
                # find smallest in [$sib..$end] > $in->[$off];
                my $next = @$in;
                while (--$next) {
                    last if $in->[$next] > $in->[$off];
                }
                (@{$in}[$off, $next]) = (@{$in}[$next, $off]);
                if (DEBUG) {
                    print "@$in (reverse @{$in}[$sib..$end] needed)\n"
                        if $sib < $end;
                }
                @{$in}[$sib..$end] = reverse @{$in}[$sib..$end]
                    if $sib < $end;
            }
            else {
                # just have to flip the current and next
                DEBUG and print +(' ' x ($off*2)) . "^ ^\n";
                (@{$in}[$off, $sib]) = (@{$in}[$sib, $off]);
                if (DEBUG) {
                    print "@$in (sort @{$in}[$sib..$end] needed d=$inc)\n"
                        if $sib < $end and $inc;
                }
                # have to sort
                @{$in}[$sib..$end] = sort {$a <=> $b} @{$in}[$sib..$end]
                    if $sib < $end and $inc;
            }
            return 1;
        }
        --$off;
    }
    return 0;
}

=item reset

Resets the object, which causes it to enumerate the arrangements from the
beginning.

  $p->reset; # begin again

=cut

sub reset {
    my $self  = shift;
    delete $self->{state};
    return $self;
}

=back

=head1 DIAGNOSTICS

=head2 sum of partitions (%d) exceeds available elements (%d)

A list of partition sizes (for instance, 2, 3, 4) was given, along
with a list to partition (for instance, containing 8 elements),
however, the number of elements required to fill the different
partitions (9) exceeds the number available in the source list (8).

=head1 NOTES

The order within a set is unimportant, thus, if

  (a b) (c d)

is produced, then the following arrangement will never be encountered:

  (a b) (d c)

On the other hand, the order of the sets is important, which means
that the following arrangement I<will> be encountered:

  (c d) (a b)

=head1 SEE ALSO

=over 8

=item L<Algorithm::Combinatorics>

Permutations, combinations, derangements and more; all you need
for your set transformations.

=back

=head1 BUGS

Using a partition of length 0 is valid, although you get back an C<undef>,
rather than an empty array. This could be construed as a bug.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Set-Partition|rt.cpan.org>

Make sure you include the output from the following two commands:

  perl -MSet::Partition -le 'print Set::Partition::VERSION'
  perl -V

=head1 ACKNOWLEDGEMENTS

Ken Williams suggested the possibility to use a hash as a source
for partitioning.

=head1 AUTHOR

David Landgren, copyright (C) 2006. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it. If you
want to be informed of updates, send me a note. You know my first
name, you know my domain. Can you guess my e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

'The Lusty Decadent Delights of Imperial Pompeii';
__END__
