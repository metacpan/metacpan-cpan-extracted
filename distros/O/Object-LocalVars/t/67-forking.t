#!/usr/bin/perl
use strict;
use warnings;
use blib;  
use Config;
use Test::More;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class = "t::Object::Complete";

# Win32 fork is done with threads, so we need at least perl 5.8
if ( $^O eq 'MSWin32' && $Config{useithreads} &&  $] < 5.008 ) {
    plan skip_all => "Win32 fork() support requires perl 5.8";
}
else {
    plan tests => 4;
}

my $o = test_constructor($class, name => "Charlie" );

my $child_pid = fork;
if ( ! $child_pid ) { # we're in the child
    is( $o->name, "Charlie", "got right name in child process");
    exit;
}
waitpid $child_pid, 0;

# current Test::More object counter is off due to child
Test::More->builder->current_test( 4 );

