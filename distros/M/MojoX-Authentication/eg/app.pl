#!/usr/bin/env perl
use v5.24;
use warnings;
use English qw< -no_match_vars >;
use experimental qw< signatures >;

use FindBin '$RealBin';
use lib
   "$RealBin/../lib",
   "$RealBin/local/lib/perl5";
use Mojolicious::Lite;
use MojoX::Authentication;

# This example runs with the Mojolicious default secret, so anyone can
# forge its session cookies. A real application must set its own, e.g.:
#   app->secrets([ $ENV{MOJO_SECRET} // die "set MOJO_SECRET\n" ]);
# Likewise, server.key is public: generate your own SP key.

my $mauth = MojoX::Authentication->new(
   provider_name => 'my-saml2',
   model => {
      config => {},
      providers => [
         {
            name  => 'my-hash',
            class => 'MojoX::Authentication::Model::Hash',
            args => {
               secrets_are_cleartext => 1,
               db => {
                  foo => {
                     secret => 123,
                     fullname => 'Foo de Foiegras',
                     groups => [qw< this that >],
                  },
                  bar => { secret => 456 },
               }
            }
         },
         {
            name  => 'my-db',
            class => 'MojoX::Authentication::Model::Db',
            args => {
               wmdb => {
                  db_url => 'sqlite:testdb.sqlite',
               },
               key_for_secret => 'userpass',   # column with the hash
               remaps => [
                  sub ($r, $backwards) {
                     if ($backwards) {
                        $r->{groups} = join ' ', $r->{groups}->@*;
                     }
                     else {
                        $r->{groups} = [ split m{\s+}mxs, $r->{groups} ];
                     }
                  },
               ],
            }
         },
         {
            name  => 'my-saml2',
            class => 'MojoX::Authentication::Model::SAML2',
            args => {
               idp => './idp.xml',
               sp_configuration => {
                  identifier => 'https://srv.example.com/sp',
                  key => 'server.key',
                  'sso-post-url-override' => 'http://127.0.0.1:3000/public/saml2',
               },
               remaps => [
                  sub ($r, $backwards) {
                     for my $feat (qw< id email firstName lastName >) {
                        $r->{$feat} = $r->{$feat}[0];
                     }
                     $r->{fullname}
                        = join ' ', $r->@{qw< firstName lastName >};
                  },
               ],
            }
         },
      ]
   },
   -startup => app(),
);

get '/public' => sub ($c) {
   return $c->render(template => 'public');
} => 'public';

get '/public/login' => sub ($c) {
   $mauth->ctr_saml2_login($c, { not_ok => 'public' });
} => 'saml2_redirect';

post '/public/saml2' => sub ($c) {
   $mauth->ctr_saml2_sso_post($c, {qw< ok protected not_ok public >});
} => 'saml2_login';

post '/public/login' => sub ($c) {
   $mauth->ctr_credentials_login($c, {qw< ok protected not_ok public >});
} => 'login';

post '/public/logout' => sub ($c) {
   $mauth->ctr_logout($c, 'protected');
} => 'logout';

under '/' => sub ($c) {
   if ($c->is_user_authenticated) {
      return 1;
   }
   $c->log->info('NOT authenticated, deal with it');
   $c->redirect_to('public');
   return 0;
};

get '/' => sub ($c) { return $c->redirect_to('protected') };

get '/protected' => sub ($c) {
   return $c->render(template => 'protected');
} => 'protected';

app->log->info('started');
app->start;

__DATA__
@@ public.html.ep
<html>
   <head><title>public</title></head>
   <body>
      <h1>public</h1>
      <p><a href="/">home</a> - <a href="/public">public</a> - <a href="/protected">protected</a></p>
% if (defined($user)) {
      <p>Welcome, <strong><%= $user->{data}{fullname} // $user->{uid} %></strong></p>
      <form method="POST" action="/public/logout">
         %= csrf_field
         <input type="submit" value="logout">
      </form>
% } else {
      <p><a href="/public/login">Login (SAML2)</a></p>
      <form method="POST" action="/public/login">
         %= csrf_field
         <input type="text" name="username" placeholder="username" />
         <input type="password" name="password" placeholder="password" />
         <input type="submit" value="login" />
      </form>
% }
   </body>
</html>

@@ protected.html.ep
<html>
   <head><title>protected</title></head>
   <body>
      <h1>protected</h1>
      <p><a href="/">home</a> - <a href="/public">public</a> - <a href="/protected">protected</a></p>
% if (defined($user)) {
      <p>Welcome, <strong><%= $user->{data}{fullname} // $user->{uid} %></strong></p>
      <form method="POST" action="/public/logout">
         %= csrf_field
         <input type="submit" value="logout">
      </form>
% }
   </body>
</html>

