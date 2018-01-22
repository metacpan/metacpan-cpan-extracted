#!perl

use Test::Most;    # plan is down at bottom

use IO::Pty;
use Term::TtyWrite;

dies_ok( sub { Term::TtyWrite->new }, "no arg no dice" );
dies_ok( sub { Term::TtyWrite->new("/dev/tty\0bad") }, "illegal embedded NUL" );

my $faketerm = IO::Pty->new;
my $tty;

ok( $tty = Term::TtyWrite->new( $faketerm->ttyname ), "write access to pty" );
isa_ok( $tty, "Term::TtyWrite" );

dies_ok( sub { $tty->write },             "nothing to write" );
dies_ok( sub { $tty->write_delay("hi") }, "no delay specified" );

plan tests => 6;
