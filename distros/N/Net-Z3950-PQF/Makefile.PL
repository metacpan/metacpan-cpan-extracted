# $Id: Makefile.PL,v 1.6 2007/11/27 22:19:51 mike Exp $

use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Z3950::PQF',
    'VERSION_FROM'	=> 'lib/Net/Z3950/PQF.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    clean => { FILES => "build-stamp install-stamp debian/files " .
			"debian/libnet-z3950-pqf-perl " .
			"debian/libnet-z3950-pqf-perl.substvars" },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Mike Taylor <mike@indexdata.com>') : ()),
);


sub MY::postamble { "debian: makemakerdflt
	dpkg-buildpackage -rfakeroot -d
	rm -rf debian/output
	mkdir debian/output
	mv ../libnet-z3950-pqf-perl* debian/output
";
}
                                              
