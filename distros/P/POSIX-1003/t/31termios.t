#!/usr/bin/env perl
# Modernized version of t/sigaction.t from POSIX.pm

use strict;
use warnings;

use Test::More;

use lib 'lib', 'blib/lib', 'blib/arch';
use POSIX::1003::Termios;

my @getters = qw(getcflag getiflag getispeed getlflag getoflag getospeed);

plan tests => 3 + 2 * (3 + NCCS() + @getters);

my $r;

# create a new object
my $termios = eval { POSIX::1003::Termios->new };
is( $@, '', "calling POSIX::1003::Termios->new" );
ok( defined $termios, "\tchecking if the object is defined" );
isa_ok( $termios, "POSIX::Termios", "\tchecking the type of the object" );

# testing getattr()

SKIP: {
    -t STDIN or skip("STDIN not a tty", 2);
    $r = eval { $termios->getattr(0) };
    is( $@, '', "calling getattr(0)" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}

SKIP: {
    -t STDOUT or skip("STDOUT not a tty", 2);
    $r = eval { $termios->getattr(1) };
    is( $@, '', "calling getattr(1)" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}

SKIP: {
    -t STDERR or skip("STDERR not a tty", 2);
    $r = eval { $termios->getattr(2) };
    is( $@, '', "calling getattr(2)" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}

# testing getcc()
for my $i (0..NCCS()-1) {
    $r = eval { $termios->getcc($i) };
    is( $@, '', "calling getcc($i)" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}

# testing getcflag()
for my $method (@getters) {
    $r = eval { $termios->$method() };
    is( $@, '', "calling $method()" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}

