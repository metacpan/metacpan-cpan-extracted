        # File:  : examples/synopsis.pl
        # Author : Josiah Bryan, 2000/9/16, jdb@wcoil.com
	use Term::Sample qw(sample average analyze intr);
	use strict;
 	
	my $set = Term::Sample::Set->new();
	
	my $sample_string = 'green eggs and ham';
	
	if(!$set->load("test4.set")) {
		my @samples;
		print "Person: Person #1\n";
		
		my $top = 2;
		for (0..$top) {
			print "[ Sample $_ of $top ]  Please type \"$sample_string\": ";
		   	$samples[$_] = sample();
		}
		
	   	$set->store( 'Person #1' => average(@samples) );
	   	
	   	print "Person: Person #2\n";

		my $top = 2;
		for (0..$top) {
			print "[ Sample $_ of $top ]  Please type \"$sample_string\": ";
		   	
		   	# This has the same effect as saving all the samples in an array 
		   	# then calling store on the average() output, as shown above.
		   	
		   	$set->store( 'Person #2' => sample() );
		}
		
	   	$set->save("test4.set");
	}
   	
   	print "Now to test it out...\n";
   	print "[ Anybody ] Please type \"$sample_string\": ";
   	my $sample = sample();

	my ($key, $diff) = $set->match($sample, 1);
   	print "I am sure (about ",intr(100-$diff),"% sure) that your signiture matched the key `$key'.\n";
   	
