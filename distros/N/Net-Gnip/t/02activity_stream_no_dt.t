#!perl -w

use strict;
use Test::More tests => 12;
use Net::Gnip::Activity;
use_ok('Net::Gnip::ActivityStream');

my $stream;
ok($stream = Net::Gnip::ActivityStream->new( _no_dt => 1 ), "Created activity stream");
is(scalar($stream->activities), 0, "Got 0 activities");

my $action    = 'update';
my $actor     = 'foo';
my $activity = Net::Gnip::Activity->new($action, $actor);
ok($stream->activities($activity), "Added an activity");
is(scalar($stream->activities), 1, "Got 1 activity");
my ($tmp) = $stream->activities;
is($tmp->action, $action,   "Got the same uid back");
is($tmp->actor, $actor,    "Got the same type back");

my $xml;
ok($xml = $stream->as_xml, "Got xml");
ok($stream = $stream->parse($xml), "Parsed xml");
is(scalar($stream->activities), 1, "Got 1 activity still");
($tmp) = $stream->activities;
is($tmp->action, $action,   "Got the same uid back");
is($tmp->actor, $actor,    "Got the same type back");

