#!/usr/bin/perl
use strict;
use warnings;
use Plack::Builder;

my $app = sub {
    return [
        '200', [ 'Content-Type' => 'text/plain', 'Content-Lenth' => 13 ],
        ["hello, world!"]
    ];
};

builder { $app };
