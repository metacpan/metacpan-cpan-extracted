use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
	       'NAME'	       =>  'Persistence::Object::Postgres',
	       'VERSION_FROM'  =>  'Postgres.pm',
	       'ABSTRACT'      =>  'Object Persistence with PostgreSQL.',
	       'PREREQ_PM'     =>  {
				    'DBI'          =>  0,
				    'Data::Dumper' =>  0,
				   },
	      );

