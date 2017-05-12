#!/usr/bin/perl
use strict;
use warnings;
use blib;  
use Config;
# threads must come before Test::More to work, but ignore failure since
# we skip anyway if its not loaded
BEGIN { eval "use threads;" } 
use Test::More;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class = "t::Object::Complete";

if ( $Config{usethreads} ) {
  plan tests => 4;
}
else {
  plan skip_all => "perl threads not available";
}

my $o = test_constructor($class, name => "Charlie" );

my $thr = threads->new( 
    sub { 
        is( $o->name, "Charlie", "got right name in thread") 
    } 
);

$thr->join;

