#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 546;

use lib qw(t t/data/static);
use Utils;


##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps' ); }


##############################################################
# RECURSE OPTION TESTS

##############################################################
# Using the following dependency tree
#
#                            M
#                           /|\
#                          / | \
#                         /  |  \
#                        /   M   \
#                       /   / \   \
#                      /   /   \   \
#                     M   M     M   M
#                      \   \   /   /
#                       \   \ /   /
#                        \   M   /
#                         \  |  /
#                          \ | /
#                            M
#
#   With dependencies always going from the top downwards
##############################################################
my @roots1 = qw(t/data/static/outer_diamond_N.pm);
my $expected_rv1 =
{
  "inner_diamond_N.pm" => {
                            file    => generic_abs_path("t/data/static/inner_diamond_N.pm"),
                            key     => "inner_diamond_N.pm",
                            type    => "module",
                            used_by => ["outer_diamond_N.pm"],
                          },
  "outer_diamond_E.pm" => {
                            file    => generic_abs_path("t/data/static/outer_diamond_E.pm"),
                            key     => "outer_diamond_E.pm",
                            type    => "module",
                            used_by => ["outer_diamond_N.pm"],
                          },
  "outer_diamond_N.pm" => {
                            file => generic_abs_path("t/data/static/outer_diamond_N.pm"),
                            key  => "outer_diamond_N.pm",
                            type => "module",
                            uses => ["inner_diamond_N.pm", "outer_diamond_E.pm", "outer_diamond_W.pm"],
                          },
  "outer_diamond_W.pm" => {
                            file    => generic_abs_path("t/data/static/outer_diamond_W.pm"),
                            key     => "outer_diamond_W.pm",
                            type    => "module",
                            used_by => ["outer_diamond_N.pm"],
                          },
};

my $rv1 = scan_deps(
            files   => \@roots1,
            recurse => 0,
          );

compare_scandeps_rvs($rv1, $expected_rv1, \@roots1);


##############################################################
# Using the following dependency tree
#
#     InputA.pl       InputB.pl   InputC.pl
#       /  \             \           /
#      /    \             \         /
#     /      \             \       /
# TestA.pm  TestB.pm   TestC.pm   /
#                            \   /
#                             \ /
#                          TestD.pm
#
##############################################################
my @roots2 = qw(t/data/static/InputA.pl
                t/data/static/InputB.pl
                t/data/static/InputC.pl);

