use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME         => 'SSH::Command',
    AUTHOR       => 'NRG <pavel.odintsov@googlemail.com>',
    LICENSE      => 'perl',
    ABSTRACT     => 'SSH::Command - interface to execute multiple commands on host by SSH protocol',
    VERSION_FROM => 'lib/SSH/Command.pm',
    PREREQ_PM    => {
                        'Carp'               => '0',
                        'Data::Dumper'       => '0',
                        'Getopt::Long'       => '0',
                        'Test::More'         => '0',
                        'Test::LongString'   => '0',
                        'Net::SSH2'          => '0',
                        'Scope::Guard'       => '0',
                        'File::Temp'         => '0',
                        'Exporter::Lite'     => '0',
                    },
    INSTALLDIRS  => 'site',
    EXE_FILES    => [],
    PL_FILES     => {}
);

