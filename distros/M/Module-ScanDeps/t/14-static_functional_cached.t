#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use lib qw(t t/data/static);
use Utils;
use version;


##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps' ); }



##############################################################
# Static dependency check of a script that doesn't use
# anything with basic cache_cb test added
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
expected_cache_cb_args({key  => 'null.pl',
                        file => 't/data/static/null.pl',
                    });

my $rv1 = scan_deps(files => \@roots1,
                    cache_cb => \&cache_cb
                );
compare_scandeps_rvs($rv1, $expected_rv1, \@roots1);

### check if we can use M::SD::Cache
my $skip_cache_tests = 1;
eval {require Module::ScanDeps::Cache;};
unless ($@){
    $skip_cache_tests = Module::ScanDeps::Cache::prereq_missing();
    warn $skip_cache_tests, "\n";
}
my $cache_file = 'deps_cache.dat';

for my $t(qw/write_cache use_cache/){

  SKIP:
    {
     skip "Skipping M:SD::Cache tests" , 289 if $skip_cache_tests;

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
     my $rv2 = scan_deps(files => \@roots2,
                         cache_file => $cache_file,
                         recurse => 1,
                     );
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
     my $rv3 = scan_deps(cache_file => $cache_file,
                         recurse => 1,
                         files => \@roots3);
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
     my $rv4 = scan_deps(cache_file => $cache_file,
                         recurse => 1,
                         files => \@roots4);
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
     my $rv5 = scan_deps(cache_file => $cache_file,
                         recurse => 1,
                         files => \@roots5);
     compare_scandeps_rvs($rv5, $expected_rv5, \@roots5);


   }  ### SKIP block wrapping M::SD::Cache tests
}     ### end of for (qw/write_cache use_cache/)





### cache testing helper functions ###
{
my ($cb_args, $expecting_write);

sub expected_cache_cb_args{
    $cb_args = shift;
}
sub cache_cb{
    my %args = @_;
    is($args{key}, $cb_args->{key}, "check arg 'key' in cache_cb.");
    is($args{file}, $cb_args->{file}, "check arg 'file' in cache_cb.");
    if ( $expecting_write ){
        is($args{action}, 'write', "expecting write action");
    }
    if ($args{action} eq 'read'){
        $expecting_write = 1;
        return 0;
    }
    elsif ( $args{action} eq 'write' ){
        $expecting_write = 0;
        return 1
    }
    my $action  = $args{action};
    ok( 0, "wrong action: got [$action] must be 'read' or 'write'");
}


}### end cache testing helper functions ###

### test Module::ScanDeps::Cache.pm

SKIP:
{
    skip "Skipping M:SD::Cache tests" , 9 if $skip_cache_tests;
    my %files = ('file1.pl' => "use TestModule;\n",
                 'file2.pl' => "use TestModule;\n",
                 'file3.pl' => "use TestModule;\n return 0;\n");
 
    for my $name (keys %files){
        open my $fh, '>', $name or die "Can not open file $name: $!";
        print $fh $files{$name};
        close $fh or die "Can not close file $name: $!";
    }
    
    my $cb = Module::ScanDeps::Cache::get_cache_cb();
    my $mod = [];
    my $ret = $cb->(key     => 'testfile',
                    file    => 'file1.pl',
                    action  => 'read',
                    modules => $mod
                );
    is( $ret, 0, "File not present in cache");
    $ret = $cb->(key     => 'testfile',
                 file    => 'file1.pl',
                 modules => [qw /TestModule.pm/],
                 action  => 'write',
            );
    is( $ret, 1, "Writing file to cache");
    $ret = $cb->(key     => 'testfile',
                 file    => 'file1.pl',
                 action  => 'read',
                 modules => $mod
             );
    is( $ret, 1, "File is present in cache");
    is( $mod->[0], 'TestModule.pm', "cache_cb sets modules 1");
    $mod = [];
    $ret = $cb->(key     => 'testfile',
                 file    => 'file2.pl',
                 action  => 'read',
                 modules => $mod
             );
    is( $ret, 1, "Identical file returns the same dependencies from cache");
    is( $mod->[0], 'TestModule.pm', "cache_cb sets modules 2");
    $mod = [];
    $ret = $cb->(key     => 'testfile',
                 file    => 'file3.pl',
                 action  => 'read',
                 modules => $mod
             );
    is( $ret, 0, "No cached deps returned for file with different content");
    is( @$mod, 0, "cache_cb does not set modules if no deps found");

    eval {$cb->(action => 'foo')};
    ok ($@ =~ /must be read or write/, "cache_cb dies on wrong action");
    for my $name (keys %files){
        unlink $name or die "Could not unlink file $name: $!";
    }
}

unlink( $cache_file );
__END__
