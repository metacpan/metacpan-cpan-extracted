use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Spreadsheet::WriteExcel::Extended::FitColumnWidth',
    AUTHOR              => q{Greg George <gng@cpan.org>},
    VERSION_FROM        => 'lib/Spreadsheet/WriteExcel/Extended/FitColumnWidth.pm',
    ABSTRACT_FROM       => 'lib/Spreadsheet/WriteExcel/Extended/FitColumnWidth.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'              => 0,
        'Spreadsheet::WriteExcel' => 2.37,
        'Font::TTFMetrics'        => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Spreadsheet-WriteExcel-Extended-FitColumnWidth-*' },
);
