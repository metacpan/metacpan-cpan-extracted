	# File   : examples/spasswd.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample analyze intr to_string diff plus new_Set);
	
	my $set = new_Set(silent=>1);
	$set->load("password.set");
	
	print "Enter username: ";
	chomp(my $key = <>);
	
	my $password = $set->get($key);
	if(!$password) {
		print "Error: No user by name `$key' in database. Exiting.\n";
		exit -1;
	}
	
	print "Enter password: ";
	my $input = sample( echo => '*' );
	
	print "got:",to_string($input)," needed:",to_string($password),"\n";
	my $diff;
	if(to_string($input) ne to_string($password)) {
		print "Error: Passwords don't match. Penalty of 100%\n";
		$diff = 100;
	}
		
	$diff = intr(100 - (diff(analyze($input), analyze($password))+$diff));
	                                                                    
	print "I am $diff% sure you are ",(($diff>50)?"real.":"a fake!"),"\n";

	__END__
