#!/usr/bin/perl -w
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MySQL::Insert',
    license             => 'perl',
    dist_author         => 'Walery Studennikov <despair@cpan.org>',
    dist_version_from   => 'lib/MySQL/Insert.pm',
    build_requires => {
        'Test::More' => 0,
        'DBI' => 0,
    },
    add_to_cleanup      => [ 'MySQL-Insert-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
