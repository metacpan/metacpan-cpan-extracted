use ExtUtils::MakeMaker;

if ($^O eq 'MSWin32')
{
  $smspath = 'lib\\Net\\SMS.pm';
}
else
{
  $smspath = 'lib/Net/SMS.pm';  
}


WriteMakefile(
    NAME	=> 'Net::SMS',
    DISTNAME => 'Net-SMS',
    VERSION_FROM => $smspath,
    PREREQ_PM => {
    		'XML::DOM'		=> "1.25",
			'Unicode::String'	=> "2.06",
			'LWP::UserAgent'	=> 0,
			'HTTP::Request'	=> 0,
			'HTTP::Response'	=> 0},
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
	($] ge '5.005') ? (
        'AUTHOR' => 'Simplewire, Inc. (support@simplewire.com)',
        'ABSTRACT' => 'Perl module that can send wireless messages like SMS (Short Message Service) and Smart Messages (logos, ringtones, etc.).',
    ) : (),
);

print "\nPerl SMS Software Development Kit\n";
print "----------------------------------------------------------------\n";
print "Thank you for installing the Simplewire Perl SMS Software\n";
print "Development Kit. The Perl SMS Software Development Kit connects your\n";
print "application to, and works in conjunction with, the Simplewire\n";
print "Wireless Messaging Network. This network is the conduit through\n";
print "which customers are able to reach wireless users throughout the\n";
print "world. One may view the hundreds of networks to which you may\n";
print "send messages via Simplewire at http://coverage.simplewire.com/.\n";
print "\n";
print "Sales and Technical Support\n";
print "----------------------------------------------------------------\n";
print "Technical support is offered for both developers and commercial\n";
print "users. One may submit problems, bug reports, incompatibilities,\n";
print "requests for change, or other comments at\n";
print "http://support.simplewire.com/.\n";
print "\n";
print "Sales support is offered for users interested in purchasing a\n";
print "commercial license or to answer any questions about Simplewire's\n";
print "products and services.  Submit sales inquiries to the Sales Team\n";
print "at http://www.simplewire.com/contact/sales/.\n";
print "\n";
print "Makefile has been written.  Now run 'make' or 'nmake' if you are\n";
print "on Windows.\n\n";
