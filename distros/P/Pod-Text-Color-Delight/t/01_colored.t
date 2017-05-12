#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use Pod::Text::Color::Delight;

use Test::More;

my $delight = Pod::Text::Color::Delight->new;

subtest 'normal' => sub {
    my $got = $delight->_colored('foo', 'red');
    is $got, "\e[31mfoo\e[0m";
};

subtest 'invalid (fall back to "reset")' => sub {
    my $got = $delight->_colored('foo', 'INVALID_COLOR');
    is $got, "\e[0mfoo\e[0m";
};

done_testing;
