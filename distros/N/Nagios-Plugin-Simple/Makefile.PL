use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Nagios::Plugin::Simple',
    VERSION_FROM => 'lib/Nagios/Plugin/Simple.pm',
    AUTHOR       => 'Michael R. Davis (account=>perl,tld=>com,domain=>michaelrdavis)',
    ABSTRACT     => 'Simple and Minimalistic Nagios Plugin Package',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
