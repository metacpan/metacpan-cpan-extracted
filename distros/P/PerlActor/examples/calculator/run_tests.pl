#!/usr/bin/perl -w

use strict;
use lib qw( ../../lib app test );
use PerlActor::Runner::Console;

my $runner = new PerlActor::Runner::Console();
$runner->run('scripts/test_all.pact_suite');
