use ExtUtils::MakeMaker;
use English;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


$abstract = "Simple printer support for window and linux/unix";


WriteMakefile(
	      NAME	   => 'Printer',
	      VERSION_FROM => 'lib/Printer.pm',
	      PREREQ_PM    => {},
	      PM           => {'lib/Printer.pm'
				   => '$(INST_LIBDIR)/Printer.pm',
			       'lib/Printer/Unix.pm',
			           => '$(INST_LIBDIR)/Printer/Unix.pm',
			       'lib/Printer/Win32.pm'
			           => '$(INST_LIBDIR)/Printer/Win32.pm',
			       },
	      ($] >= 5.005 ?
	       (ABSTRACT => $abstract,
		AUTHOR     => 'Stephen Patterson <steve@patter.mine.nu>') :())
	      );
