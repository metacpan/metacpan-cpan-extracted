#!/usr/bin/env perl
use strict; use warnings FATAL => 'all';
use List::Objects::WithUtils 1.009;


my $nickname = 'litebot';
my $username = 'clientlite';
my $server   = 'irc.cobaltirc.org';
my $channels = array( '#eris', '#botsex' );


use POE;
use IRC::Toolkit;
use POEx::IRC::Client::Lite;


POE::Session->create(
  heap => hash(irc => undef)->inflate(rw => 1),
  package_states => [
    main => [ qw/
      _start
      cli_irc_public_msg
      cli_irc_ctcp_version
      cli_irc_001
    / ],
  ],
);
$poe_kernel->run;

sub _start {
  my ($kern, $heap) = @_[KERNEL, HEAP];
  $heap->irc( 
    POEx::IRC::Client::Lite->new(
      event_prefix => 'cli_',
      server   => $server,
      nick     => $nickname,
      username => $username,
      port     => 6697,
      ssl      => 1,
    )
  );
  $heap->irc->connect;
}

sub cli_irc_001 {
  my ($kern, $heap, $ev) = @_[KERNEL, HEAP, ARG0];
  my $irc = $heap->irc;

  ## Chainable methods:
  $irc->join( $channels->all )
    ->privmsg( $channels->join(',') => "hello there!" );
}

sub cli_irc_public_msg {
  my ($kern, $heap, $ev) = @_[KERNEL, HEAP, ARG0];
  my ($target, $string)  = @{ $ev->params };

  if (lc($string || '') eq 'hello') {
    $heap->irc->privmsg($target, "hello, world!");
  }
}

sub cli_irc_ctcp_version {
  my ($kern, $heap, $ev) = @_[KERNEL, HEAP, ARG0];
  my $from = parse_user( $ev->prefix );

  $heap->irc->notice( $from,
    ctcp_quote("VERSION a silly POEx::IRC::Client::Lite example"),
  );
}

