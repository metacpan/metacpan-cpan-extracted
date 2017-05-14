#!/usr/bin/perl -w

BEGIN {
use strict;
use Test::More 'no_plan';
use_ok('POE::Framework::MIDI');
use_ok('FindBin');
}

my @musicians = (
	{
		name => 'Frank',
		package => 'MyTest',
		patch => 50,
		channel => 1,
	},
	{
		name => 'Ian',
		package => 'MyTest',
		patch => 75,
		channel => 2,
	}
);

# what else do we want here?
my %data = (
	bars => 15,
	debug => 0,
	verbose => 1,
	filename => 'miditest.mid',
);

ok(my $midi = POE::Framework::MIDI->new( musicians => \@musicians, data => \%data ));
isa_ok($midi,'POE::Framework::MIDI');
ok($midi->run);

ok(unlink('miditest.mid'));


############
# A musician used by the test script

package MyTest;
use base 'POE::Framework::MIDI::Musician';
use POE::Framework::MIDI::Bar;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rest;



sub make_bar {
	my $self = shift;
	my $barnum = shift;
	
	# make a bar
	my $bar = new POE::Framework::MIDI::Bar(  number => $barnum  );
	# add some notes & rests 
	my $note1 = new POE::Framework::MIDI::Note(  name => 'C', duration => 'sn' );
	my $note2 = new POE::Framework::MIDI::Note(  name => 'D', duration => 'en' );
	my $rest1 = new POE::Framework::MIDI::Rest(  duration => 'qn' );
	my @notes = qw(C4 C3 D3 D1 D5 E4);
	my @e;
	for(1..16)
	{
		my $n = POE::Framework::MIDI::Note->new( name => $notes[rand(@notes)], duration => 'sn' );
		push @e, $n;
	}
	
	$bar->add_events(@e);  
	
	return $bar;
}

1;
