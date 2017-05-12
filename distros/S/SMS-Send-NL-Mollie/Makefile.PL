use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SMS::Send::NL::Mollie',
    VERSION_FROM => 'lib/SMS/Send/NL/Mollie.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'SMS::Send driver for www.mollie.nl',
    PREREQ_PM    => {
                     'Test::More'       => 0.47,
                     'SMS::Send'        => 0,
                     'Net::SMS::Mollie' => 0,
                     'Carp'             => 0,
                    },
);
