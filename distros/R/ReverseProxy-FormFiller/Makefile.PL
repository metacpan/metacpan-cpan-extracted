use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ReverseProxy::FormFiller',
    AUTHOR              => q{FX Deltombe <fxdeltombe@gmail.com>},
    VERSION_FROM        => 'lib/ReverseProxy/FormFiller.pm',
    ABSTRACT_FROM       => 'lib/ReverseProxy/FormFiller.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Apache2::Filter'      => 0,
        'Apache2::Const'       => 0,
        'Apache2::RequestUtil' => 0,
        'Apache2::RequestRec'  => 0,
        'Apache2::Response'    => 0,
        'Apache2::Log'         => 0,
        'URI::Escape'          => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ReverseProxy-FormFiller-*' },
);
