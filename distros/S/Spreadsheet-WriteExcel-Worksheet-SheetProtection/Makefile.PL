use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Spreadsheet::WriteExcel::Worksheet::SheetProtection',
    VERSION_FROM      => 'SheetProtection.pm', # finds $VERSION
    PREREQ_PM         => {Spreadsheet::WriteExcel => 2.02},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'SheetProtection.pm', # retrieve abstract from module
       AUTHOR         => 'Stepan Riha <sriha@cpan.org>') : ()),
);
