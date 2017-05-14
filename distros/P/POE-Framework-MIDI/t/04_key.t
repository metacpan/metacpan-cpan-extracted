# tests for the key object.  this will be used to lookup info about specific keys 
# and modes

BEGIN
{
	use strict;	
	use Test::More 'no_plan';
	# MIDI::Simple uses unquoted strings, but it's yummy.
	$SIG{__WARN__} = sub { return $_[0] unless $_[0] =~ /Unquoted string/ };

	#################
	# test module use
	#################
	use_ok('POE');
	use_ok('POE::Framework::MIDI::Key');
}

SKIP: {
	skip 1, 'Key is not done yet';
	ok(my $key = new POE::Framework::MIDI::Key);

}