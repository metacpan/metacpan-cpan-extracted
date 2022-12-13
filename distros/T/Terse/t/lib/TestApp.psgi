#!/usr/bin/perl
use strict;
use warnings;
use Plack::Builder;
use TestApp;

my $app = TestApp->to_app;

builder {
    $app;
};
