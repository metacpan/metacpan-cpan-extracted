package Set::Product;

use strict;
use warnings;

use Exporter qw(import);

our $VERSION = '0.03';
$VERSION = eval $VERSION;

our @EXPORT_OK = qw(product);

my $want_pp = $ENV{SET_PRODUCT_PP} || $ENV{PURE_PERL};
if ($want_pp or ! eval { require Set::Product::XS; 1 }) {
    require Set::Product::PP;
    Set::Product::PP->import(@EXPORT_OK);
}
else {
    Set::Product::XS->import(@EXPORT_OK);
}


1;

__END__

=head1 NAME

Set::Product - generates the cartesian product of a set of lists

=head1 SYNOPSIS

    use Set::Product qw(product);

    product { say "@_" } [1..10], ['A'..'E'], ['u'..'z'];

=head1 DESCRIPTION

The C<Set::Product> module generates the cartesian product of a set of lists.

=head1 FUNCTIONS

=head2 product

    product { BLOCK } \@array1, \@array2, ...

Evaluates C<BLOCK> and sets @_ to each tuple in the cartesian product for the
list of array references.

=head1 NOTES

If C<Set::Product::XS> is installed, this module will automatically use it.
You can prevent that and stick with the pure Perl version by setting the
C<SET_PRODUCT_PP> or C<PURE_PERL> environment varible before using this module.

=head1 PERFORMANCE

This distribution contains a benchmarking script which compares several
modules available on CPAN. These are the results on a MacBook 2.6GHz Core i5
(64-bit) with Perl 5.22.0:

    Set::CrossProduct          45.06+-0.54/s
    List::Gen                  61.94+-0.22/s
    Algorithm::Loops           70.25+-0.55/s
    Set::Scalar                  96.5+-1.7/s
    Math::Cartesian::Product      212.5+-2/s
    Set::Product::PP          283.52+-0.34/s
    Set::Product::XS         1003.05+-0.21/s

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Cartesian_product>

L<Set::Product::XS>

L<Algorithm::Loops>

L<List::Gen>

L<Math::Cartesian::Product>

L<Set::CrossProduct>

L<Set::Scalar>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Set-Product>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set::Product

You can also look for information at:

=over

=item * GitHub Source Repository

L<https://github.com/gray/set-product>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Set-Product>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Set-Product>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Set-Product>

=item * Search CPAN

L<http://search.cpan.org/dist/Set-Product/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
