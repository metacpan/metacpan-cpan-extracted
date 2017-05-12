package Plack::Middleware::PyeLogger;

# ABSTRACT: Use Pye as a Plack logger

use parent qw/Plack::Middleware/;
use strict;
use warnings;

use Carp;
use Plack::Util::Accessor qw/logger backend opts/;
use Pye;

our $VERSION = "2.000001";
$VERSION = eval $VERSION;

=head1 NAME

Plack::Middleware::PyeLogger - Use Pye as a Plack logger

=head1 SYNOPSIS

	builder {
		enable 'PyeLogger', backend => 'MongoDB', opts => \%opts;
		$app;
	};

=head1 DESCRIPTION

This L<Plack> middleware sets L<Pye> as a logger for your Plack applications (C<psgix.logger>).
It differs from "normal" Plack loggers in that the C<psgix.logger> subroutine takes a hash-ref of
a different format:

=over

=item * B<message> - the text of the message (this is standard to all loggers)

=item * B<session_id> - the ID of the session (this is required for this logger)

=item * B<data> - an optional hash-ref of data to attach to the message

=back

Also, the C<level> key is ignored, as C<Pye> has no log levels.

=head1 METHODS

This module implements the following methods, as required by L<Plack::Middleware>/L<Plack::Component>.

=head2 prepare_app()

Generates an instance of L<Pye>.

=cut

sub prepare_app {
	my $self = shift;

	$self->backend('MongoDB')
		unless $self->backend;

	$self->opts({})
		unless $self->opts;

	$self->logger(Pye->new($self->backend, %{$self->opts}));
}

=head2 call( \%env )

Creates the C<psgix.logger> subroutine for your app.

=cut

sub call {
	my($self, $env) = @_;

	$env->{'psgix.logger'} = sub {
		my $args = shift;

		croak "You must provide the session_id to the logger"
			unless $args->{session_id};

		$args->{message} ||= '';

		$self->logger->log($args->{session_id}, $args->{message}, $args->{data});
	};

	$self->app->($env);
}

=head1 CONFIGURATION

You need to pass the C<Pye> backend to use (e.g. C<MongoDB> for L<Pye::MongoDB>, which is the
default for backwards compatibility reasons), and optionally a hash-ref of options. These can
be anything the respective backend constructor accepts. For example:

	builder {
		enable 'PyeLogger',
			backend => 'MongoDB',
			opts => { host => 'mongodb://logserver:27017', log_coll => 'logsssss!!!!!!' };
		$app;
	};

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Plack-Middleware-PyeLogger@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-PyeLogger>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Plack::Middleware::PyeLogger

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-PyeLogger>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Plack-Middleware-PyeLogger>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Plack-Middleware-PyeLogger>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Plack-Middleware-PyeLogger/>
 
=back

=head1 SEE ALSO

L<PSGI::Extensions>, L<Plack>, L<Plack>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Ido Perlmuter C<< ido@ido50.net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
__END__
