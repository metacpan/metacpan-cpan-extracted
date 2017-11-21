#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;

use OTRS::OPM::Maker::Utils::Git;

my $git =  dirname(__FILE__) . '/../bin/git';

$OTRS::OPM::Maker::Utils::Git::GIT = 'perl ' . $git;

my $toplevel = OTRS::OPM::Maker::Utils::Git->find_toplevel( dir => '.' );
is $toplevel, 'hello';

done_testing();
