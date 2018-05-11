use Test::More;
use strict;
use warnings;
use Data::Dumper;
use lib 't/lib';
use Carp;
use TestPW;

for my $test (qw<simple circular circular-noerr hidden continuous after_tmpl>) {
    
    TestPW->run_in_dir($test);
}

done_testing;
