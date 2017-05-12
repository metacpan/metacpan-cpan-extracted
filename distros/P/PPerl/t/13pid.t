#!perl -w
use strict;
use Test;
BEGIN { plan tests => 4 };

for my $perl ( $^X, './pperl -Iblib/lib -Iblib/arch --prefork 1', './pperl', './pperl' ) {
    my $child = open FOO, "$perl t/pid.plx|"
      or die "can't fork: $!";
    my $answer = <FOO>;
    close FOO
      or die "subprocess error $?";
    ok ($answer, "$child\n");
}

`./pperl -k t/pid.plx`
