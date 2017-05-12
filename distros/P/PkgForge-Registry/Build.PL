#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my %doc_files = map { $_ => $_ } grep { -f } glob 'doc/*';
my %conf_files = map { $_ => $_ } grep { -f } glob 'conf/*';
my %scripts    = map { $_ => $_ } grep { -f } glob 'scripts/*';

my $build = Module::Build->new(
    module_name   => 'PkgForge::Registry',
    dist_abstract => 'Package Forge job registry',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '1.3.0',
    license => 'gpl',
    requires => {
        'DBD::Pg'              => 0,
        'DBIx::Class'          => '0.08112',
        'DateTime::Format::Pg' => 0,
        'Moose'                => 0,
        'MooseX::Types::Moose' => 0,
        'Text::Abbrev'         => 0,
        'perl'                 => '5.8.8',
    },
    build_requires => {
        'Test::More'           => '0.87',
    },
    conf_files    => \%conf_files,
    doc_files     => \%doc_files,
    scripts_files => \%scripts,
    install_path => {
        scripts => '/usr/share/pkgforge/scripts',
        conf    => '/etc/pkgforge',
        doc     => '/usr/share/pkgforge/doc/registry',
    },
    add_to_cleanup => [ 'MANIFEST.bak', 'ChangeLog.bak' ],
    create_makefile_pl => 'traditional',
);
$build->add_build_element('doc');
$build->add_build_element('conf');
$build->add_build_element('scripts');
$build->create_build_script;
