#!/usr/bin/perl -w

BEGIN {
use strict;
use Test::More 'no_plan';
use_ok('POE::Framework::MIDI');
use_ok('POE::Framework::MIDI::Interval');
use_ok('FindBin');
}

ok(my $i = POE::Framework::MIDI::Interval->new( duration => 'qn' , notes => [ 'C3','E3','G3' ]));
isa_ok($i,'POE::Framework::MIDI::Interval');
is($i->duration, 'qn');
is(ref($i->notes), 'ARRAY');


my @musicians = (
	{
		name => 'Frank',
		package => 'MyTest',
		patch => 1,
		channel => 1,
	},

);

# what else do we want here?
my %data = (
	bars => 15,
	debug => 0,
	verbose => 1,
	filename => 'intervaltest.mid',
);

ok(my $midi = POE::Framework::MIDI->new( musicians => \@musicians, data => \%data ));
isa_ok($midi,'POE::Framework::MIDI');
ok($midi->run);

ok(unlink('intervaltest.mid'));

package MyTest;
use base 'POE::Framework::MIDI::Musician';
use POE::Framework::MIDI::Bar;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rest;
use POE::Framework::MIDI::Interval;


sub make_bar {
	my $self = shift;
	my $barnum = shift;
	
	# make a bar
	my $bar = new POE::Framework::MIDI::Bar(  number => $barnum  );
	# add some notes & rests 
	
	my $int1 = POE::Framework::MIDI::Interval->new( 
		duration => 'wn', notes => ['C2','G2','C3','G3','C4','G4','C5' ]);
	$bar->add_event($int1);
 
	
	return $bar;
}

1;

