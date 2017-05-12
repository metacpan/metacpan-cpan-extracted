#!perl

use strict;
use warnings;
use Test::More tests => 5;

use_ok("Sub::Current");

sub davros { ROUTINE() }
is(davros(), \&davros, 'davros');

sub borusa {
    my $coderef = ROUTINE();
    is($coderef, \&borusa, 'borusa');
}
borusa();

sub romana {
    @_ = (ROUTINE(), \&romana, 'romana');
    &is;
}
romana();

sub rassilon {
    is(ROUTINE(), \&rassilon, 'rassilon');
}
rassilon();
