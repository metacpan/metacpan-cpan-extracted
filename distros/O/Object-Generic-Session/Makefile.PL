use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Object::Generic::Session',
    AUTHOR              => 'Jim Mahoney <mahoney@marlboro.edu>',
    VERSION_FROM        => 'lib/Object/Generic/Session.pm',
    ABSTRACT_FROM       => 'lib/Object/Generic/Session.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
	'Object::Generic' => 0,
	'Apache::Cookie'  => 0,
	'Session'         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Object-Generic-Session-*' },
);
