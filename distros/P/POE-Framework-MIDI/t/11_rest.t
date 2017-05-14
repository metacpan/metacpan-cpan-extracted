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
	use_ok('POE::Framework::MIDI::Rest');
	ok(my $r = POE::Framework::MIDI::Rest->new( duration => 'qn' ));
	isa_ok($r,'POE::Framework::MIDI::Rest');
	is($r->duration,'qn');
	is($r->name,'rest');	
	
}