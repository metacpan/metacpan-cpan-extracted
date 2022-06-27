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
    } qr/"blah"/;
};

done_testing;
