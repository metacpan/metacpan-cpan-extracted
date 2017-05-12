package Set::Product::PP;

use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);
use Scalar::Util qw(reftype);

our @EXPORT_OK = qw(product);

sub product (&@) {
    my ($sub, @in) = @_;

    croak 'Not a subroutine reference'
        unless 'CODE' eq (reftype($sub) || '');
    croak 'Not an array reference'
        if grep { 'ARRAY' ne (reftype($_) || '') } @in;
    return if ! @in or grep { ! @$_ } @in;

    my @out = map { $in[$_]->[0] } 0 .. $#in;
    my @idx = (0) x @in;

    for (my $i = 0; $i >= 0; ) {
        $sub->(@out);
        for ($i=$#in; $i >= 0; $i--) {
            $idx[$i]++;
            if ($idx[$i] > $#{$in[$i]}) {
                $idx[$i] = 0;
                $out[$i] = $in[$i]->[0];
            }
            else {
                $out[$i] = $in[$i]->[$idx[$i]];
                last;
            }
        }
    }
}


1;

__END__

=head1 NAME

Set::Product::PP - Pure Perl implementation

=head1 SYNOPSIS

    use Set::Product qw(product);

    product { say "@_" } [1..10], ['A'..'E'], ['u'..'z'];

=head1 DESCRIPTION

This is the default pure Perl implementation used by C<Set::Product>.

=head1 FUNCTIONS

=head2 product

    product { BLOCK } \@array1, \@array2, ...

Evaluates C<BLOCK> and sets @_ to each tuple in the cartesian product for the
list of array references.

=head1 SEE ALSO

L<Set::Product>

L<Set::Product::XS>

=cut
