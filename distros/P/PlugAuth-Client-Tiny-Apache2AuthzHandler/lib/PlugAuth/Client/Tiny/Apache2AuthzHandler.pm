package PlugAuth::Client::Tiny::Apache2AuthzHandler;

use strict;
use warnings;
use 5.012;
use PlugAuth::Client::Tiny;
use Apache2::Access      ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Const -compile => qw(OK HTTP_UNAUTHORIZED);

# ABSTRACT: Apache authorization handler for PlugAuth
our $VERSION = '0.02'; # VERSION


sub handler
{
  my($r) = @_;
  
  my $auth   = PlugAuth::Client::Tiny->new(url => $ENV{PLUGAUTH_URL});
  my $prefix = $ENV{PLUGAUTH_PREFIX} // '';
  
  my $user = $r->user;
  if($user && $auth->authz($user, $r->method, $prefix . $r->uri))
  {
    return Apache2::Const::OK;
  }
  else
  {
    $r->note_basic_auth_failure;
    return Apache2::Const::HTTP_UNAUTHORIZED;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Client::Tiny::Apache2AuthzHandler - Apache authorization handler for PlugAuth

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In your httpd.conf:

 <Location /protected>
   PerlAuthenHandler PlugAuth::Client::Tiny::Apache2AuthenHandler
   PerlAuthzHandler  PlugAuth::Client::Tiny::Apache2AuthzHandler
   AuthType Basic
   AuthName "My Protected Documents"
   Require valid-user
   PerlSetEnv PLUGAUTH_URL http://localhost:3001
 </Location>

=head1 DESCRIPTION

This module provides PlugAuth authentication (via L<PlugAuth::Tiny>) for your legacy Apache2
application.

=head1 ENVIRONMENT

=head2 PLUGAUTH_URL

 PerlSetEnv PLUGAUTH_URL http://localhost:3001

Specifies the URL for the PlugAuth server to authenticate against.

=head2 PLUGAUTH_PREFIX

 PerlSetEnv PLUGAUTH_PREFIX /myprefix

Specifies a prefix for resource authorization requests.  What that means is that
if you set C<PLUGAUTH_PREFIX> to C</myprefix> as above, then when a client requests
a path such as C</myrequestpath> the authentication request to L<PlugAuth> will be
for the resource C</myprefix/myrequestpath>.

=head1 SEE ALSO

=over 4

=item L<PlugAuth::Client::Tiny::Apache2AuthenHandler>

For authentication.

=item L<PlugAuth>

Server to authenticate against.

=item L<PlugAuth::Client::Tiny>

Simplified PlugAuth client.

=item L<Alien::Apache24|https://github.com/plicease/Alien-Apache24>

For testing

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
