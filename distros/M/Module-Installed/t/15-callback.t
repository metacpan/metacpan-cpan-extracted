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

# callback param
{
    is eval {module_installed('Carp', 1); 1}, undef, "callback param must be a cref";
}

# callback
{

    for (@installed) {
        is module_installed($_, \&cb), 1, "$_ sent in with cb ok";
    }

    for (@not_installed) {
        is module_installed($_, \&cb), 0, "$_ sent in with cb nok";
    }
}

sub cb {
    my ($m, $i) = @_;
    return "$m:$i";
}

done_testing;

