use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rose::DBx::Object::Metadata::Column::Xml',
    AUTHOR              => q{Andrey Chergik <andrey@chergik.ru>},
    VERSION_FROM        => 'lib/Rose/DBx/Object/Metadata/Column/Xml.pm',
    ABSTRACT_FROM       => 'lib/Rose/DBx/Object/Metadata/Column/Xml.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Rose::DB::Object::Metadata::Column::Text' => 0,
	'DBD::Oracle' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-DBx-Object-Metadata-Column-Xml-*' },
);
