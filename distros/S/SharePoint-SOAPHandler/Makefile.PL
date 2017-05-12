use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if(open my $config_fh, ">", "test.config") {

	print <<EOP;

Please Note:

For 'make test' to run properly, you must provide login credentials
for your working sharepoint server, and have enough privileges to 
create and delete files and dirs under your Shared Documents
dir.

I do apologize for the need of interaction for my tests, but unless you have 
a real connection, I cannot test the functions with my script, as my functions
call objects from the sharepoint server that are black boxes to me.

sleeping for 5 seconds..

EOP

	sleep 5;
	my $network_tests = prompt "Do you want to run the live tests [y/N]? ", "N";
	print $config_fh "live_tests ", ( $network_tests =~ /y/i ? 1 : 0), "\n";
}



WriteMakefile(
    NAME              => 'SharePoint::SOAPHandler',
    VERSION_FROM      => 'lib/SharePoint/SOAPHandler.pm', # finds $VERSION
    PREREQ_PM         => {Authen::NTLM =>1.09, CopyTree::VendorProof => 0, SOAP::Lite =>0, MIME::Base64=>0, File::Basename=> 0, Data::Dumper=> 0, Carp=>0, Term::ReadKey=>0}, # e.g., Module::Name => 1.1
    #PREREQ_PM         => {Authen::NTLM =>1.09, CopyTree::VendorProof => 0.0011, SOAP::Lite =>0.712, MIME::Base64=>3.01, File::Basename=> 2.72, Data::Dumper=> 2.121, Carp=>1.02}, # e.g., Module::Name => 1.1
    clean => {
        FILES => 'test.config'
    },
	
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SharePoint/SOAPHandler.pm', # retrieve abstract from module
       AUTHOR         => 'dbmolester de gmail.com') : ()),
);

