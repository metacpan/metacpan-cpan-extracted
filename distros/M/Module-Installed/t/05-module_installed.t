#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

#use_ok Module::Installed;

use Module::Installed qw(module_installed);


my @installed = qw(
    Data::Dumper
    Carp
    ExtUtils::MakeMaker
);

my @not_installed = qw(
    Bad::Module
    Not::Available
);

# true
{
    for (@installed) {
        is module_installed($_), 1, "$_ is installed ok";
    }
}

# false
{
    for (@not_installed) {
        is module_installed($_), 0, "$_ is not installed ok";
    }
}

# load
{
    if (module_installed('Carp')) {
        require Carp;
        Carp->import('croak');
        is eval { croak("error"); 1 }, undef, "require/import ok";
    }
}

done_testing();

