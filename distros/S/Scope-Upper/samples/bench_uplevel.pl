#!perl

use strict;
use warnings;

use blib;

use Benchmark qw<cmpthese>;

use Scope::Upper qw<:words>;
BEGIN { *uplevel_xs = \&Scope::Upper::uplevel }

use Sub::Uplevel;
BEGIN { *uplevel_pp = \&Sub::Uplevel::uplevel }

sub void { }

sub foo_t  { void { } }

sub foo_pp { uplevel_pp(0, sub { }) }

sub foo_xs { uplevel_xs { } }

print "\nuplevel to current scope:\n";
cmpthese -1, {
 tare => sub { foo_t() },
 pp   => sub { foo_pp() },
 xs   => sub { foo_xs() },
};

sub bar_1_t  { bar_2_t() }
sub bar_2_t  { void() }

sub bar_1_pp { bar_2_pp() }
sub bar_2_pp { uplevel_pp(1, sub { }) }

sub bar_1_xs { bar_2_xs() }
sub bar_2_xs { uplevel_xs { } UP }

print "\nuplevel to one scope above:\n";
cmpthese -1, {
 tare => sub { bar_2_t() },
 pp   => sub { bar_2_pp() },
 xs   => sub { bar_2_xs() },
};

sub hundred { 1 .. 100 }

sub baz_t  { hundred() }

sub baz_pp { uplevel_pp(0, sub { 1 .. 100 }) }

sub baz_xs { uplevel_xs { 1 .. 100 } }

print "\nreturning 100 values:\n";
cmpthese -1, {
 tare => sub { my @r = baz_t() },
 pp   => sub { my @r = baz_pp() },
 xs   => sub { my @r = baz_xs() },
};

my $n = 10_000;
my $tare_code = "sub { my \@c; \@c = caller(0) for 1 .. $n }->()";

print "\ncaller() slowdown:\n";
cmpthese 30, {
 tare => sub { system { $^X } $^X, '-e', "use blib; use List::Util; $tare_code" },
 pp   => sub { system { $^X } $^X, '-e', "use blib; use Sub::Uplevel; $tare_code" },
 xs   => sub { system { $^X } $^X, '-e', "use blib; use Scope::Upper; $tare_code" },
}
