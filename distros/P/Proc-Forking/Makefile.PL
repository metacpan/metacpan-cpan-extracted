use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
        VERSION_FROM     => 'Forking.pm',
        NAME    => 'Proc::Forking',
	ABSTRACT       => 'Proc::Forking - fork a function and daemonize the parent',
        dist => { COMPRESS=>"gzip -f", SUFFIX=>"gz" },
	PREREQ_PM      => {@extra_prereq,qw(
                    POSIX      0
                    IO::File   0
                    Sys::Load  0
		    Sys::Prctl 0
                    Cwd        0
                   )},

        );

