#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

use_ok('Parse::IRCLog');

isa_ok(Parse::IRCLog->new, 'Parse::IRCLog');

eval { Parse::IRCLog->new->new };
ok($@, "new dies on call as instance method");
