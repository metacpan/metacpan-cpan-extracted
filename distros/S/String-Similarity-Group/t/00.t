#!/usr/bin/perl -w
use Test::Simple 'no_plan';
use warnings;
use strict;
use lib './lib';
use Cwd;
use vars qw($_part);

use String::Similarity::Group ':all';
use Smart::Comments '###';

my @a = qw/victory victorious victoria velociraptor velocirapto matrix garrot s/;

my @r;
ok_part("VERY BASIC TEST...");


ok( 1, 'started');

ok @r = groups( 0.8, \@a ),'groups()';
### @r
ok @r = groups_hard( 0.8, \@a ),'groups_hard()';
### @r
ok @r = groups_lazy( 0.8, \@a ),'groups_lazy()';
### @r


$String::Similarity::Group::DEBUG =1;
### LONERS 
my @med = _group_medium(0.9, \@a );
### grouped on 0.9: @med
ok @r = loners( 0.9, \@a ),'loners()';
### @r





my( $e0, $s0 ) = similarest(\@a, 'matryx');
ok $e0 eq 'matrix';

my $e1 = similarest(\@a, 'matryx');
ok $e1, 'similarest() returns';
ok $e1 eq 'matrix', "$e1 eq 'matrix'";


ok_part("similartest()");

my @b = qw/a b leonardo/;
ok( ! defined similarest( \@b, 'jorge', 0.9) ,'similarest() with min 0.9, and none will be that high.. should not return defined');







sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


