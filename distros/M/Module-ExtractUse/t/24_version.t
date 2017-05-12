#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use Module::ExtractUse;


{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, '5.010';
use 5.010;
CODE
}

{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, '5.006_001';
use 5.006_001;
CODE
}

{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, '5.008';
use 5.008;
CODE
}

