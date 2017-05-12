use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# optional stuff
my %opts = (
	    XML::SAX => "RDF::Notation3::SAX class can't be used",
	    RDF::Core => "RDF::Notation3::RDFCore class can't be used",
	    RDFStore => "RDF::Notation3::RDFStore class can't be used",
	   );

foreach (keys %opts) {

    my $try = "require $_;";
    eval $try;
    if ($@) {
	print "$_ not found!\n";
	print "RDF::Notation3 will be installed with the following limitation:\n";
	print "=> $opts{$_}!\n";
	print "Install $_ from CPAN to get this functionality.\n\n";
    } else {
	print "$_ found...\n";
    }
}

WriteMakefile(
    'NAME'		=> 'RDF::Notation3',
    'VERSION_FROM'	=> 'lib/RDF/Notation3.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
     dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
