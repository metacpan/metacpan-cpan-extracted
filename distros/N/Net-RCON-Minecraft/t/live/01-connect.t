#!perl
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Test::Warnings ':all';
use Local::Helpers;
use Carp; # for mocked subs

use Net::RCON::Minecraft;

my %opts = env_rcon;
plan(skip_all => live_skip) unless %opts;

my $rcon = Net::RCON::Minecraft->new(%opts);

lives_ok { $rcon->connect };

done_testing;
