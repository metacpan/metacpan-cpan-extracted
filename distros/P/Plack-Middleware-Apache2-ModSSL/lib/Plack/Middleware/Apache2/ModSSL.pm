package Plack::Middleware::Apache2::ModSSL;

use 5.010;
use strict;

use base qw(Plack::Middleware);
use Apache2::ModSSL;
use Plack::Util::Accessor qw(vars client_exts server_exts);

BEGIN {
	$Plack::Middleware::Apache2::ModSSL::AUTHORITY = 'cpan:TOBYINK';
	$Plack::Middleware::Apache2::ModSSL::VERSION   = '0.002';
}

sub call
{
	my ($self, $env) = @_;
	my $c = $env->{'psgi.input'}->connection;
	
	$env->{$_} //= $c->ssl_var_lookup($_)
		for @{ $self->vars // [] };
	
	$env->{"SERVER:$_"} //= $c->ssl_ext_lookup(0, $_)
		for @{ $self->server_exts // [] };
	
	$env->{"CLIENT:$_"} //= $c->ssl_ext_lookup(1, $_)
		for @{ $self->client_exts // [] };
	
	$self->app->($env);
}

__PACKAGE__
__END__

=head1 NAME

Plack::Middleware::Apache2::ModSSL - pull in $env data from mod_ssl API

=head1 SYNOPSIS

 builder
 {
   enable "Apache2::ModSSL",
          vars => [qw(SSL_CLIENT_CERT)];
   $app;
 };

=head1 DESCRIPTION

Apache mod_ssl provides a bunch of data about the SSL connection. While
much of this is often exposed in environment variables, sometimes server
configuration (especially the I<SSLOptions> configuration directive)
will result in some of the data not being available to your application.
This module pokes into the mod_ssl API to retrieve the data you need and
stash it away in Plack's C<< $env >>.

You may be able to tweak your Apache configuration and persuade it to
give you the data you want via environment variables, in which case
Plack's Apache2 handler will automatically copy them into C<< $env >>
and you don't need this module.

=head2 C<vars>

Specifies an arrayref listing SSL-related variables to add to C<< $env >>.

=head2 C<server_exts>

An arrayref of OIDs which will be exported from the server's certificate.
It's incredibly unlikely you need this.

=head2 C<client_exts>

An arrayref of OIDs which will be exported from the client's certificate.
It's pretty unlikely you need this.

=begin private

=item call

=end private

=head1 BUGS

Plack::Middleware::Apache2::ModSSL uses L<Apache2::ModSSL> which is an
XS module (and a bit of a pain to build at that). The latter has an
oddity in how it loads up the XS part of the module. To counteract the
oddity, I've found it necessary to add this to my PSGI, near the top:

 BEGIN { $ENV{MOD_PERL} ||= 'mod_perl' };

If you get error messages about the C<ssl_var_lookup> method not being
defined in package Apache2::Connection, then try the above.

Please report any other bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Plack-Middleware-Apache2-ModSSL>.

=head1 SEE ALSO

L<Plack>,
L<Apache2::ModSSL>.

L<http://httpd.apache.org/docs/2.0/mod/mod_ssl.html>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
