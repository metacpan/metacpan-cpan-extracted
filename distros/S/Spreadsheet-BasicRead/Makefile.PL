use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'Spreadsheet::BasicRead',
    'VERSION_FROM'  => 'BasicRead.pm', # finds $VERSION
    'PREREQ_PM'     => {
        Spreadsheet::ParseExcel => 0.26,
        Spreadsheet::XLSX => 0.13,
        utf8 => 1.09,
        },
    'NEEDS_LINKING' => 0,
    'EXE_FILES'     => [ qw(xlsgrep.pl dumpSS.pl) ],
#    'HTMLSCRIPTPODS' => { 'xlsgrep.pl' => 'xlsgrep.html',},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'BasicRead.pm', # retrieve abstract from module
       AUTHOR     => 'Greg George, IT Technology Solutions P/L, Australia, gng@cpan.org') : ()),
);
