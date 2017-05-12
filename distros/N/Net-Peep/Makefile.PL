use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Peep',
    'VERSION'		=> '0.4.5.1', # VERSION_FROM seems to break 5.00503
    'PREREQ_PM'		=> { 
      File::Tail => 0.98,
      Time::HiRes => 1.20,
      Net::Ping::External => 0.06,
      Filesys::DiskFree => 0.06,
      Proc::ProcessTable => 0.32
      },
    'PM'                => {
                            'Peep.pm' => '$(INST_LIB)/Net/Peep.pm', 
                            'bin/peck' => '$(INST_SCRIPT)/peck',
                            'bin/logparser' => '$(INST_SCRIPT)/logparser',
                            'bin/sysmonitor' => '$(INST_SCRIPT)/sysmonitor',
                            'bin/keytest' => '$(INST_SCRIPT)/keytest',
                            'bin/pinger' => '$(INST_SCRIPT)/pinger'
                           },
     ($] >= 5.005 ?
         ('ABSTRACT' => 'Client modules for Peep:  The Network Auralizer',
          'AUTHOR'   => 'Michael Gilfix <mgilfix@eecs.tufts.edu>') : ()),

);
