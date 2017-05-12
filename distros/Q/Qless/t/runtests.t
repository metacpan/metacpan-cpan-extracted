#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Cwd qw(abs_path);

BEGIN {
	my @folder = File::Spec->splitdir(dirname(__FILE__));
	my $basepath = abs_path(join '/', @folder);
	unshift @INC, join '/', $basepath, 'lib';
};

use TestQless::General;
use TestQless::Recurring;

Test::Class->runtests;
