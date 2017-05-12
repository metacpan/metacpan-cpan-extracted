#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

use Net::LCDproc;
use Carp;

use Sys::Hostname;
use YAML::XS;
use Try::Tiny;

my $lcdproc;
my $screen;

$lcdproc = Net::LCDproc->new(server => 'badhost', port => 1234);

try {
    $lcdproc->init;
}
catch {
    say "cannot connect: " . $_->message;
    say "Dump: " . $_->dump;
    confess $_->short_msg;
};

