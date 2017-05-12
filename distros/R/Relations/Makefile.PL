use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Relations',
  'VERSION_FROM' => 'Relations.pm', 
  ($] ge '5.005') ? 
  (
    'AUTHOR'   => 'George A. Fitch III (aka Gaffer), gaf3@gaf3.com',
    'ABSTRACT' => 'Functions to Use with Databases and Queries',
  ) : (),
  'PREREQ_PM' => 
  { 
  },
  'PM' => {
     'Relations.pm' => '$(INST_LIBDIR)/Relations.pm'
  }
);