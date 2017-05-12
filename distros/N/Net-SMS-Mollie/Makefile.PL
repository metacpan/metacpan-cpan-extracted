use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::SMS::Mollie',
    VERSION_FROM => 'lib/Net/SMS/Mollie.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'Send SMS messages via the mollie.nl service',
    PREREQ_PM    => {
                     'Test::Simple'     => 0.44,
                     'LWP::UserAgent'   => 0,
                     'XML::Simple'      => 0,
                    },
);
