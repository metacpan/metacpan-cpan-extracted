use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Number::Object::Plugin::Tax::AU::GST',
    AUTHOR              => q{Matt Koscica <matt@qx.net.au>},
    VERSION_FROM        => 'lib/Number/Object/Plugin/Tax/AU/GST.pm',
    ABSTRACT_FROM       => 'lib/Number/Object/Plugin/Tax/AU/GST.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Number::Object' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Number::Object::Plugin::Tax::AU::GST-*' },
);
