use strict;
use warnings;
use ExtUtils::MakeMaker;

my %compat_prereqs;

if ($] < 5.012) {
    $compat_prereqs{Socket6} = 0;
}

WriteMakefile(
    NAME                => 'RackMan',
    LICENSE             => 'gpl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/RackMan.pm',
    ABSTRACT_FROM       => 'lib/RackMan.pm',
    EXE_FILES           => [
        'bin/rack', 'bin/cfengine-tags', 'bin/cisco-status',
        'bin/racktables-check'
    ],
    PREREQ_PM => {
        # prereqs
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

        # build/test prereqs
        'Test::More'                    => '0.45',
    },
    postamble           => {
        files           => {
            'etc/rack.conf' => '$(PREFIX)/etc/rack.sample.conf',
        },
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'RackMan-*' },
);


sub MY::postamble {
    my ($mm, %args) = @_;
    my $postamble = "";

    # install data files (in /etc, /usr/share, ...)
    # first, we must add a target in install::
    for my $makeline (@{ $mm->{RESULT} }) {
        $makeline =~ s/(install *::.+)\n/$1 priv_data_files\n/;
    }

    # then, declare the target with the files
    $postamble .= "\nINSTALL = install -d -p\n\npriv_data_files:\n";

    while (my($file,$target) = each %{ $args{files} }) {
        $postamble .= "\t\$(INSTALL) $file $target\n";
    }

    return $postamble
}

