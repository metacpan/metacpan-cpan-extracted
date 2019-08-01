#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;
use Data::Dumper;
use File::Spec;

require_ok('SqlBatch::Engine');

my ($volume, $bindir, undef) = File::Spec->splitpath($0);
my $binbase_dir     = File::Spec->catpath($volume, $ENV{PWD}, $bindir);
my $testrun1_dir    = File::Spec->catpath($volume, $binbase_dir, 'testrun1');
my $testrun1_config = File::Spec->catpath($volume, $testrun1_dir, 'sb.conf');

my $testsub = sub {
    my $tags = shift;
    my $expect1 = shift;
    my $expect2 = shift;

    my $app = SqlBatch::Engine->new(
	"-directory=$testrun1_dir",
	"-configfile=$testrun1_config",
	"-verbosity=2",
	$tags,
	);
    $app->run();
#say Dumper($app);
    
    my $dbh = $app->plan->current_databasehandle();

    my $ary1 = $dbh->selectall_arrayref("select * from t1");
    ok(scalar(@$ary1)==$expect1,"Execution reached expected state for table1");
# say Dumper($ary1);
    
    my $ary2 = $dbh->selectall_arrayref("select * from t2");
    ok(scalar(@$ary2)==$expect2,"Execution reached expected state for table2");
# say Dumper($ary2);
};

subtest "Test-run tag: setup1",$testsub,"-tags=setup1",1,1;
subtest "Test-run tag: setup1 & production",$testsub,"-tags=setup1,production",2,2;

done_testing();
