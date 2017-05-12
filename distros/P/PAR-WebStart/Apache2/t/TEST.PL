#!perl
use strict;
use warnings FATAL => 'all';
use Apache::TestRunPerl();
use lib map {("../blib/$_", "../../blib/$_")} qw(lib arch);

Apache::TestRunPerl->new->run(@ARGV);
