use 5.14.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::OpenVPN::Agent',
    AUTHOR              => q{David Farrell <davidnmfarrell@gmail.com>},
    VERSION_FROM        => 'lib/Net/OpenVPN/Agent.pm',
    ABSTRACT_FROM       => 'lib/Net/OpenVPN/Agent.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                => 0,
        'Encode'                    => 0,
        'utf8'                      => 0,
        'Carp'                      => 0,
        'URI'                       => 0,
        'Net::OpenVPN::Launcher'    => 0.05,
        'HTTP::Tiny'                => 0,
        'HTTP::CookieJar'           => 0,
        'Test::Most'                => 0,
        'Log::Log4perl'         => 1.42,
        'YAML::XS'              => 0.41,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-OpenVPN-Agent*' },
);
