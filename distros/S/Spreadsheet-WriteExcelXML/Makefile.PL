#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
use strict;

require 5.005;

my %deps = (
    'Parse::RecDescent' => 0,
    'File::Temp'        => 0,
    'OLE::Storage_Lite' => 0.19,
);

my %resources = (
    repository  => 'http://github.com/jmcnamara/spreadsheet-writeexcelxml',
    MailingList => 'http://groups.google.com/group/spreadsheet-writeexcel',
);

my %params = (
    'AUTHOR'        => 'John McNamara (jmcnamara@cpan.org)',
    'ABSTRACT'      => 'Write an Excel XML file.',
    'NAME'          => 'Spreadsheet::WriteExcelXML',
    'VERSION_FROM'  => 'lib/Spreadsheet/WriteExcelXML.pm',
    'NEEDS_LINKING' => 0,
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    'LICENSE'       => 'perl',
    'PREREQ_PM'     => {},
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $params{META_MERGE} = { resources => \%resources };
}

WriteMakefile(%params);
