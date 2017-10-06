package Set::Product::XS;

use strict;
use warnings;

use Exporter qw(import);
use XSLoader;

our $VERSION    = '0.04';
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
(64-bit) with Perl 5.26.1:

    Set::CrossProduct           31.17+-0.2/s
    List::MapMulti             34.16+-0.21/s
    Algorithm::Loops             86.3+-1.5/s
    Set::Scalar               138.15+-0.56/s
    Math::Cartesian::Product      244+-1.8/s
    Set::Product::PP              306+-3.6/s
    Set::Product::XS         1066.58+-0.24/s

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

Copyright (C) 2015-2017 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
