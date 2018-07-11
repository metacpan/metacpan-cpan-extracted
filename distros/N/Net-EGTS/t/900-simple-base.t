#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib ../t/lib);

use Test::More tests    => 2;
use Test::EGTS;

BEGIN {
    use_ok 'Net::EGTS::Simple';
}

subtest 'base' => sub {
    plan tests => 1;

    my $client = Net::EGTS::Simple->new(
        host        => 'localhost',
        port        => 4444,
        did         => 0,
        description => 'test',
    );
    isa_ok $client, 'Net::EGTS::Simple';
};
