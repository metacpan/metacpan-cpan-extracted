	# File   : examples/passwd.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample analyze load intr to_string diff plus);
	
	my $password = load("password.sample");
	
	print "Enter password: ";
	my $input = sample( echo => '*' );
	
	my $diff;
	if(to_string($input) ne to_string($password)) {
		print "Error: Passwords don't match. Penalty of 100%\n";
		$diff = 100;
	}
		
	$diff = intr(100 - (diff(analyze($input), analyze($password))+$diff));
	                                                                    
	print "I am $diff% sure you are ",(($diff>50)?"real.":"a fake!"),"\n";

	__END__
