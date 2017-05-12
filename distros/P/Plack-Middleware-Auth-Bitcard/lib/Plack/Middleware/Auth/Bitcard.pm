package Plack::Middleware::Auth::Bitcard;

use 5.008;
use strict;
use warnings;

BEGIN {
	$Plack::Middleware::Auth::Bitcard::AUTHORITY = 'cpan:TOBYINK';
	$Plack::Middleware::Auth::Bitcard::VERSION   = '0.002';
}

use Carp;
use JSON qw(to_json from_json);
use Plack::Response;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw( bitcard skip_if on_unauth );
use Digest::SHA qw(sha1_hex);

use base "Plack::Middleware";

sub prepare_app
{
	my $self = shift;
	croak "Need to provide Authen::Bitcard object" unless ref $self->bitcard;
	$self->bitcard->info_required('username');
}

sub call
{
	my $self = shift;
	my $env  = $_[0];
	my $req  = "Plack::Request"->new($env);
	
	$env->{BITCARD_URL} = sub
	{
		unshift @_, 'login_url' if ref $_[0];
		my $method = shift;
		my $env    = shift || croak("needs \$env!");
		my $return = shift || $self->_boomerang_uri("Plack::Request"->new($env));
		$self->bitcard->$method(r => $return);
	};

	if ($self->_req_is_boomerang($req))
	{
		my $res = $self->_store_cookie_data($req);
		return $res->finalize;
	}
	elsif ($self->_fetch_cookie_data($req => $env))
	{
		return $self->app->($env);
	}
	elsif ($self->skip_if and $self->skip_if->($env))
	{
		return $self->app->($env);
	}
	elsif (my $on_unauth = $self->on_unauth)
	{
		return $on_unauth->($env);
	}
	else
	{
		my $res = $self->_start_boomerang($req);
		return $res->finalize;
	}
}

sub _boomerang_uri
{
	my $self = shift;
	my $req  = $_[0];
	
	my $base = $req->base;
	$base =~ m{/$} ? "${base}_bitcard_boomerang" : "${base}/_bitcard_boomerang";
}

sub _start_boomerang
{
	my $self = shift;
	my $req  = $_[0];
	
	my $res = "Plack::Response"->new;
	$res->cookies->{bitcard_return_to} = $req->uri;
	$res->redirect(
		$self->bitcard->login_url(
			r => $self->_boomerang_uri($req),
		),
	);
	return $res;
}

sub _req_is_boomerang
{
	my $self = shift;
	my $req  = $_[0];
	
	my ($uri) = split /\?/, $req->uri;  # ignore query string
	return ($uri eq $self->_boomerang_uri($req));
}

sub _store_cookie_data
{
	my $self = shift;
	my $req  = $_[0];
	
	my $res = "Plack::Response"->new;
	$res->redirect(
		defined $req->cookies->{bitcard_return_to} && $req->cookies->{bitcard_return_to} ne '-'
		? $req->cookies->{bitcard_return_to}
		: $req->base
	);
	if (my $user = $self->bitcard->verify($req))
	{
		$user->{_checksum} = sha1_hex($self->bitcard->api_secret . $user->{username});
		$res->cookies->{bitcard} = to_json($user);
	}
	else
	{
		$res->cookies->{bitcard} = to_json({});
	}
	$req->cookies->{bitcard_return_to} = { value => "-" };
	return $res;
}

