package Pod::POM::Web::PSGI;

use strict;
use warnings;

our $VERSION;
BEGIN {
    $VERSION = '0.002';
}

use CGI::Emulate::PSGI;
use Pod::POM::Web;

# The PSGI application, returned as the last value
# Pod::POM::Web is already designed as a persistent webapp, so that's easy
# (for the curious who wants an example of how to wrap a generic CGI application
#  see on BackPAN how Pod::POM::Web::PSGI 0.001 was implemented)
CGI::Emulate::PSGI->handler(sub {
    Pod::POM::Web->handler
})
__END__

=head1 NAME

Pod::POM::Web::PSGI - Run Pod::POM::Web as a PSGI application

=head1 SYNOPSIS

Run L<Pod::POM::Web> as a L<PSGI> application with L<plackup>:

    plackup -e 'require Pod::POM::Web::PSGI'

Load Pod::POM::Web as a PSGI application:

    my $app = require Pod::POM::Web::PSGI;

=head1 DESCRIPTION

This is a wrapper for L<Pod::POM::Web> to transform it as a L<PSGI> application.
This allow then to integrate Pod::POM::Web in a bigger web application, by
mounting it for example with L<Plack::Builder>.

=head1 SEE ALSO

=over 4

=item *

L<Pod::POM::Web>

=item *

L<PSGI>, L<Plack>, L<Plack::Builder>

=back

=head1 AUTHOR

Olivier MenguE<eacute>, C<dolmen@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2011 Olivier MenguE<eacute>.

This library is free software; you can distribute it and/or modify it
under the same terms as Perl 5 itself.

=cut
