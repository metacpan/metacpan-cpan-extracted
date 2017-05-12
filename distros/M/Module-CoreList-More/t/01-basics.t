#!perl

use 5.010;
use strict;
use warnings;

use Module::CoreList::More;
use Test::More 0.98;

subtest removed_from => sub {
    my @tests = (
        {args=>["Foo"],       answer=>undef},
        {args=>["Benchmark"], answer=>undef},
        {args=>["CGI"],       answer=>'5.021'},
    );
    my $i = -1;
    for my $test (@tests) {
        $i++;
        is_deeply(scalar(Module::CoreList::More->removed_from(@{$test->{args}})),
                  $test->{answer}, "$i ($test->{args}[0])");
    }
};

subtest removed_from_by_date => sub {
    my @tests = (
        # currently all answers for removed_from & removed_from_by_date are the same
        {args=>["Foo"],       answer=>undef},
        {args=>["Benchmark"], answer=>undef},
        {args=>["CGI"],       answer=>'5.021'},
    );
    my $i = -1;
    for my $test (@tests) {
        $i++;
        is_deeply(scalar(Module::CoreList::More->removed_from_by_date(@{$test->{args}})),
                  $test->{answer}, "$i ($test->{args}[0])");
    }
};

subtest first_release => sub {
    my @tests = (
        {args=>["Foo"]      , answer=>undef},
        {args=>["Benchmark"], answer=>'5'},
        {args=>["CGI"]      , answer=>'5.004'},
        {args=>["Unicode"]  , answer=>'5.006002'},
    );
    my $i = -1;
    for my $test (@tests) {
        $i++;
        # Try as both function and method
        is_deeply(scalar(Module::CoreList::More->first_release(@{$test->{args}})),
		  $test->{answer}, "$i ($test->{args}[0])");
        is_deeply(scalar(Module::CoreList::More::first_release(@{$test->{args}})),
		  $test->{answer}, "$i ($test->{args}[0])");
    }
};

subtest first_release_by_date => sub {
    my @tests = (
        {args=>["Foo"], answer=>undef},
        {args=>["Benchmark"], answer=>'5'},
        {args=>["CGI"], answer=>'5.004'},
        {args=>["Unicode"], answer=>'5.008'},
    );
    my $i = -1;
    for my $test (@tests) {
        $i++;
        # Try as both function and method
        is_deeply(scalar(Module::CoreList::More->first_release_by_date(@{$test->{args}})),
                  $test->{answer}, "$i ($test->{args}[0])");
        is_deeply(scalar(Module::CoreList::More::first_release_by_date(@{$test->{args}})),
                  $test->{answer}, "$i ($test->{args}[0])");
    }
};

subtest list_context_first_release => sub {
  my @tests = (
        {args=>['Foo'], answer=>[]},
        {args=>['Carp'], answer=>['5']},
        {args=>['CGI'], answer=>['5.004']},
	      );

  for my $test (@tests) {
    my @args = @{$test->{args}};
    is_deeply([Module::CoreList::More->first_release(@args)],
      $test->{answer}, "first_release @args");
    is_deeply([Module::CoreList::More->first_release_by_date(@args)],
      $test->{answer}, "first_release_by_date @args");
  }
};

subtest is_core => sub {
    my @tests = (
        ["parent", undef, 5.010000], # 0
        ["parent", undef, 5.010001], # 1
        ["parent", 0.223, 5.010001], # 0
        ["parent", 0.223, 5.011000], # 1
        ["parent", 0.223, 5.018000], # 1

        ["CGI", undef, 5.010000], # 1
        ["CGI", undef, 5.021001], # 0

        ["Module::CoreList", 2.76, 5.017], # test
    );
    my $i = -1;
    for my $test (@tests) {
        $i++;
        is_deeply(Module::CoreList::More->is_core(@$test), Module::CoreList->is_core(@$test), "$i ($test->[0])");
    }
};

subtest is_still_core => sub {
    # always in core
    ok(Module::CoreList::More->is_still_core("Benchmark"));

    # never in core
    ok(!Module::CoreList::More->is_still_core("Module::Path"));

    # not yet core
    ok(!Module::CoreList::More->is_still_core("IO::Socket::IP", undef, 5.010001));

    # removed
    ok(!Module::CoreList::More->is_still_core("CGI"));


    # call as function
    ok(Module::CoreList::More::is_still_core("Benchmark"));

    # arg: module_version
    ok(!Module::CoreList::More->is_still_core("Benchmark", 9.99));

    # arg: perl_version
    ok( Module::CoreList::More->is_still_core("IO::Socket::IP", undef, 5.020000));
    ok(!Module::CoreList::More->is_still_core("IO::Socket::IP", undef, 5.010000));
};

subtest list_still_core_modules => sub {
    my %mods5010000 = Module::CoreList::More->list_still_core_modules(5.010);
    my %mods5010001 = Module::CoreList::More->list_still_core_modules(5.010001);
    my %mods5018000 = Module::CoreList::More->list_still_core_modules(5.018000);

    is( $mods5010000{'Benchmark'}, 1.1);
    is( $mods5010001{'Benchmark'}, 1.11);
    is( $mods5018000{'Benchmark'}, 1.15);

    ok(!$mods5010000{'parent'});
    is( $mods5010001{'parent'}, 0.221);
    is( $mods5018000{'parent'}, 0.225);

    ok(!$mods5010000{'CGI'});
    ok(!$mods5010001{'CGI'});
    ok(!$mods5018000{'CGI'});
};

subtest list_still_core_modules => sub {
    my %mods5010000 = Module::CoreList::More->list_core_modules(5.010);
    my %mods5010001 = Module::CoreList::More->list_core_modules(5.010001);
    my %mods5018000 = Module::CoreList::More->list_core_modules(5.018000);
    my %mods5021000 = Module::CoreList::More->list_core_modules(5.021000);

    is( $mods5010000{'Benchmark'}, 1.1);
    is( $mods5010001{'Benchmark'}, 1.11);
    is( $mods5018000{'Benchmark'}, 1.15);

    ok(!$mods5010000{'parent'});
    is( $mods5010001{'parent'}, 0.221);
    is( $mods5018000{'parent'}, 0.225);

    ok( $mods5010000{'CGI'});
    ok( $mods5010001{'CGI'});
    ok( $mods5018000{'CGI'});
    ok(!$mods5021000{'CGI'});
};

DONE_TESTING:
done_testing;
