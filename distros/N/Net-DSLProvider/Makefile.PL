use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::DSLProvider',
    AUTHOR              => q{Jason Clifford <jason@ukfsn.org>, Simon Cozens <simon@simon-cozens.org>},
    VERSION_FROM        => 'lib/Net/DSLProvider.pm',
    ABSTRACT_FROM       => 'lib/Net/DSLProvider.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::Accessor' => 0,
        'SOAP::Lite'    => 0,
        'HTML::Entities' => 0,
        'LWP' => 0,
        'HTTP::Cookies' => 0,
        'HTML::Entities' => 0,
        'XML::Simple' => 0,
        'Time::Piece' => 0,
        'Time::Seconds' => 0,
        'Date::Holidays::EnglandWales' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-DSLProvider-*' },
);
