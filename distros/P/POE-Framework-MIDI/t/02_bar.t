# tests for the bar object - the bar is a container for note and rest events
#
# eventually it would be nice to add some sort of intelligence to the bar object
# whereby it knows what key signature it is in, and 

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
	use_ok('POE::Framework::MIDI::Bar');
	use_ok('POE::Framework::MIDI::Note');
	use_ok('POE::Framework::MIDI::Rest');
	
	ok(my $b = POE::Framework::MIDI::Bar->new( number => 1));
	isa_ok($b,'POE::Framework::MIDI::Bar');
	is($b->number,1);
	
	
	ok(my $n = POE::Framework::MIDI::Note->new( name => 'C2', duration => 'sn'));
	isa_ok($n,'POE::Framework::MIDI::Note');
	ok(my $r = POE::Framework::MIDI::Rest->new( duration => 'en' ));
	isa_ok($r,'POE::Framework::MIDI::Rest');
	ok($b->add_event($n));
	ok($b->add_events([$r,$n,$n,$n,$r,$r]));
	ok(my $e = $b->events);

}