use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sphinx::Manager',
    AUTHOR              => 'Jon Schutz <jon@jschutz.net>',
    VERSION_FROM        => 'lib/Sphinx/Manager.pm',
    ABSTRACT_FROM       => 'lib/Sphinx/Manager.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Carp' => 0,
	'FindBin' => 0,
	'Path::Class' => 0,
	'Proc::ProcessTable' => 0,
	'File::Spec' => 0,
	'Sphinx::Config' => '0.09',
	'Class::Accessor::Fast' => 0,
        'POSIX' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sphinx-Manager-*' },
);
