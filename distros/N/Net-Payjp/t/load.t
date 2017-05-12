#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 2;

use_ok('Net::Payjp');
can_ok('Net::Payjp', 'new');
