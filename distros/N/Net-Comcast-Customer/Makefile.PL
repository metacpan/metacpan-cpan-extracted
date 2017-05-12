use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Comcast::Customer',
    AUTHOR              => q{Ken Dreyer <ktdreyer@ktdreyer.com>},
    VERSION_FROM        => 'lib/Net/Comcast/Customer.pm',
    ABSTRACT_FROM       => 'lib/Net/Comcast/Customer.pm',
    EXE_FILES           => [ 'bin/comcast-data' ],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        'META_MERGE' => {
            resources => {
                license        => 'http://dev.perl.org/licenses/',
                homepage       => 'http://www.ktdreyer.com',
                repository     => 'https://gitorious.org/ktdreyer/net-comcast-customer',
            },
        } ) : ()
    ),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'WWW::Mechanize' => 0,
        'Date::Calc'     => 0,
        'Net::Netrc'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Comcast-Customer-*' },
);
