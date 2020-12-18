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
        is eval { confess("test"); 1 }, undef, "require/import fails if module isn't loaded ok";
        like $@, qr/confess/, "...and error is that module isn't loaded ok";

        require Carp;
        Carp->import('confess');
        is eval { confess("test2"); 1 }, undef, "require/import ok";
        like $@, qr/test2/, "...and error is from the required module ok";

    }
}

done_testing();

