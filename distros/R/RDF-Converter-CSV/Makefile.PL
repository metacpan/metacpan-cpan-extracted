use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'RDF::Converter::CSV',
    AUTHOR              => 'Arshad Mohamed <arshad25@gmail.com>',
    VERSION_FROM        => 'lib/RDF/Converter/CSV.pm',
    ABSTRACT_FROM       => 'lib/RDF/Converter/CSV.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 		=> 0,
	'XML::Writer' 		=> '>= 1.2',
	'Class::Std::Utils'	=> '>=0.0.2',
	'Text::CSV' 		=> '1.10',
	'IO::File'			=> '1.09'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'RDF-Converter-CSV-*' },
);
