#!/usr/bin/perl

use strict;
use warnings;
use Module::Build::PM_Filter;

my $builder = Module::Build::PM_Filter->new(
    module_name         => 'MyModule',
    license             => 'gpl',
    dist_author         => 'Víctor Moral <victor@taquiones.net>',
    dist_abstract       => 'This is just a sample distribution',
    dist_version_from   => 'lib/MyModule.pm',
    requires => {
        'Test::More'                =>  0,
        'Module::Build::PM_Filter'  =>  0,
    },
    add_to_cleanup      => [ 'MyModule-*' ],
);

$builder->create_build_script();
