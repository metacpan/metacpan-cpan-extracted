package Plack::App::Redirect;

use base qw(Plack::Component);
use strict;
use warnings;

use Plack::Response;
use Plack::Request;
use Plack::Util::Accessor qw(redirect_url);

our $VERSION = 0.02;

sub call {
	my ($self, $env) = @_;

	if (defined $self->redirect_url) {
		my $req = Plack::Request->new($env);
		my $res = Plack::Response->new;
		$res->redirect($self->redirect_url.$req->request_uri, 308);
		return $res->finalize;
	} else {
		return [
			404,
			[
				'content-type' => 'text/html; charset=utf-8',
			],
			['No redirect.'],
		];
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Redirect - Plack application for redirect.

=head1 SYNOPSIS

 use Plack::App::Redirect;

 my $obj = Plack::App::Redirect->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Redirect->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<redirect_url>

Redirect URL.

If this URL isn't present, application returns error.

=back

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of redirect application.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Plack::App::Redirect;
 use Plack::Runner;

 # Run application.
 my $app = Plack::App::Redirect->new(
         'redirect_url' => 'https://skim.cz',
 )->to_app;
 Plack::Runner->new->run($app);

 # Output (HEAD on redirected site):
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # HEAD http://localhost:5000/
 # 200 OK
 # Connection: close
 # Date: Wed, 16 Jun 2021 15:41:44 GMT
 # Server: nginx/1.17.6
 # Content-Length: 3543
 # Content-Type: text/html; charset=utf-8
 # Last-Modified: Tue, 15 Jun 2021 22:16:46 GMT
 # Client-Date: Wed, 16 Jun 2021 15:41:44 GMT
 # Client-Peer: 89.185.227.162:443
 # Client-Response-Num: 1
 # Client-SSL-Cert-Issuer: /C=US/O=Let's Encrypt/CN=R3
 # Client-SSL-Cert-Subject: /CN=skim.cz
 # Client-SSL-Cipher: TLS_AES_256_GCM_SHA384
 # Client-SSL-Socket-Class: IO::Socket::SSL
 # Strict-Transport-Security: max-age=31536000

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Plack::App::Redirect;
 use Plack::Runner;

 # Run application.
 my $app = Plack::App::Redirect->new->to_app;
 Plack::Runner->new->run($app);

 # Output (HEAD on error from app):
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # HEAD http://localhost:5000/
 # 404 Not Found
 # Date: Wed, 16 Jun 2021 15:40:40 GMT
 # Server: HTTP::Server::PSGI
 # Content-Length: 1
 # Content-Type: text/html; charset=utf-8
 # Client-Date: Wed, 16 Jun 2021 15:40:40 GMT
 # Client-Peer: 127.0.0.1:5000
 # Client-Response-Num: 1

=head1 DEPENDENCIES

L<Plack::Response>,
L<Plack::Request>,
L<Plack::Util::Accessor>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Redirect>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
