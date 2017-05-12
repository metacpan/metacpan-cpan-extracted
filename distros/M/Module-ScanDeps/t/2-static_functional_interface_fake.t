#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 304;
use lib qw(t t/data/static);
use Utils;
use version;


##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps' ); }


##############################################################
# Static dependency check of a script that doesn't use
# anything
##############################################################
my @roots1 = qw(t/data/static/null.pl);
my $expected_rv1 =
{
  "null.pl" => {
                 file => generic_abs_path("t/data/static/null.pl"),
                 key => "null.pl",
                 type => "data",
               },
};

# Functional i/f
my $rv1 = scan_deps(@roots1);
compare_scandeps_rvs($rv1, $expected_rv1, \@roots1);


##############################################################
# Static dependency check of a circular dependency:
#        ___
#     |/_   \
#     M     _M
#      \____/|
#
##############################################################
my @roots2 = qw(t/data/static/egg.pm);
my $expected_rv2 =
{
  "chicken.pm" => {
                    file    => generic_abs_path("t/data/static/chicken.pm"),
                    key     => "chicken.pm",
                    type    => "module",
                    used_by => ["egg.pm"],
                    uses    => ["egg.pm"],
                  },
  "egg.pm"     => {
                    file    => generic_abs_path("t/data/static/egg.pm"),
                    key     => "egg.pm",
                    type    => "module",
                    used_by => ["chicken.pm"],
                    uses    => ["chicken.pm"],
                  },
};

# Functional i/f
my $rv2 = scan_deps(@roots2);
compare_scandeps_rvs($rv2, $expected_rv2, \@roots2);


##############################################################
# Static dependency check of the following dependency tree
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
my @roots3 = qw(t/data/static/outer_diamond_N.pm);
my $expected_rv3 =
{
  "inner_diamond_E.pm" => {
                            file    => generic_abs_path("t/data/static/inner_diamond_E.pm"),
                            key     => "inner_diamond_E.pm",
                            type    => "module",
                            used_by => ["inner_diamond_N.pm"],
                            uses    => ["inner_diamond_S.pm"],
                          },
  "inner_diamond_N.pm" => {
                            file    => generic_abs_path("t/data/static/inner_diamond_N.pm"),
                            key     => "inner_diamond_N.pm",
                            type    => "module",
                            used_by => ["outer_diamond_N.pm"],
                            uses    => ["inner_diamond_E.pm", "inner_diamond_W.pm"],
                          },
  "inner_diamond_S.pm" => {
                            file    => generic_abs_path("t/data/static/inner_diamond_S.pm"),
                            key     => "inner_diamond_S.pm",
                            type    => "module",
                            used_by => ["inner_diamond_W.pm", "inner_diamond_E.pm"],
                            uses    => ["outer_diamond_S.pm"],
                          },
  "inner_diamond_W.pm" => {
                            file    => generic_abs_path("t/data/static/inner_diamond_W.pm"),
                            key     => "inner_diamond_W.pm",
                            type    => "module",
                            used_by => ["inner_diamond_N.pm"],
                            uses    => ["inner_diamond_S.pm"],
                          },
  "outer_diamond_E.pm" => {
                            file    => generic_abs_path("t/data/static/outer_diamond_E.pm"),
                            key     => "outer_diamond_E.pm",
                            type    => "module",
                            used_by => ["outer_diamond_N.pm"],
                            uses    => ["outer_diamond_S.pm"],
                          },
  "outer_diamond_N.pm" => {
                            file => generic_abs_path("t/data/static/outer_diamond_N.pm"),
                            key  => "outer_diamond_N.pm",
                            type => "module",
                            uses => ["inner_diamond_N.pm", "outer_diamond_E.pm", "outer_diamond_W.pm"],
                          },
  "outer_diamond_S.pm" => {
                            file    => generic_abs_path("t/data/static/outer_diamond_S.pm"),
                            key     => "outer_diamond_S.pm",
                            type    => "module",
                            used_by => ["outer_diamond_E.pm", "outer_diamond_W.pm", "inner_diamond_S.pm"],
                          },
  "outer_diamond_W.pm" => {
                            file    => generic_abs_path("t/data/static/outer_diamond_W.pm"),
                            key     => "outer_diamond_W.pm",
                            type    => "module",
                            used_by => ["outer_diamond_N.pm"],
                            uses    => ["outer_diamond_S.pm"],
                          },
};

# Functional i/f
my $rv3 = scan_deps(@roots3);
compare_scandeps_rvs($rv3, $expected_rv3, \@roots3);


##############################################################
# Static dependency check of the following dependency tree
# (i.e. multiple inputs)
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
my @roots4 = qw(t/data/static/InputA.pl
                t/data/static/InputB.pl
                t/data/static/InputC.pl);
my $expected_rv4 =
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
                   uses    => ["TestD.pm"],
                 },
  "TestD.pm"  => {
                   file    => generic_abs_path("t/data/static/TestD.pm"),
                   key     => "TestD.pm",
                   type    => "module",
                   used_by => ["InputC.pl", "TestC.pm"],
                 },
};

# Functional i/f
my $rv4 = scan_deps(@roots4);
compare_scandeps_rvs($rv4, $expected_rv4, \@roots4);


##############################################################
# Static dependency check of the following dependency tree
# Tests the .pm only lists the .pl once in it's used_by entries
#
#   Duplicator.pl
#       /  \
#      /    \
#     /      \
#     \      /
#      \    /
#       \  /
#   Duplicated.pm
#
##############################################################
my @roots5 = qw(t/data/static/Duplicator.pl);
my $expected_rv5 =
{
  "Duplicated.pm" => {
                       file    => generic_abs_path("t/data/static/Duplicated.pm"),
                       key     => "Duplicated.pm",
                       type    => "module",
                       used_by => ["Duplicator.pl"],
                     },
  "Duplicator.pl" => {
                       file => generic_abs_path("t/data/static/Duplicator.pl"),
                       key  => "Duplicator.pl",
                       type => "data",
                       uses => ["Duplicated.pm"],
                     },
};

# Functional i/f
my $rv5 = scan_deps(@roots5);
compare_scandeps_rvs($rv5, $expected_rv5, \@roots5);


##############################################################
# Static dependency check of a module that does a
# use 5.010;
# Note that this doesn't test as much as the other tests
# since feature.pm ropes in all kinds of things.
##############################################################
SKIP: {
  skip "Skipping 'use VERSION' tests on pre-5.10.0", 2 if version->new($]) < version->new("5.10.0");
  my @roots1 = qw(t/data/static/useVERSION.pm);

  # Functional i/f
  my $rv1 = scan_deps(@roots1);
  ok(exists $rv1->{"useVERSION.pm"}, "use VERSION: source file included");
  ok(exists $rv1->{"feature.pm"}, "use VERSION: feature.pm included");
}



__END__
