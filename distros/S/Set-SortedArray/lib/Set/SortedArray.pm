package Set::SortedArray;

use strict;
use warnings;

=head1 NAME

Set::SortedArray - sets stored as sorted arrays

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Set::SortedArray;
    my $S = Set::SortedArray->new( qw/ d b c a e /);
    my $T = Set::SortedArray->new_presorted( qw/ b c e f g / );

    print $S->as_string, "\n";
    print $S, "\n";

    $U = $S->union($T);
    $I = $S->intersection($T);
    $D = $S->difference($T);
    $E = $S->symmetric_difference($T);
    $A = $S->asymmetric_difference($T);
    $V = $S->unique($T);

    $U = $S + $T;   # union
    $I = $S * $T;   # intersection
    $D = $S - $T;   # difference
    $E = $S % $T;   # symmetric_difference
    $V = $S / $T;   # unique

    $eq = $S->is_equal($T);
    $dj = $S->is_disjoint($T);
    $ps = $S->is_proper_subset($T);
    $pS = $S->is_proper_superset($T);
    $is = $S->is_subset($T);
    $iS = $S->is_superset($T);

    $eq = $S == $T; # equal
    $dj = $S != $T; # disjoint
    $ps = $S <  $T; # is_proper_subset
    $pS = $S >  $T; # is_proper_superset
    $is = $S <= $T; # is_subset
    $iS = $S >= $T; # is_superset

    # amalgam of a few of the above
    $cmp = $S->compare($T);
    $cmp = $S <=> $T;

=head2 DESCRIPTION

Create a set that is stored as a sorted array. Modification is currently
unsupported.

=cut

use overload
  '""'  => \&_as_string,
  '+'   => \&merge,
  '*'   => \&binary_intersection,
  '-'   => \&difference,
  '%'   => \&symmetric_difference,
  '/'   => \&unique,
  '=='  => \&is_equal,
  '!='  => \&is_disjoint,
  '<'   => \&is_proper_subset,
  '>'   => \&is_proper_superset,
  '<='  => \&is_subset,
  '>='  => \&is_superset,
  '<=>' => \&compare;

=head1 CONSTRUCTORS

=head2 new

    $set = Set::SortedArray->new();
    $set = Set::SortedArray->new(@members);

=head2 new_presorted

    $set = Set::SortedArray->new_presorted(@members);

Quicker than new, but doesn't sort data.

=cut

sub new {
    my $class = shift;
    my $self = bless [ sort @_ ], $class;
    return $self;
}

sub new_presorted {
    my $class = shift;
    my $self = bless [@_], $class;
    return $self;
}

=head1 MODIFYING

Currently unsupported. Inserting or deleting would take O(n) time.

=cut

=head1 DISPLAYING

=head2 as_string

    print $S->as_string, "\n";
    print $S, "\n";

=head2 as_string_callback

    Set::SortedArray->as_string_callback(sub { ... });

=cut

# helper function that overload points to
sub _as_string { shift->as_string(@_) }

sub as_string { return '(' . join( ' ', @{ $_[0] } ) . ')' }

sub as_string_callback {
    my ( $class, $callback ) = @_;
    no strict 'refs';
    no warnings;
    *{"${class}::as_string"} = $callback;
}

=head1 QUERYING

=head2 members

=head2 size

=cut

sub members { return @{ $_[0] } }
sub size    { return scalar @{ $_[0] } }

=head1 DERIVING

=head2 union

    $U = $S->union($T);
    $U = $S->union($T, $V);
    $U = $S + $T;
    $U = $S + $T + $V; # inefficient

=cut

sub union {
    return $_[0]->merge( $_[1] ) if ( @_ == 2 );

    my %members;
    foreach my $set (@_) {
        foreach my $member (@$set) {
            $members{$member} ||= $member;
        }
    }

    my $union = bless [ sort values %members ], ref( $_[0] );
    return $union;
}

=head2 merge

    $U = $S->merge($T);
    $U = $S + $T;

Special case of union where only two sets are considered. "+" is actually
overloaded to merge, not union. Named merge since this is essentially the
"merge" step of a mergesort.

=cut

