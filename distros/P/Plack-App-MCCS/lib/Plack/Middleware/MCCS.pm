package Plack::Middleware::MCCS;

use parent qw/Plack::Middleware/;
use warnings;
use strict;

use Plack::App::MCCS;
use Plack::Util::Accessor qw/path root defaults types encoding min_cache_dir/;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

Plack::Middleware::MCCS - Middleware for serving static files with Plack::App::MCCS

=head1 EXTENDS

L<Plack::Middleware>

=head1 SYNOPSIS

	# in your app.psgi:
	use Plack::Builder;

	builder {
		enable 'Plack::Middleware::MCCS',
			path => qr{^/static/},
			root => '/path/to/static_files';
		$app;
	};

=head1 DESCRIPTION

This package allows serving static files with L<Plack::App::MCCS> in the form of a
middleware. It allows for more flexibility with regards to which paths are to be
served by C<MCCS>, as the app can only be C<mount>ed onto a certain path prefix.
The middleware, however, can serve requests that match a certain regular expression.

=head1 CONFIGURATIONS

The only required configuration option is B<path>. You should either provide a regular
expression, or a subroutine to match against requests. For more info about the C<path>
option, look at L<Plack::Middleware::Static>, it's exactly the same.

Other configuration options are those supported by L<Plack::App::MCCS>. None are required,
but you will mostly provide the C<root> option. If you do not provide it, the current
working directory is assumed. These are the supported options:

=over

=item * root

=item * defaults

=item * types

=item * encoding

=item * min_cache_dir

=back

Refer to L<Plack::App::MCCS> for a complete explanation of them.

=head1 METHODS

=head2 call( \%env )

Attempts to handle a request by using Plack::App::MCCS.

=cut

sub call {
	my ($self, $env) = @_;

	my $res = $self->_handle_static($env);

	return $res
		if $res && $res->[0] != 404;

	return $self->app->($env);
}

sub _handle_static {
	my($self, $env) = @_;

	return
		unless $self->path;

	my $path = $env->{PATH_INFO};

	for ($path) {
		my $matched = ref $self->path eq 'CODE' ? $self->path->($_, $env) : $_ =~ $self->path;
		return unless $matched;
	}

	my %opts = (root => $self->root || '.');
	foreach (qw/defaults types encoding min_cache_dir/) {
		$opts{$_} = $self->$_
			if defined $self->$_;
	}

	$self->{mccs} ||= Plack::App::MCCS->new(%opts);

	local $env->{PATH_INFO} = $path; # rewrite PATH

	return $self->{mccs}->call($env);
}

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Plack-App-MCCS@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-App-MCCS>.

=head1 SEE ALSO

L<Plack::App::MCCS>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

=head1 ACKNOWLEDGMENTS

This module is just an adapation of L<Plack::Middleware::Static> by Tatsuhiko Miyagawa
to use L<Plack::App::MCCS> instead.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2016, Ido Perlmuter C<< ido@ido50.net >>.

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

1;
