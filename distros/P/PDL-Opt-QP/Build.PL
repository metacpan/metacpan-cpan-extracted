#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/inc";

use Module::Build::Pluggable (
    'PDL', 'Fortran',
    'CheckLib' => { lib => 'blas', },
    'Warn64Bit',
);

my $builder = Module::Build::Pluggable->new(
    module_name       => 'PDL::Opt::QP',
    dist_version_from => 'lib/PDL/Opt/QP.pd',
    license           => 'perl',
    create_readme     => 1,

    extra_linker_flags => [qw{ -lblas }],
    f_source           => [qw{ src }],

    requires => {
        'PDL' => '2.00',
    },
    configure_requires => {
        'Module::Build'                      => '0.4004',
        'Module::Build::Pluggable'           => '0',
        'Module::Build::Pluggable::PDL'      => '0.20',
        'Module::Build::Pluggable::Fortran'  => '0.20',
        'Module::Build::Pluggable::CheckLib' => '1.00',

    },
    test_requires => {
        'Test::More'      => '0',
        'Test::Exception' => 0,
    },

    recursive_test_files => 1,

    meta_merge => {
        resources => {
            bugtracker => 'https://github.com/mvgrimes/pdl-opt-qp/issues',
            repository => 'http://github.com/mvgrimes/pdl-opt-qp'
        }
    },

    add_to_cleanup => [qw{PDL-Opt-QP-*}],

);

# Module::Build::Plugin adds configure_requires and build_requires entries
# for its modules. Since WARN64 is in the inc/ dir, it shouldn't be included.
delete $builder->prereq_data->{configure_requires}
  ->{'Module::Build::Pluggable::Warn64Bit'};
delete $builder->prereq_data->{build_requires}
  ->{'Module::Build::Pluggable::Warn64Bit'};

$builder->create_build_script();

