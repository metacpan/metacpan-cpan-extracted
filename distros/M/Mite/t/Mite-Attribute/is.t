#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Attribute;

tests "bad is" => sub {
    throws_ok {
        Mite::Attribute->new(
            name        => 'foo',
            is          => 'blah'
        );
    } qr/^I do not understand this option \(is => blah\) on attribute \(foo\) at \Q$0\E/;
};

done_testing;
