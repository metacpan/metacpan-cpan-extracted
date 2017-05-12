#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Module::Build;

# Autoflush ON
local $| = 1;

####################
# INIT BUILDER
####################

my $builder = Module::Build->new(
    module_name        => 'String::Range::Expand',
    license            => 'perl',
    dist_author        => 'Mithun Ayachit <mithun@cpan.org>',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires     => {
        'Test::More' => 0,
        'version'    => 0,
    },
    requires => {

    },
    add_to_cleanup     => ['String-Range-Expand-*'],
    create_license     => 1,
    create_makefile_pl => 'traditional',
    meta_merge         => {
        keywords  => [qw(text string range expand permute glob)],
        resources => {
            bugtracker =>
              'https://github.com/mithun/perl-string-range-expand/issues',
            repository =>
              'git://github.com/mithun/perl-string-range-expand.git',
            homepage => 'https://github.com/mithun/perl-string-range-expand',
        },
    },
);

####################
# CREATE BUILD SCRIPT
####################
$builder->create_build_script();
