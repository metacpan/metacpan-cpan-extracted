use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
	       'NAME'	      =>  'Persistence::Database::SQL',
	       'VERSION_FROM'  =>  'SQL.pm',
	       'PREREQ_PM'     =>  {
				    'Persistence::Object::Postgres'  =>  0,
				   },
	      );

