use 5.005;
use ExtUtils::MakeMaker;
WriteMakefile(
    'PL_FILES'     => {},
    'INSTALLDIRS'  => 'site',
    'NAME'         => 'Nagios::Scrape',
    'EXE_FILES'    => [],
    'VERSION_FROM' => 'lib/Nagios/Scrape.pm',
    'ABSTRACT_FROM' => 'lib/Nagios/Scrape.pm',
    'AUTHOR'        => 'David Precious <davidp@preshweb.co.uk>',
    'LICENSE'       => 'GPL_3',
    'PREREQ_PM'    => {
        'Test::More'      => 0,
        'Error'           => 0,
        'Test::Exception' => 0,
        'LWP::UserAgent'  => 0,
        'CGI'             => 0
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/bigpresh/Nagios-Scrape',
            bugtracker => 'https://github.com/bigpresh/Nagios-Scrape/issues',
            homepage   => 'https://github.com/bigpresh/Nagios-Scrape',
        },
    },
);
