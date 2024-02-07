#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::More tests => 5;
use Test::Mojo;
use Mojolicious::Lite;
use Encode;
use File::Temp 'tempdir';

my $tempdir = tempdir(CLEANUP => 1);

plugin Credentials => {
	keys => [ '1234567890ABCDEF1234567890ABCDEF'],
	dir  => $tempdir,
};

get '/get' => sub {
	my $self = shift;
	my ($k) = $self->param('k');
	$self->render(data => $self->credentials->get($k));
};

get '/list' => sub {
	my $self = shift;
	$self->render(data => join ', ', $self->credentials->list);
};

post '/post' => sub {
	my $self = shift;
	my ($k, $v) = map { $self->param($_) } qw/k v/;

	$self->credentials->put($k, $v);
	
	$self->render(text => 'ok');
};

my $t = Test::Mojo->new();
$t->post_ok('/post', form => { k => 'a', v => 1 });
$t->get_ok('/list')->content_is('a');
$t->get_ok('/get?k=a')->content_is(1);
