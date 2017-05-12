use 5.008;
use ExtUtils::MakeMaker;

use strict;
use warnings;

# See comment below on XPathContext
my $libxmlver;
eval {
    require "XML/LibXML.pm";
    $libxmlver = $XML::LibXML::VERSION;
};
# If the "require" failed, this will be diagnosed below, so ignore it now
if (!$@ && $libxmlver < "1.61") {
    eval {
	require "XML/LibXML/XPathContext.pm";
    }; if ($@) {
	die <<__EOT__;
You have a pre-1.61 version of XML::LibXML ($libxmlver) and no
installation of XML::LibXML::XPathContext.  You must either install
XPathContext from CPAN, or upgrade to a XML::LibXML 1.61 or later
(which includes XPathContext).
__EOT__
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Z3950::UDDI',
    VERSION_FROM      => 'lib/Net/Z3950/UDDI.pm', # finds $VERSION
    PREREQ_PM         => {
	'Net::Z3950::SimpleServer' => 1.07,
	'Exception::Class' => 1.23,
	'Net::Z3950::ZOOM' => 1.20,
		# ZOOM is used only for ZOOM::Exception, which is not
		# used by the underlying UDDI library but is required
		# by the Z39.50 gateway.
	'Data::Dumper' => 2.121,
	'YAML' => 0.62,
	'SOAP::Lite' => 0.69,
	      ### Do we still need SOAP::Lite?
	'HTML::Entities' => 1.35,
	'LWP::UserAgent' => 2.033,
	'XML::LibXML' => 1.59,
	'XML::LibXML::XPathContext' => 0.07,
    },
    EXE_FILES         => [ 'bin/z2uddi' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Z3950/UDDI.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@miketaylor.org.uk>') : ()),
);


sub MY::postamble { q[
POD =	lib/Net/Z3950/UDDI.pm \
	bin/z2uddi \
	lib/Net/Z3950/UDDI/Config.pm \
	lib/Net/Z3950/UDDI/Session.pm \
	lib/Net/Z3950/UDDI/Database.pm \
	lib/Net/Z3950/UDDI/ResultSet.pm \
	lib/UDDI/HalfDecent.pm \
	lib/UDDI/HalfDecent/ResultSet.pm \
	lib/UDDI/HalfDecent/Record.pm \
	bin/uddihd

z2uddi.pdf: bin/pod2pdf $(POD)
	bin/pod2pdf $(POD) > $@
];
}
