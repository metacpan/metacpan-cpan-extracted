use 5.010;
use strict;
use warnings;

package Plack::Middleware::SignedCookies;
$Plack::Middleware::SignedCookies::VERSION = '1.103';
# ABSTRACT: accept only server-minted cookies

use parent 'Plack::Middleware';

use Plack::Util ();
use Plack::Util::Accessor qw( secret secure httponly );
use Digest::SHA ();

sub _hmac { y{+/}{-~}, return $_ for Digest::SHA::hmac_sha256_base64( @_[0,1] ) }

my $length = length _hmac 'something', 'something';

sub call {
	my $self = shift;
	my $env  = shift;

	my $secure   = $self->secure   // do { $self->secure  ( 0 ) };
	my $httponly = $self->httponly // do { $self->httponly( 1 ) };
	my $secret   = $self->secret
		// do { $self->secret( join '', map { chr int rand 256 } 1..17 ) };

	my $cookie =
		join '; ',
		grep { s/(.{$length})\z//o and $1 eq _hmac $_, $secret }
		split /\s*[;,]\s*/,
		$env->{'HTTP_COOKIE'} // '';

	length $cookie
		? local $env->{'HTTP_COOKIE'} = $cookie
		: delete local $env->{'HTTP_COOKIE'};

	return Plack::Util::response_cb( $self->app->( $env ), sub {
		my ( $i, $headers ) = ( 0, $_[0][1] );
		while ( $i < $#$headers ) {
			++$i, next if 'set-cookie' ne lc $headers->[$i++];
			for ( $headers->[$i++] ) {
				s!\A\s*([^;]+?)\K\s*(?=;|\z)!_hmac $1, $secret!e;
				$_ .= '; secure'   if $secure   and not /;\s* secure   \s* (?:;|\z)/ix;
				$_ .= '; HTTPonly' if $httponly and not /;\s* httponly \s* (?:;|\z)/ix;
			}
		}
	} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::SignedCookies - accept only server-minted cookies

=head1 VERSION

version 1.103

=head1 SYNOPSIS

 # in app.psgi
 use Plack::Builder;
 
 builder {
     enable 'SignedCookies', secret => 's333333333kr1t!!!!1!!';
     $app;
 };

=head1 DESCRIPTION

This middleware modifies C<Cookie> headers in the request and C<Set-Cookie> headers in the response.
It appends a HMAC digest to outgoing cookies and removes and verifies it from incoming cookies.
It rejects incoming cookies that were sent without a valid digest.

=head1 CONFIGURATION OPTIONS

=over 4

=item C<secret>

The secret to pass to the L<Digest::SHA> HMAC function.

If not provided, a random secret will be generated using PerlE<rsquo>s built-in L<rand> function.

=item C<secure>

Whether to force the I<secure> flag to be set on all cookies,
which instructs the browser to only send them when using an encrypted connection.

Defaults to false. B<You should strongly consider overriding this default with a true value.>

=item C<httponly>

Whether to force the I<HttpOnly> flag to be set on all cookies,
which instructs the browser to not make them available to Javascript on the page.

B<Defaults to true.> Provide a defined false value if you wish to override this.

=back

=head1 SEE ALSO

=over 4

=item *

L<RFCE<nbsp>6265, I<HTTP State Management Mechanism>, section 4.1.2.5., I<The Secure Attribute>|http://tools.ietf.org/html/rfc6265#section-4.1.2.5>

=item *

L<MSDN, I<Mitigating Cross-site Scripting With HTTP-only Cookies>|http://msdn.microsoft.com/en-us/library/ms533046.aspx>

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
