use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Net::TrackIT',
    VERSION_FROM    => 'lib/Net/TrackIT.pm',
    PREREQ_PM       => {
                        'HTTP::Request'         => 0,
                        'LWP::UserAgent'        => 0,
                        'XML::Simple'           => 0,
    },
);
