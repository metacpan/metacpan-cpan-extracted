use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Spreadsheet::BasicReadNamedCol',
    'VERSION_FROM'	=> 'BasicReadNamedCol.pm', # finds $VERSION
    'PREREQ_PM'		=> {
							'Spreadsheet::ParseExcel' => 0.26,
							'Spreadsheet::BasicRead'  => 1.07
					   },
    'NEEDS_LINKING' => 0,
    ($] >= 5.005 ?    												## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'BasicReadNamedCol.pm', 					# retrieve abstract from module
       AUTHOR     => 'Greg George, IT Technology Solutions P/L, Australia, gng@cpan.org') : ()),
);
