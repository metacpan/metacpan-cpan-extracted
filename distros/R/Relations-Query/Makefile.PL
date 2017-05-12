use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Relations::Query',
  'VERSION_FROM' => 'Query.pm', 
  ($] ge '5.005') ? 
  (
    'AUTHOR'   => 'George A. Fitch III (aka Gaffer), gaf3@gaf3.com',
    'ABSTRACT' => 'Object for creating SQL queries',
  ) : (),
  'PREREQ_PM' => 
  { 
    'Relations'  => 0.94
  },
  'PM' => {
     'Query.pm' => '$(INST_LIBDIR)/Query.pm'
  }
);

