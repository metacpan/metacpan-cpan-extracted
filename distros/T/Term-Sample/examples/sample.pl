	# File   : examples/sample.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample average load save print_data);
	
	print "\nSample Creation Script\n\n";
	print "Please enter a file to save the final sample in: ";
	chomp(my $file = <>);
	print "Number of samples to take: ";
	chomp(my $num = <>);
	
	my @samples;
	for my $x (1..$num) {
		print "[$x of $num] Enter sample string: ";
		$samples[++$#samples] = sample();
	}
	
	print "Combining and saving samples...";
	save(average(@samples), $file);
	
	print "Done!\n";
	
	
	
	__END__
                 
