package PlugAuth::Client::Tiny::Apache2AuthenHandler;

use strict;
use warnings;
use 5.012;
use PlugAuth::Client::Tiny;
use Apache2::RequestRec  ();
use Apache2::Access      ();
use Apache2::RequestUtil ();
use Apache2::Const       -compile => qw( OK HTTP_UNAUTHORIZED );

# ABSTRACT: Apache authentication handler for PlugAuth
our $VERSION = '0.04'; # VERSION


sub handler
{
  my($r) = @_;

  my($status, $password) = $r->get_basic_auth_pw;
  return $status unless $status == Apache2::Const::OK;

  my $auth = PlugAuth::Client::Tiny->new(url => $ENV{PLUGAUTH_URL});

  if($auth->auth($r->user, $password))
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

PlugAuth::Client::Tiny::Apache2AuthenHandler - Apache authentication handler for PlugAuth

=head1 VERSION

version 0.04

=head1 SYNOPSIS

In your httpd.conf:

 <Location /protected>
   PerlAuthenHandler PlugAuth::Client::Tiny::Apache2AuthenHandler
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

=head1 SEE ALSO

=over 4

=item L<PlugAuth::Client::Tiny::Apache2AuthzHandler>

For authorization.

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
