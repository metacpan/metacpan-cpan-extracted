use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Spreadsheet::WriteExcel::Simple::Save',
    'VERSION_FROM'	=> 'Save.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Spreadsheet::WriteExcel => '0.42',
			    File::Temp => '0.14',
			    Spreadsheet::ParseExcel => '0.26',
			    Spreadsheet::WriteExcel::Simple => '0.03'

}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Save.pm', # retrieve abstract from module
       AUTHOR     => 'T. M. Brannon <tbone@cpan.org>') : ()),
);
