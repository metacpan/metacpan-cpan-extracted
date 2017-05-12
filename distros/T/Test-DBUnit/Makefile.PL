
use ExtUtils::MakeMaker;
use 5.006;

WriteMakefile(
    NAME         => 'Test::DBUnit',
    VERSION_FROM => 'lib/Test/DBUnit.pm',
    DISTNAME     => 'Test-DBUnit',
    PREREQ_PM    => {
        'Abstract::Meta::Class'   => 0,
	'DBIx::Connection'        => 0.13,
	'XML::SAX'		  => 0,
	'Simple::SAX::Serializer' => 0.05,
	'IO::File'		  => 0,
        'XML::Writer'		  => 0,
        'Data::Dumper'		  => 0,
        'Test::Pod'               => 0,
        'Test::Pod::Coverage'     => 0,
        'Sub::Uplevel'            => 0,
        'Test::Builder'           => 0,
    },
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'MANIFEST.bak' },
);
