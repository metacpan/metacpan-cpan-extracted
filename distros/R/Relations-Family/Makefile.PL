use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Relations::Family',
  'VERSION_FROM' => 'Family.pm', 
  ($] ge '5.005') ? 
  (
    'AUTHOR'   => 'George A. Fitch III (aka Gaffer), gaf3@gaf3.com',
    'ABSTRACT' => 'DBI/DBD::mysql relational query engine object.',
  ) : (),
  'PREREQ_PM' => 
  { 
    'DBI'                 => 1.13,
    'DBD::mysql'          => 1.18,
    'Relations'           => 0.94,
    'Relations::Query'    => 0.93,
    'Relations::Abstract' => 0.94
  },
  'PM' => {
     'Family.pm'         => '$(INST_LIBDIR)/Family.pm',
     'Family/Member.pm'  => '$(INST_LIBDIR)/Family/Member.pm',
     'Family/Lineage.pm' => '$(INST_LIBDIR)/Family/Lineage.pm',
     'Family/Rivalry.pm' => '$(INST_LIBDIR)/Family/Rivalry.pm',
     'Family/Value.pm'   => '$(INST_LIBDIR)/Family/Value.pm'
  }
);