sub _fetch_cookie_data
{
	my $self = shift;
	my ($req, $env) = @_;
	
	return unless $req->cookies->{bitcard};
	my $user = from_json($req->cookies->{bitcard});
	
	return unless $user->{username};
	return unless sha1_hex($self->bitcard->api_secret . $user->{username}) eq $user->{_checksum};
	
	$env->{BITCARD} = +{%$user};
	delete $env->{BITCARD}{_checksum};
	return $env->{BITCARD}{username};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Middleware::Auth::Bitcard - Bitcard authentication for Plack, which I suppose is what you might have guessed from the name

=head1 SYNOPSIS

   use strict;
   use warnings;
   
   use Authen::Bitcard;
   use Plack::Builder;
   
   my $app = sub {
      my $env = shift;
      my $username = $env->{BITCARD}{username};
      ...;
   };
   
   my $bc = "Authen::Bitcard"->new;
   $bc->token("12345678");
   $bc->api_secret("1234567890ABCDEF");
   
   builder {
      enable "Auth::Bitcard", bitcard => $bc;
      $app;
   };

=head1 DESCRIPTION

This module provides Plack middleware for Bitcard authentication.

B<< What is Bitcard? >> It's a trusted third-party authentication system.
Like OpenID but centralised, somewhat outdated, and pretty obscure.

B<< So why use it? >> You probably shouldn't. An exception would be if you
need login functionality for a website that is aimed at Perl developers.
This is because Bitcard is already used as login for C<< rt.cpan.org >> and
C<< cpanratings.perl.org >>, so many Perl developers already have a login
set up.

=head2 Simple usage

The example in the SYNOPSIS section shows how easy it is to add Bitcard
authentication to an existing PSGI app.

You'll need a Bitcard token and API secret for your website - to get these,
sign into L<http://www.bitcard.org/>, go to your account settings, click on
"My Sites", then add a new site. You will need to tell it your site's name,
and a URL. This URL should be the "base" URL for your PSGI app with
C<< /_bitcard_boomerang >> added to the end. For example, if you are serving
C<< http://bugs.example.com/ >> using Plack, then the URL you want is
C<< http://bugs.example.com/_bitcard_boomerang >>. Once you've entered that
information, the bitcard.org site will issue you with a token and API secret.

With this simple setup, B<all> requests to your site will be protected by
Bitcard authentication. When somebody first hits your site, they'll be
instantly redirected to bitcard.org to login.

Once they've logged in, their Bitcard details, including their username will
be in C<< $env->{BITCARD} >>.

=head2 No login necessary

You may want to specify that certain parts of your site do not require a
login; or perhaps visitors from certain IP addresses do not need to login;
or whatever.

This module accepts a coderef which can check these sorts of criteria:

   builder {
      enable "Auth::Bitcard",
         bitcard => $bc,
         skip_if => sub { my $env = shift; ... };
      $app;
   };

If the coderef returns true, then Bitcard authentication will be skipped for
the given request.

=head2 Showing different views of the site

Perhaps you don't B<always> need people to login to your site. Maybe you
are happy for them to browse a public version of your site, and they only
need to login if they want to access the super-awesome features.

In this case, you can provide an C<on_unauth> action:

   builder {
      enable "Auth::Bitcard",
         bitcard   => $bc,
         on_unauth => sub { my $env = shift; ... };
      $app;
   };

C<on_unauth> is a PSGI app in its own right, and is expected to return a
PSGI-style arrayref.

=head2 Displaying login/logout links

You can obtain login/logout URLs using the following:

   my $login_url    = $env->{BITCARD_URL}->(login_url => $env);
   my $logout_url   = $env->{BITCARD_URL}->(logout_url => $env);

There are also URLs for the user's account settings page, and to register
for a new bitcard account.

   my $account_url  = $env->{BITCARD_URL}->(account_url => $env);
   my $register_url = $env->{BITCARD_URL}->(register_url => $env);

When logged in people return to your site, they will arrive back at your
site's base URL. If you wish to send them elsewhere, set a cookie containing
the full URL you wish them to return to:

   my $res = "Plack::Response"->new;
   $res->cookies->{bitcard_return_to} = "http://example.com/goodbye";
   $res->redirect($env->{BITCARD_URL}->(logout_url => $env));
   return $res->finalize;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Plack-Middleware-Auth-Bitcard>.

=head1 SEE ALSO

L<Authen::Bitcard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

