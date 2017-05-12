#!perl

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use File::Spec;

plan skip_all => 'Set AUTHOR_TEST to run this test'
    unless $ENV{AUTHOR_TEST};
plan skip_all => 'Perl::Critic required'
    unless eval 'use Perl::Critic; 1';
plan skip_all => 'Test::Perl::Critic required'
    unless eval 'use Test::Perl::Critic; 1';

my %opt;
my $rc_file = File::Spec->catfile($Bin, 'perlcriticrc');
$opt{'-profile'} = $rc_file if -r $rc_file;
Test::Perl::Critic->import(%opt);
all_critic_ok("lib");
