#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Mojolicious::Plugin::Auth;


#
# HTTP Header
#
# Apache:
# X-Forwarded-For -> $IP/$NAME

use strict;
use warnings;

use base qw(Mojolicious::Plugin);
use Digest::SHA qw(sha1_hex);
use MIME::Base64;

sub register {
   my ($plugin, $app) = @_;

   $app->routes->add_condition(authenticated => sub {
      my ($r, $mojo) = @_;
      if(! $mojo->is_auth) {
         return $mojo->auth;
      }

      return 1;
   });

   $app->helper(is_auth => sub {
      my ($mojo) = @_;
      my ($auth_type, $auth_header) = split(/ /, $mojo->req->headers->authorization || "");

      return $mojo->auth unless $auth_type;

      if($auth_type && lc($auth_type) ne "basic") {
         return $mojo->auth;
      }

      my ($user, $pass) = split(/:/, decode_base64($auth_header));

      if($mojo->auth($user, $pass)) {
         return 1;
      }
      return 0;
   });

   $app->helper(auth => sub {
      my ($mojo, $user, $pass) = @_;
      if($user && $pass) {
         # do the auth
         my $file = $mojo->stash('config')->{user_file};

         my ($f_user, $f_pw) = split( /:/, [ grep { /^$user:/ } eval { local(@ARGV) = ($file); <>; } ]->[0] || "" ); 

         if($f_user) {
            chomp $f_pw;

            $pass = sha1_hex($pass);
            if($user eq $f_user && $pass eq $f_pw) {
               return 1;
            }
         }
      }

      $mojo->res->headers->www_authenticate("Basic realm=\"Rex::Endpoint::HTTP\"");
      $mojo->res->code(401);
      $mojo->rendered;

      return;
   });

   $app->plugins->on(before_dispatch => sub {
      my ($self, $mojo) = @_;
      return $self->is_auth;
   });
}

1;
