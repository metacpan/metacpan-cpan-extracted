#!/usr/local/bin/perl

my ($NO_TEST_TESTER,$NO_TEST_POD);
BEGIN {
    eval "use Test::Tester 0.08;";
    $NO_TEST_TESTER = $@;
    eval "use Test::Pod 0.95";
    $NO_TEST_POD = $@;
}
use Test::More tests=>54;
use POSIX;
use strict;

use_ok("Test::AutoLoader");
can_ok("Test::AutoLoader",'autoload_ok');
SKIP: {
    skip "Pod test requires Test::Pod 0.95",1 if $NO_TEST_POD;
    pod_file_ok("AutoLoader.pm");
}

if ($NO_TEST_TESTER) {
  SKIP:{ skip "Remaining tests require Test::Tester 0.08", 51}
    exit(0);
}


require File::Spec;

# test setup:
unshift @INC, 'tlib';
require TestBusted1;
require TestBusted2;
require EmptyModule;

my @unreadable = (File::Spec->catdir(qw(tlib auto TestBusted1)),
                  File::Spec->catfile(qw(tlib auto TestBusted2 no_ready.al)));
my $CAN_CHMOD =  chmod 0000, @unreadable;
my $file_errors;
$file_errors .=<<DIAG if $CAN_CHMOD;
    couldn't load no_ready.al: Permission denied
DIAG
$file_errors .= <<DIAG;
    couldn't load nobody_home.al: No such file or directory
    couldn't load empty.al: false return value
DIAG


my @tests = (
  [ ['POSIX'],{ok=>1,name=>"Autoload of POSIX (all files)"},"Standard-distribution module, all files"],
  [ [qw(POSIX strcpy)],{ok=>1,name=>"Autoload of POSIX (listed subroutines)"},"Standard-distribution module, one file"],
  [ [qw(POSIX no_such_function)], {ok=>0,diag=>"    couldn't load no_such_function.al: No such file or directory"}, "Standard-distribution, bad subroutine name"],
  [ [qw(strict)], {ok=>0,diag=>"Unable to find valid autoload directory for strict"}, "Non-existent auto directory"],
  [ [qw(EmptyModule)], {ok=>0,diag=>"No autoloaded files found"}, "No files in auto directory"],
  [ [qw(Foo::Bar::Baz)], {ok=>0,diag=>"Unable to find valid autoload directory for Foo::Bar::Baz (perhaps you forgot to load 'Foo::Bar::Baz'?)"}, "Module not loaded"],
  [ [qw(TestBusted2 no_worky)], {ok=>0,diag=>"    couldn't load no_worky.al: Compile error"}, "Syntax error"],
  [ [qw(TestBusted2 no_ready nobody_home empty)], {ok=>0,diag=>$file_errors}, "File-reading errors"],
  [ [qw()], {ok=>0,diag=>"",name=>"Can't test autoload of empty package"}, "Empty arglist"],
#  [ [qw()], {ok=>0,diag=>""}, "name"],

);

if ($CAN_CHMOD) {
    push @tests, 
      [ [qw(TestBusted1)], {ok=>0,diag=>"Unable to find valid autoload directory for TestBusted1"}, "Unreadable auto directory"],
}

foreach my $test (@tests) {
    check_test( sub {autoload_ok(@{$test->[0]})},$test->[1],$test->[2])
}

if ($CAN_CHMOD) {
    chmod 0755, @unreadable or warn "Couldn't chmod @unreadable back: $!\n";
} else {
  SKIP:{skip "Couldn't set up unreadable directory for test",5}
}
