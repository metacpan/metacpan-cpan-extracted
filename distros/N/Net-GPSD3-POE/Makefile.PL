use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::GPSD3::POE',
    VERSION_FROM => 'lib/Net/GPSD3/POE.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT_FROM=> 'lib/Net/GPSD3/POE.pm',
    PREREQ_PM    => {
                     'Test::Simple'             => 0.44,
                     'Net::GPSD3'               => 0.17,
                     'POE'                      => 0,
                     'POE::Session'             => 0,
                     'POE::Wheel::ReadWrite'    => 0,
                     'POE::Filter::Line'        => 0,
                     'POE::Kernel'              => 0,
                    },
    EXE_FILES    => [
                    qw{
                       scripts/perl-Net-GPSD3-POE-Example.pl
                      }
                    ],
);
