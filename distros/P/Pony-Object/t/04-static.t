#!/usr/bin/env perl

use lib './lib';
use lib './t';

use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 9;
use Pony::Object;
use Static::Base;
use Static::Issue;
use Static::Unstatic;

my $base  = Static::Base->new;
my $base2 = Static::Base->new;
my $issue = Static::Issue->new;

$base->set_type('task');
ok($base->{type} == 4, "1st static");
ok($base->get_type eq 'task');
$base->type_list->{task} = 400;
$base->set_type('task');
ok($base->{type} == 400);

$base2->set_type('task');
ok($base2->{type} == 400, "2nd static");

my $base3 = Static::Base->new;
$base3->set_type('task');
ok($base3->{type} == 400, "3rd static");

$issue->set_type('task');
ok($issue->{type} == 4, "1st static child");
$issue->type_list->{task} = 444;
my $issue2 = Static::Issue->new;
$issue2->set_type('task');
ok($issue2->{type} == 444, "2nd static child");

my $unstat = Static::Unstatic->new;
my $unstat2 = Static::Unstatic->new;
$unstat->type_list->{task} = 555;
$unstat->set_type('task');
ok($unstat->{type} == 555, "unstatic 1");
$unstat2->set_type('task');
ok($unstat2->{type} == 4, "unstatic 2");

diag( "Testing static for Pony::Object $Pony::Object::VERSION" );