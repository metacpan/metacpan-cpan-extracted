#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    # Windows can't change timezone inside Perl script
    if ($ENV{TEST_TZ}) {
        $ENV{TZ} = delete $ENV{TEST_TZ};
        exec $^X (map { "-I\"$_\"" } @INC), $0, @ARGV;
    };
}

use Time::Local;
use POSIX::strftime::Compiler;

my $fmt = shift @ARGV || '%z';
my @t = @ARGV ? localtime timelocal(@ARGV) : localtime;

print POSIX::strftime::Compiler::strftime($fmt,@t);

