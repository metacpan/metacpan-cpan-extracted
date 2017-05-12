use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Template::ClearSilver::I18N',
    AUTHOR              => 'syushi matsumoto <matsumoto@alink.co.jp>',
    VERSION_FROM        => 'lib/Sledge/Template/ClearSilver/I18N.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Template/ClearSilver/I18N.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'ClearSilver' => 0,
        'Sledge::Template::ClearSilver' => 0,
        'Sledge::Request::Apache::I18N' => 0,
        'Sledge::Pages::Apache::I18N' => 0,
        'Sledge::Charset::UTF8::I18N' => 0,
        'Encode' => 1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Template-ClearSilver-I18N-*' },
);
