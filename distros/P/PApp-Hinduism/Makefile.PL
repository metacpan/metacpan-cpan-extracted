use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PApp::Hinduism',
    'VERSION_FROM'	=> 'Hinduism.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    'PApp::SQL' => 0.131,
			    'DBIx::AnyDBD' => 2.0,
			    'DBIx::Connect' => 1.7,
			    'DBIx::Recordset' => 0.24,
			    'Text::Template' => 1.43
			   }, # e.g., Module::Name => 1.1
);
