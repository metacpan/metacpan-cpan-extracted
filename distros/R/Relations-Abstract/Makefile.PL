use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Relations::Abstract',
  'VERSION_FROM' => 'Abstract.pm', 
  ($] ge '5.005') ? 
  (
    'AUTHOR'   => 'George A. Fitch III (aka Gaffer), gaf3@gaf3.com',
    'ABSTRACT' => 'DBI/DBD::mysql module to ease development',
  ) : (),
  'PREREQ_PM' => 
  { 
    'DBI'              => 1.13,
    'DBD::mysql'       => 1.18,
    'Relations'        => 0.94,
    'Relations::Query' => 0.93,
  },
  'PM' => {
     'Abstract.pm' => '$(INST_LIBDIR)/Abstract.pm'
  }
);