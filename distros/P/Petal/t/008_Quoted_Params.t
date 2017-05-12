#!/usr/bin/perl
use warnings;
use strict;
package Foo;
sub param { return $_[1] };

package main;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template = new Petal ('quoted_params.xml');
my $cgi = bless {}, 'Foo';

eval {
    my $string = $template->process ( cgi => $cgi );
};

ok(! (defined $@ and $@), "ran") || diag $@;
