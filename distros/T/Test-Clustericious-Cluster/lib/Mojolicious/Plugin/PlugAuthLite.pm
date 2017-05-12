package Mojolicious::Plugin::PlugAuthLite;

use Mojo::Base qw( Mojolicious::Plugin );
use Mojo::ByteStream qw( b );
use 5.010001;

# ABSTRACT: Add a minimal PlugAuth server to your Mojolicious application.
our $VERSION = '0.35'; # VERSION


sub register
{
  my($self, $app, $conf) = @_;
  
  my $cb_auth  = $conf->{auth}  // sub { 0 };
  my $cb_authz = $conf->{authz} // sub { 1 };
  my $cb_host  = $conf->{host}  // sub { 0 };
  my $realm = $conf->{realm} // 'PlugAuthLite';
  my $base_url = $conf->{url} // $conf->{uri} // '';

  $app->routes->get("$base_url/auth" => sub {
    my $self = shift;
    eval {
      my $auth_header = $self->req->headers->authorization;
      unless($auth_header)
      {
        $self->res->headers->www_authenticate("Basic \"$realm\"");
        $self->render(text => 'please authenticate', status => 401);
        return;
      }
      my ($method,$str) = split / /,$auth_header;
      my ($user,$pw) = split /:/, b($str)->b64_decode;
      if($cb_auth->($user, $pw))
      {
        $self->render(text => 'ok', status => 200);
      }
      else
      {
        $self->render(text => 'not ok', status => 403);
      }
    };
    $self->render(text => 'not ok', status => 503) if $@;
  })->name('plugauth_auth');
  
  $app->routes->get("$base_url/authz/user/#user/#action/(*resource)" => { resource => '/' } => sub {
    my $self = shift;
    eval {
      my($user, $resource, $action) = map { $self->stash($_) } qw( user resource action );
      $resource =~ s{^/?}{/};
      if($cb_authz->($user, $action, $resource))
      {
        $self->render(text => 'ok', status => 200);
      }
      else
      {
        $self->render(text => 'not ok', status => 403);
      }
    };
    $self->render(text => 'not ok', status => 503) if $@;
  })->name('plugauth_authz');
  
  $app->routes->get("$base_url/host/#host/:tag" => sub {
    my $self = shift;
    eval {
      my ($host,$tag) = map $self->stash($_), qw/host tag/;
      if ($cb_host->($host,$tag)) {
        return $self->render(text => 'ok', status => 200);
      }
      return $self->render(text => 'not ok', status => 403);
    };
    $self->render(text => 'not ok', status => 503) if $@;
  })->name('plugauth_host');
  
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::PlugAuthLite - Add a minimal PlugAuth server to your Mojolicious application.

=head1 VERSION

version 0.35

=head1 SYNOPSIS

 use Mojolicious::Lite
 
 plugin 'plug_auth_lite', 
   auth => sub {
     my($user, $pass) = @_;
     if($user eq 'optimus' && $pass eq 'matrix')
     { return 1; }
     else
     { return 0; }
   },
   authz => sub {
     my($user, $action, $resource) = @_;
     if($user eq 'optimus && $action eq 'open' && $resource =~ m{^/matrix})
     { return 1 }
     else
     { return 0 }
   };

=head1 DESCRIPTION

This plugin provides a very minimal but customizable L<PlugAuth> server which can
be included with your L<Mojolicious> application for L<Clustericious> applications
to authenticate against.  If you do not need specialized plugins for LDAP or DBI,
and if you do not need the user/group/resource management provided by a the full
featured L<PlugAuth> server then this plugin may be for you.

The script L<plugauthlite> included with this distribution provides PlugAuth
style authentication (but not authorization) using a simple Apache style password
file.

=head1 CONFIGURATION

=head2 auth

Subroutine which checks the authentication of a user.  It is passed two arguments,
the username and the password.  If they are authentic this call back should return
1.  Otherwise it should return 0.

=head2 authz

Subroutine which checks the authorization of a user.  It is passwd three arguments,
the username, action (usually a verb) and resource (usually the path part of a URL).
If the user is authorized for the action on that resource the call back should return
1.  Otherwise it should return 0.

=head2 url

The prefix to prepend to the standard PlugAuth API routes.  Usually the authentication
route is /auth and the authorization route is /authz, but if the PlugAuth.conf client
configuration is set to http://example.com/foo the client expects the authentication
route to be /foo/auth and the authorization route to be /foo/authz.  In this case you
would set this configuration item to '/foo'.

=head2 realm

The realm to use for HTTP Basic authentication.  The default is PlugAuthLite.

=head1 ROUTES

=head2 GET /auth

=over 4

=item * if username and password provided using BASIC authentication and are correct

Return 200 ok

=item * if username and password provided using BASIC authentication but are not correct

Return 403 not ok

=item * if username and password are not provided using BASIC authentication

Return 401 please authenticate

=back

=head2 GET /authz/user/#user/#action/(*resource)

=over 4

=item * if the given user (#user) is permitted to perform the given action (#action) on the given resource (*resource)

Return 200 ok

=item * otherwise

return 403 not ok

=back

=head1 METHODS

=head2 register

This method adds the routes to your application required to implement the PlugAuth
API.

=head1 LIMITATIONS

This implementation of the PlugAuth protocol does not support these features provided
by the full fledged L<PlugAuth> server:

=over 4

=item *

Groups

=item *

Management API for creating/removing/modifying users/groups/resources

=item *

Standard Clustericious routes like "/version" and "/status"

=item *

Clustericious configuration file (~/etc/PlugAuth.conf)

=item *

Support for L<PlugAuth> plugins (L<PlugAuth::Plugin>).

=item *

Probably many others.

=back

=head1 SEE ALSO

L<plugauthlite>,
L<PlugAuth::Lite>,
L<PlugAuth>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