my $expected_rv2 =
{
  "InputA.pl" => {
                   file => generic_abs_path("t/data/static/InputA.pl"),
                   key  => "InputA.pl",
                   type => "data",
                   uses => ["TestA.pm", "TestB.pm"],
                 },
  "InputB.pl" => {
                   file => generic_abs_path("t/data/static/InputB.pl"),
                   key  => "InputB.pl",
                   type => "data",
                   uses => ["TestC.pm"],
                 },
  "InputC.pl" => {
                   file => generic_abs_path("t/data/static/InputC.pl"),
                   key  => "InputC.pl",
                   type => "data",
                   uses => ["TestD.pm"],
                 },
  "TestA.pm"  => {
                   file    => generic_abs_path("t/data/static/TestA.pm"),
                   key     => "TestA.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },
  "TestB.pm"  => {
                   file    => generic_abs_path("t/data/static/TestB.pm"),
                   key     => "TestB.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },
  "TestC.pm"  => {
                   file    => generic_abs_path("t/data/static/TestC.pm"),
                   key     => "TestC.pm",
                   type    => "module",
                   used_by => ["InputB.pl"],
                 },
  "TestD.pm"  => {
                   file    => generic_abs_path("t/data/static/TestD.pm"),
                   key     => "TestD.pm",
                   type    => "module",
                   used_by => ["InputC.pl"], # No "TestC.pm" used_by entry
                 },
};

my $rv2 = scan_deps(
            files   => \@roots2,
            recurse => 0,
          );

compare_scandeps_rvs($rv2, $expected_rv2, \@roots2);


##############################################################
# SKIP OPTION TESTS

##############################################################
# Dependency tree for tests
#
#     InputA.pl       InputB.pl   InputC.pl
#       /  \             \           /
#      /    \             \         /
#     /      \             \       /
# TestA.pm  TestB.pm   TestC.pm   /
#                            \   /
#                             \ /
#                          TestD.pm
#
##############################################################
my @roots_ABC = qw(t/data/static/InputA.pl
                   t/data/static/InputB.pl
                   t/data/static/InputC.pl);

##############################################################
my $expected_rv_ABC_skip_TestA =
{
  "InputA.pl" => {
                   file => generic_abs_path("t/data/static/InputA.pl"),
                   key  => "InputA.pl",
                   type => "data",
                   uses => ["TestA.pm", "TestB.pm"],
                 },
  "InputB.pl" => {
                   file => generic_abs_path("t/data/static/InputB.pl"),
                   key  => "InputB.pl",
                   type => "data",
                   uses => ["TestC.pm"],
                 },
  "InputC.pl" => {
                   file => generic_abs_path("t/data/static/InputC.pl"),
                   key  => "InputC.pl",
                   type => "data",
                   uses => ["TestD.pm"],
                 },

# It's OK to have this despite TestA.pm being skipped since this entry only shows
# InputA.pl has been parsed and shown to depend on TestA.pm
  "TestA.pm"  => {
                   file    => generic_abs_path("t/data/static/TestA.pm"),
                   key     => "TestA.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },

  "TestB.pm"  => {
                   file    => generic_abs_path("t/data/static/TestB.pm"),
                   key     => "TestB.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },
  "TestC.pm"  => {
                   file    => generic_abs_path("t/data/static/TestC.pm"),
                   key     => "TestC.pm",
                   type    => "module",
                   used_by => ["InputB.pl"],
                   uses    => ["TestD.pm"],
                 },
  "TestD.pm"  => {
                   file    => generic_abs_path("t/data/static/TestD.pm"),
                   key     => "TestD.pm",
                   type    => "module",
                   used_by => ["InputC.pl", "TestC.pm"],
                 },
};

my $rv3 = scan_deps(
            files   => \@roots_ABC,
            skip    => { generic_abs_path("t/data/static/TestA.pm") => 1 },
            recurse => 1,
          );

compare_scandeps_rvs($rv3, $expected_rv_ABC_skip_TestA, \@roots_ABC);


##############################################################
my $expected_rv_ABC_skip_TestC =
{
  "InputA.pl" => {
                   file => generic_abs_path("t/data/static/InputA.pl"),
                   key  => "InputA.pl",
                   type => "data",
                   uses => ["TestA.pm", "TestB.pm"],

                 },
  "InputB.pl" => {
                   file => generic_abs_path("t/data/static/InputB.pl"),
                   key  => "InputB.pl",
                   type => "data",
                   uses => ["TestC.pm"],
                 },
  "InputC.pl" => {
                   file => generic_abs_path("t/data/static/InputC.pl"),
                   key  => "InputC.pl",
                   type => "data",
                   uses => ["TestD.pm"],
                 },
  "TestA.pm"  => {
                   file    => generic_abs_path("t/data/static/TestA.pm"),
                   key     => "TestA.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },
  "TestB.pm"  => {
                   file    => generic_abs_path("t/data/static/TestB.pm"),
                   key     => "TestB.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },

# It's OK to have this despite TestC.pm being skipped since this entry only shows
# InputB.pl has been parsed and shown to depend on TestC.pm
  "TestC.pm"  => {
                   file    => generic_abs_path("t/data/static/TestC.pm"),
                   key     => "TestC.pm",
                   type    => "module",
                   used_by => ["InputB.pl"],
                 },

  "TestD.pm"  => {
                   file    => generic_abs_path("t/data/static/TestD.pm"),
                   key     => "TestD.pm",
                   type    => "module",
                   used_by => ["InputC.pl"],  # No TestC used_by
                 },
};

my $rv4 = scan_deps(
            files   => \@roots_ABC,
            skip    => { generic_abs_path("t/data/static/TestC.pm") => 1 },
            recurse => 1,
          );

compare_scandeps_rvs($rv4, $expected_rv_ABC_skip_TestC, \@roots_ABC);


##############################################################
# Test multiple skip entries
my $expected_rv_ABC_skip_TestA_TestC =
{
  "InputA.pl" => {
                   file => generic_abs_path("t/data/static/InputA.pl"),
                   key  => "InputA.pl",
                   type => "data",
                   uses => ["TestA.pm", "TestB.pm"],
                 },
  "InputB.pl" => {
                   file => generic_abs_path("t/data/static/InputB.pl"),
                   key  => "InputB.pl",
                   type => "data",
                   uses => ["TestC.pm"],
                 },
  "InputC.pl" => {
                   file => generic_abs_path("t/data/static/InputC.pl"),
                   key  => "InputC.pl",
                   type => "data",
                   uses => ["TestD.pm"],
                 },

# It's OK to have this despite TestA.pm being skipped since this entry only shows
# InputA.pl has been parsed and shown to depend on TestA.pm
  "TestA.pm"  => {
                   file    => generic_abs_path("t/data/static/TestA.pm"),
                   key     => "TestA.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },

  "TestB.pm"  => {
                   file    => generic_abs_path("t/data/static/TestB.pm"),
                   key     => "TestB.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },

# It's OK to have this despite TestC.pm being skipped since this entry only shows
# InputB.pl has been parsed and shown to depend on TestC.pm
  "TestC.pm"  => {
                   file    => generic_abs_path("t/data/static/TestC.pm"),
                   key     => "TestC.pm",
                   type    => "module",
                   used_by => ["InputB.pl"],
                 },

  "TestD.pm"  => {
                   file    => generic_abs_path("t/data/static/TestD.pm"),
                   key     => "TestD.pm",
                   type    => "module",
                   used_by => ["InputC.pl"],  # No TestC used_by
                 },
};

my $rv5 = scan_deps(
            files   => \@roots_ABC,
            skip    => { 
                         generic_abs_path("t/data/static/TestA.pm") => 1,
                         generic_abs_path("t/data/static/TestC.pm") => 1,
                       },
            recurse => 1,
          );

compare_scandeps_rvs($rv5, $expected_rv_ABC_skip_TestA_TestC, \@roots_ABC);


##############################################################
my @roots_AB = qw(t/data/static/InputA.pl
                  t/data/static/InputB.pl);

my $expected_rv_AB_skip_TestC =
{
  "InputA.pl" => {
                   file => generic_abs_path("t/data/static/InputA.pl"),
                   key  => "InputA.pl",
                   type => "data",
                   uses => ["TestA.pm", "TestB.pm"],
                 },
  "InputB.pl" => {
                   file => generic_abs_path("t/data/static/InputB.pl"),
                   key  => "InputB.pl",
                   type => "data",
                   uses => ["TestC.pm"],
                 },
  "TestA.pm"  => {
                   file    => generic_abs_path("t/data/static/TestA.pm"),
                   key     => "TestA.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },
  "TestB.pm"  => {
                   file    => generic_abs_path("t/data/static/TestB.pm"),
                   key     => "TestB.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },

# It's OK to have this despite TestC.pm being skipped since this entry only shows
# InputB.pl has been parsed and shown to depend on TestC.pm
  "TestC.pm"  => {
                   file    => generic_abs_path("t/data/static/TestC.pm"),
                   key     => "TestC.pm",
                   type    => "module",
                   used_by => ["InputB.pl"],
                 },
#
# No TestD entry
#
};

my $rv6 = scan_deps(
            files   => \@roots_AB,
            skip    => { generic_abs_path("t/data/static/TestC.pm") => 1 },
            recurse => 1,
          );

compare_scandeps_rvs($rv6, $expected_rv_AB_skip_TestC, \@roots_AB);

##############################################################

my $expected_rv_AB_skip_TestD =
{
  "InputA.pl" => {
                   file => generic_abs_path("t/data/static/InputA.pl"),
                   key  => "InputA.pl",
                   type => "data",
                   uses => ["TestA.pm", "TestB.pm"],
                 },
  "InputB.pl" => {
                   file => generic_abs_path("t/data/static/InputB.pl"),
                   key  => "InputB.pl",
                   type => "data",
                   uses => ["TestC.pm"],
                 },
  "TestA.pm"  => {
                   file    => generic_abs_path("t/data/static/TestA.pm"),
                   key     => "TestA.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },
  "TestB.pm"  => {
                   file    => generic_abs_path("t/data/static/TestB.pm"),
                   key     => "TestB.pm",
                   type    => "module",
                   used_by => ["InputA.pl"],
                 },
  "TestC.pm"  => {
                   file    => generic_abs_path("t/data/static/TestC.pm"),
                   key     => "TestC.pm",
                   type    => "module",
                   used_by => ["InputB.pl"],
                 },
#
# No TestD entry
#
};

my $rv7 = scan_deps(
            files   => \@roots_AB,
            skip    => { "t/data/static/TestD.pm" => 1 },
            recurse => 1,
          );

#is_deeply($rv7, $expected_rv_AB_skip_TestD);
compare_scandeps_rvs($rv7, $expected_rv_AB_skip_TestD, \@roots_AB);

__END__
