	# File   : examples/set.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample average new_Set);
	
	print "\nSet Creation Script\n\n";
	print "Please enter a file to save the final sample in: ";
	chomp(my $file = <>);
	print "Please enter a key for this sample in the set: ";
	chomp(my $key = <>);
	print "Number of samples to take: ";
	chomp(my $num = <>);
	
	my @samples;
	for my $x (1..$num) {
		print "[$x of $num] Enter sample string: ";
		$samples[++$#samples] = sample();
	}
	
	print "Combining and saving samples...";
	
	# Since most of the set methods return the blessed object, 
	# (except match()) you can chain methods together
	
	new_Set(silent=>1)
		->load($file)
		->store($key => average(@samples))
		->save($file);
	
	print "Done!\n";
	
	
	__END__
                 
