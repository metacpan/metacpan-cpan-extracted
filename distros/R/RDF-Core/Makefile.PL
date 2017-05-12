use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


my %required = (
		URI => 1.03,
		XML::Parser => 2.30, 
	       );
my %optional = (
		DBI => 1.14,
		DB_File => 1.72,
	       );
my %msg = (
	   URI => 'module for URI handling',
	   XML::Parser => 'Expat XML parser needed for RDF::Core::Parser',
	   DBI => 'module for a database connectivity (optional)',
	   DB_File => 'needed for Berkeley DB data storage',
	  );

my @missing_req = ();
my @missing_opt = ();
$| = 1;

sub get_dots {
    return '.' x (30 - length shift);
}

sub check_deps {
    my ($list, $result) = @_;
    foreach (keys %$list) {
	my $m = "$_ ($list->{$_})";
	print "Checking for $m", get_dots($m);
	my $try = "require $_;";
	eval $try;
	if ($@) {
	    print "missing!\n";
	    push @$result, $_;
	} else {
	    my $version = '$' . "$_" . '::VERSION >= ' . $list->{$_};
	    if( eval $version ) {
		print "ok\n";
	    } else {
		print "old version!\n"; 
		push @result, $_;
	    }
	}
    }
}

sub report_deps {
    if ($missing_req[0]) {
#	print "\nSorry, RDF::Core can't be instaled. ";
	print "The following modules are required:\n\n";
	foreach (@missing_req) {
	    print "$_, version $required{$_} or later: $msg{$_}\n";
	}
	#exit 1;
    }
    
    if ($missing_opt[0]) {
	print "\nRDF::Core can be instaled but its functionality will be limited\n";
	print "as the following modules are required to support some features:\n\n";
	foreach (@missing_opt) {
	    print "$_, version $optional{$_} or later: $msg{$_}\n";
	}
	print "\nIf you want use the above described features,\n";
	print "install or update the missing modules.\n\n"
    }
}

check_deps(\%required, \@missing_req);
check_deps(\%optional, \@missing_opt);
report_deps;

WriteMakefile(
	      'PMLIBDIRS'    => [ 'lib' ],
	      'NAME'	     => 'RDF::Core',
	      'VERSION_FROM' => 'lib/RDF/Core.pm', # finds $VERSION
	      'PREREQ_PM'    => {%required, %optional}, 
	      'dist' => {
			 'COMPRESS' => 'gzip',
			 'SUFFIX'   => 'gz',
			}
);
