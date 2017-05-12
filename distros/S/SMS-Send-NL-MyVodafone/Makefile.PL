use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SMS::Send::NL::MyVodafone',
    VERSION_FROM => 'lib/SMS/Send/NL/MyVodafone.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'An SMS::Send driver for the my.vodafone.nl website',
    PREREQ_PM    => {
                     'SMS::Send'        => 0.02,
                     'Test::Simple'     => 0.44,
                     'WWW::Mechanize'   => 0,
                    },
);
