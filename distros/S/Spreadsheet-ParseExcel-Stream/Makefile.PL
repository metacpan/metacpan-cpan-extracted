use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Spreadsheet::ParseExcel::Stream',
    VERSION_FROM      => 'lib/Spreadsheet/ParseExcel/Stream.pm', # finds $VERSION
    PREREQ_PM         => {
      "Spreadsheet::ParseExcel" => 0,
      "Coro" => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Spreadsheet/ParseExcel/Stream.pm', # retrieve abstract from module
       AUTHOR         => 'Douglas Wilson <dougw@cpan.org>') : ()),
);
