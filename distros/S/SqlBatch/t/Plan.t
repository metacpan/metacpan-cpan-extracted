#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;
use Data::Dumper;

require_ok('SqlBatch::SqlInstruction');
require_ok('SqlBatch::InsertInstruction');
require_ok('SqlBatch::DeleteInstruction');
require_ok('SqlBatch::BeginInstruction');
require_ok('SqlBatch::CommitInstruction');
require_ok('SqlBatch::RollbackInstruction');
require_ok('SqlBatch::Configuration');
require_ok('SqlBatch::Plan');

my $conffile1  =<<'FILE1';
{
    "datasource" : "DBI:RAM:",
    "username" : "user",
    "password" : "pw",
    "force_autocommit" : "1"
}
FILE1
;

my $conf1 = SqlBatch::Configuration->new(\$conffile1);
my $dbh   = $conf1->database_handles->{autocommitted};

my @instructions1 = ();

my $plan1 = SqlBatch::Plan->new($conf1);

#my $filter1 = SqlBatch::PlanTagFilter->new();

my $insert_sth;
my $delete1_sth;
my $delete2_sth;

my @seq1 = (
    SqlBatch::SqlInstruction->new($conf1,'create table t (a int,b varchar)'),
    SqlBatch::InsertInstruction->new(
	$conf1,
	{
	    a => 1,
	    b => 'first',
	},
	\$insert_sth,
	table => 't'
    ),
    SqlBatch::InsertInstruction->new(
	$conf1,
	{
	    a => 2,
	    b => 'second',
	},
	\$insert_sth,
	table => 't'
    ),
    SqlBatch::InsertInstruction->new(
	$conf1,
	{
	    a => 3,
	    b => 'third',
	},
	\$insert_sth,
	table => 't'
    ),

    SqlBatch::DeleteInstruction->new(
	$conf1,
	{
	    a => 1,
	},
	\$delete1_sth,
	table => 't'
    ),
    SqlBatch::DeleteInstruction->new(
	$conf1,
	{
	    b => 'second',
	},
	\$delete2_sth,
	table => 't'
    ),
);

$plan1->add_instructions(@seq1);
eval {
    $plan1->run();
};
ok(! $@,"Running sequence");
say $@ if $@;

my $ary = $dbh->selectall_arrayref("select * from t");
ok(scalar(@$ary)==1,"Execution reached expected state");
#say Dumper($ary);

done_testing;
