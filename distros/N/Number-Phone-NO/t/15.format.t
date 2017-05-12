#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;
use Number::Phone;
use Number::Phone::NO;

{
    my $n = new Number::Phone('+47 982 93 610');
    isa_ok($n, "Number::Phone::NO");
    isa_ok($n, "Number::Phone");
    ok($n->is_valid(), "Valid number");
    
    is($n->format(), "+47 982 93 610", "format works for cellphone");
}

{
    my $n = Number::Phone->new("+4722225555");
    isa_ok($n, "Number::Phone::NO");
    is($n->format, "+47 22 22 55 55", "format works for regular");
}
{
    my $n = Number::Phone->new("+4780080855");
    is($n->format, "+47 800 80 855", "format works for tollfree");
}