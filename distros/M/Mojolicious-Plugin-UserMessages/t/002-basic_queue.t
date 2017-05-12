#!/usr/bin/env perl
use lib qw(t lib ../lib ../mojo/lib ../../mojo/lib);
use utf8;

use Mojo::Base -base;

# Disable Bonjour, IPv6
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
}

use Test::More;

use Mojolicious::Lite;

use Test::Mojo;

# UserMessages plugin
plugin 'UserMessages';

get '/'    => 'index';
get '/add' => sub {
   my $self = shift;
   $self->user_messages->add( 'DEFAULT' => $self->param('message') );
   $self->redirect_to('/');
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)
  ->content_is("<messages>\n</messages>\n");
$t->get_ok('/add?message=test')->status_is(302);
$t->get_ok('/')->status_is(200)
  ->content_is("<messages>\n<message type='DEFAULT'>test</message>\n</messages>\n");
$t->get_ok('/add?message=test')->status_is(302);
$t->get_ok('/add?message=test2')->status_is(302);
$t->get_ok('/')->status_is(200)
  ->content_is("<messages>\n<message type='DEFAULT'>test</message>\n<message type='DEFAULT'>test2</message>\n</messages>\n");

done_testing;

__DATA__
@@ index.html.ep
<messages>
% if ( user_messages->has_messages ) {
%  for my $message ( user_messages->get ) {
<message type='<%= $message->type %>'><%= $message->message %></message>
%  }
% }
</messages>
