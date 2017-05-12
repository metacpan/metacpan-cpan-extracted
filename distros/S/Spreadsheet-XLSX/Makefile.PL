use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Spreadsheet::XLSX',
    VERSION_FROM      => 'lib/Spreadsheet/XLSX.pm', # finds $VERSION
    LICENSE           => 'perl_5',
    PREREQ_PM         => {
	'Archive::Zip' => 1.18,
	'Spreadsheet::ParseExcel' => 0,
    'Test::NoWarnings' => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Spreadsheet/XLSX.pm', # retrieve abstract from module
       AUTHOR         => ['Dmitry Ovsyanko <do@eludia.ru>','Mike Blackwell <mike.blackwell@rrd.com']) : ()),
);
