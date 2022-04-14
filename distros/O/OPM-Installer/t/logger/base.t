#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Test::More;
use Test::LongString;

use OPM::Installer::Logger;

my $logger = OPM::Installer::Logger->new;

diag "Testing *::Logger version " . OPM::Installer::Logger->VERSION;

isa_ok $logger, 'OPM::Installer::Logger';

can_ok $logger, qw/notice debug info warn error log/;

done_testing();
