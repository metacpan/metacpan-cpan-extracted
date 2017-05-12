#$Id$

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Sman',
	'EXE_FILES' => [ qw( script/sman script/sman-update ) ],	 # these go to their perl bin dir
    'VERSION_FROM'	=> 'Sman/Util.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
                        SWISH::API => 0.03, 
							# above had been commented out because
							# on FC1 'perl Makefile.PL' complained
							# Can't locate auto/SWISH/API/VERSION.al  if we leave it in!
						Compress::Zlib => 0.00, 
						File::Find => 0.00, 
						File::Temp => 0.00, 
						FindBin => 0.00, 
						FreezeThaw => 0.00,
						Term::Size => 0.00, 
						Cache::Cache => 0.00,
						Digest::MD5 => 0.00,
						Cache::FileCache => 0.00,
						Storable => 0.00,
						POSIX => 0.00,
                        IPC::Run => 0.00,   # used in Sman::Man::Convert
                        version => 0.00,
					},
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		( ABSTRACT_FROM => 'Sman.pm', # retrieve abstract from module
		AUTHOR     => 'Josh Rabinowitz') : ()),
);


package MY; 
# a 'make' snippet to be appended to the Makefile
sub postamble {
	my $install =  "install ::\n" .
        #"\tmkdir -p /usr/local/etc\n" . 
		"\tmkdir -p \$(DESTDIR)/etc\n" . 
		"\tmkdir -p \$(DESTDIR)/var/lib/sman\n" . 
		"\tcp sman-defaults.conf \$(DESTDIR)/etc/\n" .
		"\t" . '@echo "NOTE: sman and sman-update have been installed in $(INSTALLBIN)"' . "\n" . 
		"\t" . '@echo "NOTE: the default sman configuration file is /usr/local/etc/sman-defaults.conf."' . "\n" . 
		"\t" . '@echo "NOTE: sman-update should be run periodically to keep the sman index up to date."' . "\n\n";

	my $hello = "hello ::\n" . 
		"\t" . '@echo "sman and sman-update have been installed in $(INSTALLBIN)"' . "\n" .
		pquote("print qq{hello, world.\n};") . "\n\n";

	return "$install\n\n$hello\n\n";
}


# this takes a one-liner of perl code and preps 
# it for insertion in a Makefile
sub pquote {
	my $p = shift;
	$p =~ s/\n/\\n/;
	$p =~ s/\t/\\t/;
	$p =~ s/"/\"/g;
	return "\t" . q{@$(PERL) -e } . qq{"$p"};
}

