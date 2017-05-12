#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese);

use Sub::Recursive;

use vars qw/ $rec /;

sub manual_recursive {
    my $_foo = sub { @_ ? $_[0] + $rec->(@_[1 .. $#_]) : 0 };
    return sub {
        local $rec = $_foo;
        $_foo->(@_);
    };
}

sub leaker {
    my $_foo;
    $_foo = sub { @_ ? $_[0] + $_foo->(@_[1 .. $#_]) : 0 };
    return $_foo;
}

my $leaker = leaker();
my $manual = manual_recursive();
my $recursive = recursive { @_ ? $_[0] + $REC->(@_[1 .. $#_]) : 0 };

my @vals = 1 .. 50;

cmpthese(-10, {
    leaker => sub { $leaker->(@vals) },
    manual => sub { $manual->(@vals) },
    recursive => sub { $recursive->(@vals) },
});

__END__
            Rate    manual recursive    leaker
recursive 1447/s        --       -0%       -0%
manual    1449/s        0%        --       -0%
leaker    1454/s        0%        0%        --


This is perl, v5.8.0 built for MSWin32-x86-multi-thread
(with 1 registered patch, see perl -V for more detail)

Copyright 1987-2002, Larry Wall

Binary build 806 provided by ActiveState Corp. http://www.ActiveState.com
Built 00:45:44 Mar 31 2003
