use strict;
use warnings;
use Module::Build;

my %compat_prereqs;

if ($] < 5.012) {
    $compat_prereqs{Socket6} = 0;
}


my $builder = Module::Build->new(
    module_name         => 'RackMan',
    license             => 'gpl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/RackMan.pm',
    script_files        => [
        'bin/rack', 'bin/cfengine-tags', 'bin/cisco-status',
        'bin/racktables-check'
    ],

    requires => {
        'Algorithm::Diff'               => 0,
        'Carp'                          => 0,
        'Config::IniFiles'              => 0,
        'Cwd'                           => 0,
        'DBD::mysql'                    => 0,
        'DBIx::Class'                   => 0,
        'DBIx::Class::Schema::Loader'   => 0,
        'Exporter'                      => 0,
        'File::Basename'                => 0,
        'File::Path',                   => 0,
        'File::Temp',                   => 0,
        'Getopt::Long'                  => 0,
        'HTML::Template'                => '2.0',
        'HTML::Template::Filter::TT2'   => '0.03',
        'IPC::Run',                     => 0,
        'JSON',                         => 0,
        'JSON::XS',                     => 0,
        'List::MoreUtils',              => 0,
        'Moose'                         => '1.00',
        'MooseX::NonMoose'              => 0,
        'namespace::autoclean'          => 0,
        'NetAddr::IP'                   => '4.000',
        'Net::FTP',                     => 0,
        'Net::ILO',                     => "0.54",
        'Net::SNMP',                    => 0,
        'Net::Telnet::Cisco',           => 0,
        'Path::Class'                   => 0,
        'Socket'                        => 0,
        'Term::ANSIColor'               => 0,
        'YAML',                         => 0,
        'YAML::XS',                     => 0,
        %compat_prereqs,
    },
    build_requires => {
        'Test::More'                    => '0.45',
    },
    add_to_cleanup      => [ 'RackMan-*' ],
);

$builder->create_build_script();

