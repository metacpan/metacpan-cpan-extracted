#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;
use PQConform;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

conformance(sub { scalar make_queue(@_) }, 'sqlite');

done_testing();
