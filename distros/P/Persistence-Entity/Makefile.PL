
use ExtUtils::MakeMaker;
use 5.006;

WriteMakefile(
    NAME         => 'Persistence::Entity',
    VERSION_FROM => 'lib/Persistence/Entity.pm',
    DISTNAME     => 'Persistence-Entity',
    PREREQ_PM    => { 
        'Abstract::Meta::Class'   => 0.10,
        'SQL::Entity'             => 0.05,
	'DBIx::Connection'        => 0.06,
	'Simple::SAX::Serializer' => 0.04,
        'Test::DBUnit'		  => 0.07,
	'Test::Pod'		  => 0,
	'Test::Pod::Coverage'	  => 0,
        'Carp'                    => 0,
	'Storable'		  => 0,
    },
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'MANIFEST.bak' },
    test	 => { TESTS => 't/*.t t/entity/*.t t/value_generator/*.t t/relationship/*.t t/meta/*.t'},
);
