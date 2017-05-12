
use ExtUtils::MakeMaker;

  
WriteMakefile(
    NAME         => 'SQL::Entity',
    VERSION_FROM => 'lib/SQL/Entity.pm',
    DISTNAME     => 'SQL-Entity',
    PREREQ_PM    => { 
        'Abstract::Meta::Class'   => 0,
	'Storable'                => 0,
    },
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'MANIFEST.bak' },
    test	 => { TESTS => 't/*.t t/entity/*.t'},
);
