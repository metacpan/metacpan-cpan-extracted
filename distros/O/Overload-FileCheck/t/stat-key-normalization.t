#!/usr/bin/perl -w

# Test that _stat_for() correctly handles case-variant and st_-prefixed keys.
# Regression test for https://github.com/cpan-authors/Overload-FileCheck/issues/35

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:stat};
use Fcntl 'S_IFREG';

my @base = ( 0, 0, S_IFREG, (0) x 10 );

# Uppercase key: Size => 42
{
    my $expect = [@base];
    $expect->[7] = 42;
    is stat_as_file( Size => 42 ), $expect, 'uppercase key Size => 42';
}

# Mixed-case key: SIZE => 99
{
    my $expect = [@base];
    $expect->[7] = 99;
    is stat_as_file( SIZE => 99 ), $expect, 'uppercase key SIZE => 99';
}

# st_-prefixed lowercase key: st_size => 55
{
    my $expect = [@base];
    $expect->[7] = 55;
    is stat_as_file( st_size => 55 ), $expect, 'st_size prefix key';
}

# st_-prefixed uppercase key: ST_SIZE => 77
{
    my $expect = [@base];
    $expect->[7] = 77;
    is stat_as_file( ST_SIZE => 77 ), $expect, 'ST_SIZE uppercase prefix key';
}

# Mixed case mtime
{
    my $expect = [@base];
    $expect->[9] = 12345;
    is stat_as_file( Mtime => 12345 ), $expect, 'mixed-case Mtime key';
}

done_testing;
