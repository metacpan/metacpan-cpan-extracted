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
	use_ok('POE::Framework::MIDI::Ruleset');
	ok(my $rs = POE::Framework::MIDI::Ruleset->new( context  => 'event' ));
	
}