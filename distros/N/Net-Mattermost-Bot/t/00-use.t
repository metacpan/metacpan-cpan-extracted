#!/usr/bin/env perl -T
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Net-Mattermost-Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Net::Mattermost::Bot') };

