package Set::Product::XS;

use strict;
use warnings;

use Exporter qw(import);
use XSLoader;

our $VERSION    = '0.03';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

our @EXPORT_OK = qw(product);


1;

__END__

=head1 NAME

Set::Product::XS - speed up Set::Product

=head1 SYNOPSIS

    use Set::Product qw(product);

    product { say "@_" } [1..10], ['A'..'E'], ['u'..'z'];

=head1 DESCRIPTION

The C<Set::Product::XS> module provides a faster XS implementation for
C<Set::Product>. It will automatically be used, if available.

=head1 FUNCTIONS

=head2 product

    product { BLOCK } \@array1, \@array2, ...

Evaluates C<BLOCK> and sets @_ to each tuple in the cartesian product for the
list of array references.

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

L<Set::Product>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Set-Product-XS>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set::Product::XS

You can also look for information at:

=over

=item * GitHub Source Repository

L<https://github.com/gray/set-product-xs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Set-Product-XS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Set-Product-XS>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Set-Product-XS>

=item * Search CPAN

L<http://search.cpan.org/dist/Set-Product-XS/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
