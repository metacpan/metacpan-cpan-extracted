#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp;

use Test::More;
use Test::FailWarnings;

use File::Temp;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

{
    open my $fh, '>', "$dir/é";
    print {$fh} 'print 123';
}

use Cwd;

my $oldcwd = Cwd::cwd();

chdir $dir;

# Quotes are for Windows.
my $cmd = qq<"$^X" é>;

utf8::upgrade($cmd);

my $got = do {
    use Sys::Binmode;
    readpipe $cmd;
};

is( $got, 123, 'expected output' );

chdir $oldcwd;

done_testing;

1;
