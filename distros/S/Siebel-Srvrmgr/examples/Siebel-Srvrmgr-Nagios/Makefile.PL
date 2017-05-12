use 5.008009;
use ExtUtils::MakeMaker;
use warnings;
use strict;

WriteMakefile(
    NAME         => 'Siebel::Srvrmgr::Nagios',
    VERSION_FROM => 'lib/Siebel/Srvrmgr/Nagios.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Nagios::Plugin'  => 0.36,
        'XML::Rabbit'     => 0.30,
        'Siebel::Srvrmgr' => 0.15
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Siebel/Srvrmgr/Nagios.pm',    # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arreitas@cpan.org>'
          )
        : ()
    ),
    BUILD_REQUIRES => {
        'Test::Pod'           => 1.22,
        'Test::Pod::Coverage' => 1.08,
        'Test::Output'        => 1.03
    },
    EXE_FILES => [ 'comp_mon.pl', 'task_mon.pl' ],
    NO_MYMETA => 1
);
