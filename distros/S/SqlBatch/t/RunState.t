#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;
use Data::Dumper;
use SqlBatch::RunState;
require_ok('SqlBatch::RunState');

my $rs1=SqlBatch::RunState->new();

$rs1->attr1(1);
ok($rs1->attr1,"Set and get normal attribute");
$rs1->_hidden(1);
ok($rs1->_hidden,"Set and get hidden attribute");

ok($rs1->commit_mode() eq 'autocommitted',"Default commit mode");
$rs1->autocommit(0);
ok($rs1->commit_mode() eq 'nonautocommitted',"Changed commit mode");

my $rs2=SqlBatch::RunState->new($rs1);
#say Dumper($rs2);
ok($rs2->attr1,"New runstate: attribute copied");
ok($rs2->commit_mode() eq 'nonautocommitted',"New runstate: attribute copied"); 
ok(! $rs2->_hidden(),"New runstate: no hidden attribute copied"); 

done_testing();