sub merge {
    my ( $S, $T ) = @_;
    my ( $i, $j ) = ( 0, 0 );
    my $U = [];

    while ( ( $i < @$S ) && ( $j < @$T ) ) {
        my $s_i = $S->[$i];
        my $t_j = $T->[$j];

        if ( $s_i eq $t_j ) { push @$U, $s_i; $i++; $j++ }
        elsif ( $s_i lt $t_j ) { push @$U, $s_i; $i++ }
        else                   { push @$U, $t_j; $j++ }
    }

    push @$U, @$S[ $i .. $#$S ];
    push @$U, @$T[ $j .. $#$T ];

    return bless $U, ref($S);
}

=head2 intersection

    $I = $S->intersection($T);
    $I = $S->intersection($T, $U);
    $I = $S * $T;
    $I = $S * $T * $U; # inefficient

=cut

sub intersection {
    return $_[0]->binary_intersection( $_[1] ) if ( @_ == 2 );

    my $total = @_;

    my %members;
    my %counts;

    foreach my $set (@_) {
        foreach my $member (@$set) {
            $members{$member} ||= $member;
            $counts{$member}++;
        }
    }

    my $intersection =
      bless [ sort grep { $counts{$_} == $total } values %members ],
      ref $_[0];
    return $intersection;
}

=head2 binary_intersection

    $I = $S->binary_intersection($T);
    $I = $S * $T;

Special case of intersection where only two sets are considered. "*" is
actually overloaded to binary_intersection, not intersection.

=cut

sub binary_intersection {
    my ( $S, $T ) = @_;
    my ( $i, $j ) = ( 0, 0 );
    my $I = [];

    while ( ( $i < @$S ) && ( $j < @$T ) ) {
        my $s_i = $S->[$i];
        my $t_j = $T->[$j];

        if ( $s_i eq $t_j ) { push @$I, $s_i; $i++; $j++ }
        elsif ( $s_i lt $t_j ) { $i++ }
        else                   { $j++ }
    }

    return bless $I, ref($S);
}

=head2 difference

    $D = $S->difference($T);
    $D = $S - $T;

=cut

sub difference {
    my ( $S, $T ) = @_;
    my ( $i, $j ) = ( 0, 0 );
    my $D = [];

    while ( ( $i < @$S ) && ( $j < @$T ) ) {
        my $s_i = $S->[$i];
        my $t_j = $T->[$j];

        if ( $s_i eq $t_j ) { $i++; $j++ }
        elsif ( $s_i lt $t_j ) { push @$D, $s_i; $i++ }
        else                   { $j++ }
    }

    push @$D, @$S[ $i .. $#$S ];

    return bless $D, ref($S);
}

=head2 symmetric_difference

    $E = $S->symmetric_difference($T);
    $E = $S % $T;

=cut

sub symmetric_difference {
    my ( $S, $T ) = @_;
    my ( $i, $j ) = ( 0, 0 );
    my $E = [];

    while ( ( $i < @$S ) && ( $j < @$T ) ) {
        my $s_i = $S->[$i];
        my $t_j = $T->[$j];

        if ( $s_i eq $t_j ) { $i++; $j++ }
        elsif ( $s_i lt $t_j ) { push @$E, $s_i; $i++ }
        else                   { push @$E, $t_j; $j++ }
    }

    push @$E, @$S[ $i .. $#$S ];
    push @$E, @$T[ $j .. $#$T ];

    return bless $E, ref($S);
}

=head2 asymmetric_difference

    $A = $S->asymmetric_difference($T);

Returns [ $S - $T, $T - $S ], but more efficiently.

=cut

sub asymmetric_difference {
    my ( $S, $T ) = @_;
    my ( $i, $j ) = ( 0, 0 );

    # $D = $S - $T, $B = $T - $S
    # "B" chosen because "b" looks like mirror of "d"
    my ( $D, $B ) = ( [], [] );

    while ( ( $i < @$S ) && ( $j < @$T ) ) {
        my $s_i = $S->[$i];
        my $t_j = $T->[$j];

        if ( $s_i eq $t_j ) { $i++; $j++ }
        elsif ( $s_i lt $t_j ) { push @$D, $s_i; $i++ }
        else                   { push @$B, $t_j; $j++ }
    }
    push @$D, @$S[ $i .. $#$S ];
    push @$B, @$T[ $j .. $#$T ];

    my $class = ref($S);
    bless $D, $class;
    bless $B, $class;
    return [ $D, $B ];
}

=head2 unique

    $V = $S->unique($T);
    $V = $S / $T;

=cut

sub unique {
    pop if ( ( @_ == 3 ) && ( !UNIVERSAL::isa( $_[2], __PACKAGE__ ) ) );

    my %members;
    my %counts;

    foreach my $set (@_) {
        foreach my $member (@$set) {
            $counts{$member}++;
        }
    }

    my $unique =
      bless [ sort grep { $counts{$_} == 1 } values %members ],
      ref $_[0];
    return $unique;
}

=head1 COMPARING

=head2 is_equal

    $eq = $S->is_equal($T);
    $eq = $S == $T;

=cut

sub is_equal {
    my ( $S, $T ) = @_;
    return unless ( @$S == @$T );
    return _is_equal( $S, $T );
}

sub _is_equal {
    my ( $S, $T ) = @_;
    for ( my $i = 0 ; $i < @$S ; $i++ ) {
        return unless ( $S->[$i] eq $T->[$i] );
    }
    return 1;
}

=head2 is_disjoint

    $dj = $S->is_disjoint($T);
    $dj = $S != $T;

=cut

sub is_disjoint {
    my ( $S, $T ) = @_;

    my $i = 0;
    my $j = 0;

    while ( ( $i < @$S ) && ( $j < @$T ) ) {
        my $s_i = $S->[$i];
        my $t_j = $T->[$j];

        if ( $s_i eq $t_j ) { return }
        elsif ( $s_i lt $t_j ) { $i++ }
        else                   { $j++ }
    }

    return 1;
}

=head2 is_proper_subset

    $ps = $S->is_proper_subset($T);
    $ps = $S < $T;

=head2 is_proper_superset

    $pS = $S->is_proper_superset($T);
    $pS = $S > $T;

=head2 is_subset

    $is = $S->is_subset($T);
    $is = $S <= $T;

=head2 is_superset

    $iS = $S->is_superset($T);
    $iS = $S >= $T;

=cut

sub is_proper_subset {
    my ( $S, $T ) = @_;
    return unless ( @$S < @$T );
    return _is_subset( $S, $T );
}

sub is_proper_superset {
    my ( $S, $T ) = @_;
    return unless ( @$S > @$T );
    return _is_subset( $T, $S );
}

sub is_subset {
    my ( $S, $T ) = @_;
    return unless ( @$S <= @$T );
    return _is_subset( $S, $T );
}

sub is_superset {
    my ( $S, $T ) = @_;
    return unless ( @$S >= @$T );
    return _is_subset( $T, $S );
}

sub _is_subset {
    my ( $S, $T ) = @_;

    my $i = 0;
    my $j = 0;

    while ( ( $i < @$S ) && ( $j < @$T ) ) {
        my $s_i = $S->[$i];
        my $t_j = $T->[$j];

        if ( $s_i eq $t_j ) { $i++; $j++; }
        elsif ( $s_i gt $t_j ) { $j++ }
        else                   { return }
    }

    return $i == @$S;
}

=head2 compare

    $cmp = $S->compare($T);
    $cmp = $S <=> $T;

C<compare> returns:

    0  if $S == $T
    1  if $S > $T
    -1 if $S < $T
    () otherwise

=cut

sub compare {
    my ( $S, $T ) = @_;

    if ( my $cmp = $#$S <=> $#$T ) {
        return $cmp == 1
          ? ( _is_subset( $T, $S ) ? 1 : () )
          : ( _is_subset( $S, $T ) ? -1 : () );
    }
    else { return _is_equal( $S, $T ) ? 0 : () }
}

=head1 AUTHOR

"Kevin Galinsky", C<kgalinsky plus cpan at gmail dot com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-set-sortedarray at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-SortedArray>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set::SortedArray

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Set-SortedArray>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Set-SortedArray>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Set-SortedArray>

=item * Search CPAN

L<http://search.cpan.org/dist/Set-SortedArray/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 "Kevin Galinsky".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Set::SortedArray
