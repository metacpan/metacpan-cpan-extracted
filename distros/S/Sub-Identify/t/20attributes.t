#!perl

BEGIN {
    if ($] < 5.014001) {
        print "1..0 # SKIP: tests won't pass on less recent perls\n";
        exit;
    }
}

use Test::More tests => 3;
use strict;
use warnings;
use Sub::Identify ();

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $subref, @attributed) = @_;
    is(Sub::Identify::sub_fullname($subref), 'main::foo', 'half compiled');
    return ();
}

sub foo : MyAttribute {}

BEGIN {
    is(Sub::Identify::sub_fullname(\&foo), 'main::foo', 'full compiled');
}

is(Sub::Identify::sub_fullname(\&foo), 'main::foo', 'runtime');
