# $Id: Makefile.PL,v 1.5 2005/04/27 10:01:32 mike Exp $

use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Z3950::RadioMARC',
    VERSION_FROM      => 'lib/Net/Z3950/RadioMARC.pm', # finds $VERSION
    PREREQ_PM         => { Net::Z3950 => 0.46,
			   Net::Z3950::PQF => 0.03 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Z3950/RadioMARC.pm',
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),
);

# This forces etc/trunc.marc to get built (I hope)
sub MY::postamble {
    'subdirs :: etc/Makefile
	cd etc && $(MAKE) INC=$(PASTHRU_INC) $(PASTHRU)';
}
