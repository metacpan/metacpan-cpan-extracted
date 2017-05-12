use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Religion::Bible::Regex::Lexer',
    AUTHOR              => 'Daniel Holmlund <holmlund.dev@gmail.com>',
    LICENSE  		=> 'perl',
    VERSION_FROM        => 'lib/Religion/Bible/Regex/Lexer.pm',
    ABSTRACT_FROM       => 'lib/Religion/Bible/Regex/Lexer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Religion::Bible::Regex::Builder'   => 0,
        'Religion::Bible::Regex::Config'    => 0,
	'Religion::Bible::Regex::Reference' => 0, 
        'Test::More' => 0,
        'version'    => 0,
    },
    #'EXE_FILES'     => ['bin/SOAPsh.pl', 'bin/XMLRPCsh.pl', 'bin/stubmaker.pl'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Religion-Bible-Regex-Lexer-*' },
);
