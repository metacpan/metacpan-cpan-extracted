#!/usr/bin/perl

use strict;
use warnings;

use Test::Simple tests => 3;
use OpenFrame::Object;

ok(1, "loaded");
OpenFrame::debug_level( ALL => 1 );
ok(my $object = OpenFrame::Object->new(),"created object ok");
eval {
  $SIG{__WARN__} = sub { die @_ };
  $object->error("message");
};
ok($@, "error message thrown");



