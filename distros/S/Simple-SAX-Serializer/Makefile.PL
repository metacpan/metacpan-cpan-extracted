
use ExtUtils::MakeMaker;
use 5.006;

WriteMakefile(
    NAME         => 'Simple::SAX::Serializer',
    VERSION_FROM => 'lib/Simple/SAX/Serializer.pm',
    DISTNAME     => 'Simple-SAX-Serializer',
    PREREQ_PM    => { 
        'Abstract::Meta::Class'   => 0,
	'XML::SAX'  		  => 0,
	'Carp'			  => 0,
        'Test::Pod'               => 0,
        'Test::Pod::Coverage'     => 0,
    },
    test	 => { TESTS => 't/*.t t/xml/*.t'},
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'MANIFEST.bak' },
);
