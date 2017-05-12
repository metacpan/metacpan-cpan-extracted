#!/usr/bin/env perl

use strict; use warnings;
use List::Objects::WithUtils;

my $nickname = 'litebot';
my $username = 'clientlite',
my $server   = 'irc.cobaltirc.org',
my $channels = array( '#eris', '#botsex' );

package My::Bot;
use Moo;
with 'MooX::POE';

use IRC::Toolkit;
use POEx::IRC::Client::Lite;

has irc => ( is => 'rw' );

sub START {
  my ($self) = @_;
  my $irc = POEx::IRC::Client::Lite->new(
    event_prefix => '',
    server       => $server,
    nick         => $nickname,
    username     => $username,
    port         => 6667,
    ssl          => 0,
  );
  $self->irc( $irc );
  $irc->connect;
}

sub on_irc_001 {
  my ($self) = @_;
  say "Connected";  
  $self->irc->join( $channels->all )
    ->privmsg( $channels->join(',') => 'hello there!' );
}

package main;
my $bot = My::Bot->new;
POE::Kernel->run;

