#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 1;
use Slow::Loading::Module;

{
    no warnings;
    my $whee = 'whee!';
    sub whee { return $whee }
}

is whee(), 'whee!', 'subs work!';
