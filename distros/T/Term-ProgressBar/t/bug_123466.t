#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Warnings;
use Term::ProgressBar;

my $progress = Term::ProgressBar->new({ term => 0, count => 5 });
$progress->update(2);
is($progress->last_update, 2, 'progress has updated');
