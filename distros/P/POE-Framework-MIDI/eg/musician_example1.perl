#!/usr/bin/perl -w
# an example of how to make your own custom musicians for
# POE::Framework::MIDI
#
# The Musician package POE::Framework::MIDI::Musician::MyTest
# is at the bottom of this file.

use strict;
use POE;
use POE::Framework::MIDI::POEConductor;
use POE::Framework::MIDI::POEMusician;

POE::Framework::MIDI::POEConductor->spawn({
    debug     => 1,
    verbose   => 1,
    bars      => 4,
    filename  => 'example1-output.mid',
    musicians => [
        {
            name    => 'frank',		
            # specify which module you want to have "play" this track. 
            # 
            # the only real requirement for a musician object is
            # that it define a 'make_bar' method.  ideally that should
            # return POE::Framework::MIDI::Bar( { number => $barnum } );		
            package => 'POE::Framework::MIDI::Musician::MyTest',
            channel => 1,
            patch   => 10,
        },
        {
            name    => 'ainsley',
            package => 'POE::Framework::MIDI::Musician::MyTest',
            channel => 2,
            patch   => 20,
        },
        {
            name    => 'ike',
            package => 'POE::Framework::MIDI::Musician::MyTest',
            channel => 3,
            patch   => 56,
        },
    ],
}); 

# $poe_kernel is exported by POE
$poe_kernel->run;

############
# A musician used by the test script

package POE::Framework::MIDI::Musician::MyTest;
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
	
	$bar->add_events(($note1,$rest1,$note1,$note2));  
	
	return $bar;
}

1;
