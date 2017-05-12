use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME               => 'Monitoring::Icinga',
    VERSION_FROM       => 'lib/Monitoring/Icinga.pm', # finds $VERSION
    PREREQ_PM          => {
        'Carp'                  => 0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent'        => 0,
        'JSON::XS'              => 0,
    },
    ($] >= 5.005 ?    # Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'lib/Monitoring/Icinga.pm', # retrieve abstract from module
         AUTHOR        => 'Robin Schroeder <schrorg@cpan.org>') : ()),
);
