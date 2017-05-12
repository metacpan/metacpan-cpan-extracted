use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Net::TrackUPS',
    VERSION_FROM    => 'lib/Net/TrackUPS.pm',
    PREREQ_PM       => {
                        'HTTP::Request'         => 0,
                        'LWP::UserAgent'        => 0,
                        'XML::Simple'           => 0,
    },
);
