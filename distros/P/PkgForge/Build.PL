#!/usr/bin/perl
use Module::Build; # -*-perl-*-

my %doc_files  = map { $_ => $_ } grep { -f } map { glob $_ } ( 'doc/*', 'doc/user/*');
my %conf_files = map { $_ => $_ } grep { -f } glob 'conf/*';

my $build = Module::Build->new(
    module_name   => 'PkgForge',
    dist_abstract => 'Tools for building packages from source',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '1.4.8',
    license => 'gpl',
    requires => {
        'Data::UUID::Base64URLSafe' => 0,
        'Digest::SHA1'              => 0,
        'Email::Address'            => 0,
        'Email::Valid'              => 0,
        'File::Find::Rule'          => 0,
        'File::HomeDir'             => 0,
        'Module::Find'              => 0,
        'Moose'                     => '0.57',
        'MooseX::App::Cmd'          => '0.09',
        'MooseX::ConfigFromFile'    => 0,
        'MooseX::Getopt'            => 0,
        'MooseX::Types'             => '0.21',
        'RPM2'                      => 0,
        'Readonly'                  => 0,
        'UNIVERSAL::require'        => 0,
        'YAML::Syck'                => 0,
        'perl'                      => '5.8.8',
    },
    build_requires => {
        'Test::More'        => '0.87',
        'Test::Exception'   => 0,
        'Test::File'        => '1.24',
    },
    conf_files => \%conf_files,
    doc_files  => \%doc_files,
    install_path => {
        conf => '/etc/pkgforge',
        doc  => '/usr/share/pkgforge/doc/',
    },
    add_to_cleanup => [ 'MANIFEST.bak', 'ChangeLog.bak' ],
    create_makefile_pl => 'traditional',
);
$build->add_build_element('conf');
$build->add_build_element('doc');
$build->create_build_script;
