use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'		=> 'Net::DNS::TestNS',
	      'VERSION'	        => '1.10', # finds $VERSION
	      'PREREQ_PM'		=> {
		  Net::DNS => 0.64,
		  IO::File => 1.09,
		  XML::LibXML => 1.53,
		}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'TestNS.pm', # retrieve abstract from module
		AUTHOR     => 'Olaf Kolkman <olaf@ripe.net>') : ()),
	      'PM' => { 
		  'TestNS.pm'    => '$(INST_LIBDIR)/TestNS.pm',
		  'TestNS/DTD.pm'    => '$(INST_LIBDIR)/TestNS/DTD.pm',
		  'TestNS/Nameserver.pm'    => '$(INST_LIBDIR)/TestNS/Nameserver.pm',		  'TestNS/Packet.pm'    => '$(INST_LIBDIR)/TestNS/Packet.pm',
	      },

	      );



package MY;
sub postamble {
    if ( ! -r 'TestNS/DTD.pm' ){
	open (FH,'> TestNS/DTD.pm') || die "Please create TestNS/DTD.pm";
	print FH "# Empty file created during make process. Contact maintainer";
	close (FH);

    }

    my $content= '
TestNS/DTD.pm: TestNS.pm Makefile generateDTDpod.pl
	$(PERLRUN) generateDTDpod.pl > TestNS/DTD.pm


config:: $(FIRST_MAKEFILE) TestNS/DTD.pm pm_to_blib
	$(NOECHO) $(NOOP)


';
    return $content;
    

}
