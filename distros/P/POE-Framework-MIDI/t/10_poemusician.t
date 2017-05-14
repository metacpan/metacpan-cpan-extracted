#!/usr/bin/perl -w
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
	use_ok('POE::Framework::MIDI::POEMusician');
	use_ok('POE::Framework::MIDI::POEConductor');
	ok(my $mus = POE::Framework::MIDI::POEMusician->new( {
		package => 'MyTest', 
		name => 'H.R. Puffinstuff', 
		channel => 3,
		patch => 44}));
	isa_ok($mus, 'POE::Framework::MIDI::POEMusician');

	
}



package MyTest;
use base 'POE::Framework::MIDI::Musician';
#use POE::Framework::MIDI;


sub make_bar {
	my $b =POE::Framework::MIDI::Bar->new( barnum => 1 );
	my $n = POE::Framework::MIDI::Note->new( name => 'C4', duration => 'qn' );
	$b->add_event($n);
	return $b;
}



1;