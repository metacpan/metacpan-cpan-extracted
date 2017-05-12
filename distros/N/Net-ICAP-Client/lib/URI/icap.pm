package URI::icap;

use strict;
use warnings;
use base qw(URI::http);

our $VERSION = 0.07;

sub default_port { return 1344 }

1;
__END__

=head1 NAME

URI::icap - URI scheme for ICAP Identifiers

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    use URI::icap;

    my $uri = URI->new('icap://icap-proxy.example.com/');

=head1 DESCRIPTION

This module implements the C<icap:> URI scheme defined in L<RFC 3507|http://tools.ietf.org/html/rfc3507>.  This module inherits the behaviour of L<URI::http|URI::http>, and over-rides the default_port method

=head1 SUBROUTINES/METHODS

=head2 default_port

The default port for icap servers is 1344

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 DIAGNOSTICS

See L<URI|URI>
 
=head1 CONFIGURATION AND ENVIRONMENT

See L<URI|URI>

=head1 DEPENDENCIES
 
URI::icap requires the following non-core modules
 
  URI::http

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-uri-icap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-icap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::icap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-icap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-icap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-icap>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-icap/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See L<http://dev.perl.org/licenses/> for more information.
