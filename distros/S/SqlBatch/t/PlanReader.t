#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;

require_ok('SqlBatch::AbstractConfiguration');
require_ok('SqlBatch::AbstractPlan');
require_ok('SqlBatch::InstructionBase');
require_ok('SqlBatch::SqlInstruction');
require_ok('SqlBatch::InsertInstruction');
require_ok('SqlBatch::DeleteInstruction');
require_ok('SqlBatch::BeginInstruction');
require_ok('SqlBatch::CommitInstruction');
require_ok('SqlBatch::RollbackInstruction');
require_ok('SqlBatch::Configuration');
require_ok('SqlBatch::PlanReader');

use Data::Dumper;

package Testplan;

use parent "SqlBatch::AbstractPlan";

our @instructions;

sub add_instructions {
    my $self         = shift;

    push @instructions,@_;
}

package main;

my $file1  =<<'FILE1';
# Comment
undefined line
--SQL-- --id sql1
blabla
--END--

--INSERT-- --id=insert1
'a';'b'
'1';'2'
'3';'4'
--END--

--SQL-- --id=sql2 --tags=tag1,!tag2
blabla
--END--

--DELETE-- --id=delete1
'a';'b'
'1';'2'
'3';'4'
--END--
FILE1
;

my $plan1 = Testplan->new();
my $reader1 = SqlBatch::PlanReader->new(undef,$plan1,SqlBatch::AbstractConfiguration->new());
$reader1->files(\$file1);

eval { $reader1->load };
ok(!$@,"Load plan without errors");
say $@ if $@;

ok(scalar(@Testplan::instructions)==6,"Correct number of instructions");
say Dumper(\@Testplan::instructions) unless scalar(@Testplan::instructions)==6;

done_testing();
