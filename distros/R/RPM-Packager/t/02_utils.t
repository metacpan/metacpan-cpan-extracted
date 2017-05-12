#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use RPM::Packager::Utils;

subtest 'is_command', sub {
    is( RPM::Packager::Utils::is_command('grep Changelog'), 1, 'command detected' );
    is( RPM::Packager::Utils::is_command('1.0.0'),          0, 'non-command detected' );
};

subtest 'eval_command', sub {
    is( RPM::Packager::Utils::eval_command('echo foobar'), 'foobar', 'eval command worked' );
};

done_testing();
