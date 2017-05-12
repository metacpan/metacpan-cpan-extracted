#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;

use lib File::Spec->catdir($Bin, 'lib');

use Dog;
use Scope::With qw(using);
use Test::More tests => 4;

my $spot = Dog->new;

using (Dog $spot) {
    is bark,     'woof!';
    is wag_tail, '*wags tail*';
    is yawn,     'yawn!';
}

pass('no need to add a trailing semicolon');
