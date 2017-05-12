#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok('NetHack::Monster::Spoiler');

my $list = NetHack::Monster::Spoiler->_list;

is(ref $list, 'ARRAY');
