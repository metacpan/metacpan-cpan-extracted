#!/usr/bin/env perl
use Mojo::Base -strict;

# Disable Bonjour, IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_IOWATCHER} = 'Mojo::IOWatcher';
}

# mod_fastcgi doesn't like small chunks
BEGIN { $ENV{MOJO_CHUNK_SIZE} = 131072 }

use Test::More;

use File::Spec;
use File::Temp;
use IO::Socket::INET;
use Mojo::IOLoop;
use Mojo::Template;
use Mojo::UserAgent;
use File::Slurp;

# Mac OS X only test
plan skip_all => 'Mac OS X required for this test!' unless $^O eq 'darwin';
plan skip_all => 'set TEST_APACHE to enable this test (developer only!)'
  unless $ENV{TEST_APACHE};
plan tests => 13;

# "Robots don't have any emotions, and sometimes that makes me very sad."
use_ok 'Mojo::Server::FastCGI';

# Setup
my $port   = Mojo::IOLoop->generate_port;
my $dir    = File::Temp::tempdir(CLEANUP => 1);
my $config = File::Spec->catfile($dir, 'fcgi.config');
my $mt     = Mojo::Template->new;

# FastCGI setup
my $fcgi = File::Spec->catfile($dir, 'test.fcgi');
write_file($fcgi, $mt->render(<<'EOF'));
% use Config;
#!<%= $Config{perlpath} %>

use strict;
use warnings;

% use FindBin;
use lib '<%= "$FindBin::Bin/../../lib" %>';

use Mojolicious::Lite;
use Mojo::Server::FastCGI;
use Mojolicious::Command::fastcgi;


get '/' => { text =>'Your Mojo is working!' };


post '/upload' => sub {
    my $self = shift;
    $self->render_data($self->req->upload('file')->slurp);
  };



post '/chunked' => sub {
  my $self = shift;

  my $params = $self->req->params->to_hash;
  my @chunks;
  for my $key (sort keys %$params) { push @chunks, $params->{$key} }

  my $cb;
  $cb = sub {
    my $self = shift;
    $cb = undef unless my $chunk = shift @chunks || '';
    $self->write_chunk($chunk, $cb);
  };
  $self->$cb();
};

get '/bug-0-in-body' => sub {
   my $self = shift;
   $self->render(text=>"0");
};


Mojo::Server::FastCGI->new->run;

1;
EOF



chmod 0777, $fcgi;
ok -x $fcgi, 'script is executable';

# Apache setup
write_file($config, $mt->render(<<'EOF', $dir, $port, $fcgi));
% my ($dir, $port, $fcgi) = @_;
% use File::Spec;
ServerName 127.0.0.1
Listen <%= $port %>
DocumentRoot  <%= $dir %>

LoadModule log_config_module libexec/apache2/mod_log_config.so

ErrorLog <%= File::Spec->catfile($dir, 'error.log') %>

LoadModule alias_module libexec/apache2/mod_alias.so
LoadModule fastcgi_module libexec/apache2/mod_fastcgi.so

PidFile <%= File::Spec->catfile($dir, 'httpd.pid') %>
LockFile <%= File::Spec->catfile($dir, 'accept.lock') %>

FastCgiIpcDir <%= $dir %>
FastCgiServer <%= $fcgi %> -processes 1
Alias / <%= $fcgi %>/
EOF

# Start
my $pid = open my $server, '-|', '/usr/sbin/httpd', '-X', '-f', $config;
sleep 1
  while !IO::Socket::INET->new(
  Proto    => 'tcp',
  PeerAddr => 'localhost',
  PeerPort => $port
  );

# Request
my $ua = Mojo::UserAgent->new;
my $tx = $ua->get("http://127.0.0.1:$port/");
is $tx->res->code, 200, 'right status';
is $tx->res->headers->content_length, 21, 'right "Content-Length" value';
is $tx->res->body, 'Your Mojo is working!', 'right content';

# HEAD request
$tx = $ua->head("http://127.0.0.1:$port/");
is $tx->res->code, 200, 'right status';
is $tx->res->headers->content_length, 21, 'right "Content-Length" value';
is $tx->res->body, '', 'no content';

# Form with chunked response
my $params = {};
for my $i (1 .. 10) { $params->{"test$i"} = $i }
my $result = '';
for my $key (sort keys %$params) { $result .= $params->{$key} }
my ($code, $body);
$tx = $ua->post_form("http://127.0.0.1:$port/chunked" => $params);
is $tx->res->code, 200, 'right status';
is $tx->res->body, $result, 'right content';

# Upload
($code, $body) = undef;
$tx = $ua->post_form(
  "http://127.0.0.1:$port/upload" => {file => {content => $result}});
is $tx->res->code, 200, 'right status';
is $tx->res->body, $result, 'right content';


# Bug test, returning "0" as body breaks the response.

$tx = $ua->get("http://127.0.0.1:$port/bug-0-in-body");
is $tx->res->body, "0", '0 returned in body';

# Stop
kill 'INT', $pid;
sleep 1
  while IO::Socket::INET->new(
  Proto    => 'tcp',
  PeerAddr => 'localhost',
  PeerPort => $port
  );
