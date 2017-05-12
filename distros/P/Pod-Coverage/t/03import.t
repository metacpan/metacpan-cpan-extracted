#!/usr/bin/perl -w
use strict;
use lib 't/lib';
use Test::More tests => 3;


is( capture(q{ use Pod::Coverage package => 'Simple2'; }), "Simple2 has a Pod::Coverage rating of 0.75\n'naked' is uncovered", "Simple2 works correctly in import form");

is( capture(q{ use Pod::Coverage package => 'Simple7' }), "Simple7 has a Pod::Coverage rating of 0\nThe following are uncovered: bar, foo", 'Simple7 import form');

is( capture(q{ use Pod::Coverage 'Simple7' }), "Simple7 has a Pod::Coverage rating of 0\nThe following are uncovered: bar, foo", 'Simple7 import form, implicit package');

sub capture {
    my $code = shift;
    open(FH, ">test.out") or die "Couldn't open test.out for writing: $!";
    open(OLDOUT, ">&STDOUT");
    select(select(OLDOUT));
    open(STDOUT, ">&FH");

    eval $code;

    close STDOUT;
    close FH;
    open(STDOUT, ">&OLDOUT");
    open(FH, "<test.out") or die "Couldn't open test.out for reading: $!";
    my $result;
    { local $/; $result = <FH>; }
    chomp $result;
    close FH;
    unlink('test.out');
    return $result;
}
