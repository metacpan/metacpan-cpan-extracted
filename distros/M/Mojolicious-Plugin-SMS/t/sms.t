#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Mojolicious;
use Mojolicious::Lite;

my $mojolicious_version = Mojolicious->VERSION;

app->log->level('error');

plugin SMS => {
	driver => 'Test',
};

get '/simplest' => sub {
	my $self = shift;
	my $rv = $self->sms('+380506022375', "Hello!");
	$self->render( json => { ok => $rv} )
};

get '/simple' => sub {
	my $self = shift;
	my $rv = $self->sms(
		to   => '+380506022375',
		text => "Hello!",
	);
	$self->render( json => { ok => $rv } );
};

use Test::More tests => 6;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/simplest')
  ->status_is(200)
  ->json_is('/ok' => 1)
;

$t->get_ok('/simple')
  ->status_is(200)
  ->json_is('/ok' => 1)
;
