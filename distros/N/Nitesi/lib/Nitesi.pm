package Nitesi;

=head1 NAME

Nitesi - Open Source Shop Machine

=head1 VERSION

0.0094

=cut

our $VERSION = '0.0094';

=head1 DESCRIPTION

Nitesi, the Open Source Shop Machine, is the Modern Perl ecosystem
for online business.

This module provides the following APIs:

=over 4

=item Carts

L<Nitesi::Cart>

=item Products

L<Nitesi::Product>

=item Account Management

L<Nitesi::Account::Manager>

=back

To build your own business website, please take a look at
our Dancer plugin: L<Dancer::Plugin::Nitesi>.

=head1 BUNDLES
    
The following bundles are available for Nitesi:

=over 4

=item DBI

L<Nitesi::DBI>

=back
    
=head1 CART

Nitesi supports multiple carts, automatic collapsing of similar items
and price caching.

=head1 CAVEATS

Please anticipate API changes in this early state of development.

=head1 AUTHOR

Stefan Hornburg (Racke), C<racke@linuxia.de>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nitesi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nitesi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nitesi

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nitesi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nitesi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nitesi>

=item * Search CPAN

L<http://search.cpan.org/dist/Nitesi/>

=back


=head1 ACKNOWLEDGEMENTS

Marco Pessotto (patch fixing crash in logout)

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
