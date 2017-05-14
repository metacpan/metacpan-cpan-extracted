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
	use_ok('POE::Framework::MIDI::Phrase');
	use_ok('POE::Framework::MIDI::Note');
	use_ok('POE::Framework::MIDI::Rest');
	
}

ok(my $p = POE::Framework::MIDI::Phrase->new());

ok(my $n = POE::Framework::MIDI::Note->new( name => 'C2', duration => 'sn'));
isa_ok($n,'POE::Framework::MIDI::Note');
ok(my $r = POE::Framework::MIDI::Rest->new( duration => 'en' ));

	ok($p->add_event($n));
	ok($p->add_events([$r,$n,$n,$n,$r,$r]));
	ok(my $e = $p->events);