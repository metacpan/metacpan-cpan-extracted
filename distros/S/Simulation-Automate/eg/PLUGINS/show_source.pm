package Simulation::Automate::PostProcessors;

sub show_source {
	print STDERR "RESULTS:\n";	
	for my $line (@results){
		print STDERR $line;
		  }
	print STDERR "-" x 78;
	print STDERR "\n";
}

print "Loaded plugin show_source\n";
