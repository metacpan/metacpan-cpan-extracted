use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sphinx::Search',
    AUTHOR              => 'Jon Schutz <jon@jschutz.net>',
    VERSION_FROM        => 'lib/Sphinx/Search.pm',
    ABSTRACT_FROM       => 'lib/Sphinx/Search.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'File::SearchPath' => 0,
	'Path::Class' => 0,
	'Carp' => 0,
	'Socket' => 0,
	'DBI' => 0,
	'Math::BigInt' => 0,
	'Config' => 0,
	'Errno' => 0,
	'Fcntl' => 0,
	'Class::Accessor::Fast' => 0,
	'Data::Dumper' => 0,
	'Encode' => 0,
        'List::MoreUtils' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sphinx-Search-*' },
);
