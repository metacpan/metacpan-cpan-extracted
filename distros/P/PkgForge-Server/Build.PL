#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my %conf_files = map { $_ => $_ } grep { -f } glob 'conf/*';
my %doc_files  = map { $_ => $_ } grep { -f } map { glob $_ } ( 'doc/*', 'doc/admin/*' );
my %init_files = map { $_ => $_ } grep { -f } glob 'init/*';
my %sbin_files = map { $_ => $_ } grep { -f } glob 'sbin/*';

my $build = Module::Build->new(
    module_name   => 'PkgForge::Server',
    dist_abstract => 'Package Forge servers',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '1.1.10',
    license => 'gpl',
    requires => {
        'File::Copy'          => 0,
        'File::Find::Rule'    => 0,
        'File::Path'          => 0,
        'File::Temp'          => '0.22',
        'IPC::Run'            => 0,
        'Log::Dispatch'       => '2.21',
        'MIME::Lite::TT'      => 0,
        'Moose'               => 0,
        'MooseX::Getopt'      => 0,
        'MooseX::LogDispatch' => 0,
        'MooseX::Types'       => 0,
        'PkgForge'            => '1.4.6',
        'Readonly'            => 0,
        'Template'            => 0,
        'Try::Tiny'           => 0,
        'UNIVERSAL::require'  => 0,
        'perl'                => '5.8.8',
    },
    build_requires => {
        'Test::More'       => '0.87',
    },
    conf_files => \%conf_files,
    doc_files  => \%doc_files,
    sbin_files => \%sbin_files,
    init_files => \%init_files,
    install_path => {
      conf => '/etc/pkgforge',
      doc  => '/usr/share/pkgforge/doc/server',
      init => '/etc/init.d',
      sbin => '/usr/sbin',
    },
    add_to_cleanup => [ 'MANIFEST.bak', 'ChangeLog.bak' ],
    create_makefile_pl => 'traditional',
);
$build->add_build_element('conf');
$build->add_build_element('doc');
$build->add_build_element('init');
$build->add_build_element('sbin');
$build->create_build_script;
