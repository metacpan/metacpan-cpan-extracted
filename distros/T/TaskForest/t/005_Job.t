# -*- perl -*-

# 
use Test::More tests => 4;
use strict;
use warnings;
use Data::Dumper;
use Cwd;

BEGIN {
    use_ok( 'TaskForest::Job',     "Can use Job" );
}


my $job = TaskForest::Job->new(name => 'foo');
isa_ok($job,          'TaskForest::Job',      'created a job');
is($job->{name},       'foo',                  '  and it has got the right name');

my $s = $job->check();

is($s,         0,      '  and it is not ready yet');


