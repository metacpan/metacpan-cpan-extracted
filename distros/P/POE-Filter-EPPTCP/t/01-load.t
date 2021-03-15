#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;

use Test::More 'tests' => 1;

use lib::relative '../lib';

require_ok 'POE::Filter::EPPTCP';
