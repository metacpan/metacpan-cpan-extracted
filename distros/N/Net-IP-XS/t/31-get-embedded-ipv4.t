#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 8;

use Net::IP::XS qw(ip_get_embedded_ipv4);
use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

my @data = (
    [ ],
    [ '', undef ],
    [ qw(:127.0.0.1                                     127.0.0.1) ],
    [ qw(::::::::::) ],
    [ qw(::::::::::;:127.0.0.1                          127.0.0.1) ],
    [ qw(ASDF:ASDF:ASDF:ASDF:ASDF:ASDF:ASDF:127.0.0.1   127.0.0.1) ],
    [ qw(127.0.0.1                                      127.0.0.1) ],
    [ qw(:123123123123123123123123123123123) ],
);

for (@data) {
    my ($input, $res_exp) = @{$_};
    $c->start();
    my $res = ip_get_embedded_ipv4($input);
    $c->stop();
    is($res, $res_exp, $input);
}

1;
