use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::MyOpera',
    AUTHOR              => q{Cosimo Streppone <cosimo@opera.com>},
    VERSION_FROM        => 'lib/Net/MyOpera.pm',
    ABSTRACT_FROM       => 'lib/Net/MyOpera.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'CGI' => 0,
        'Net::OAuth' => '0.25',
        'LWP::UserAgent' => 0,
        'Test::More' => 0,
        'URI' => 0,
        'URI::Escape' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-MyOpera-*' },
);
