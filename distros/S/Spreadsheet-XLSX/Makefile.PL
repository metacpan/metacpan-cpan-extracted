use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Spreadsheet::XLSX',
    VERSION_FROM      => 'lib/Spreadsheet/XLSX.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/Spreadsheet/XLSX.pm', # retrieve abstract from module
    AUTHOR            => ['Dmitry Ovsyanko <do@eludia.ru>', 'Mike Blackwell <mike.blackwell@rrd.com'],
    LICENSE           => 'perl_5',
    PREREQ_PM         => {
        'Archive::Zip' => 1.18,
        'Spreadsheet::ParseExcel' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Warnings' => 0,
        'Test::NoWarnings' => 0,
    },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/Spreadsheet-XLSX',
        },
    },
);
