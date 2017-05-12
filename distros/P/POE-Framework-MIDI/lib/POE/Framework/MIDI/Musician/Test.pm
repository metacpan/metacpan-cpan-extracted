# $Id: Test.pm,v 1.2 2002/09/17 21:14:02 ology Exp $

############
# A musician used by the test script

package POE::Framework::MIDI::Musician::Test;
use POE::Framework::MIDI::Musician;
use POE::Framework::MIDI::Bar;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rest;

use vars qw/@ISA/;
@ISA = qw(POE::Framework::MIDI::Musician);

sub new
{
        my($self,$class) = ({},shift);
        $self->{cfg} = shift;
        bless($self,$class);
        return $self;
}

sub make_bar
{
	my $self = shift;
	my $barnum = shift;
	
	# make a bar
	my $bar = new POE::Framework::MIDI::Bar( { number => $barnum } );
	# add some notes & rests 
	my $note1 = new POE::Framework::MIDI::Note( { name => 'C', duration => 'sn' });
	my $note2 = new POE::Framework::MIDI::Note( { name => 'D', duration => 'en' });
	my $rest1 = new POE::Framework::MIDI::Rest( { duration => 'qn' });
	
	$bar->add_events(($note1,$rest1,$note1,$note2));  
	
	# can't really test Noops yet - not supported.
	
#lib/POE/Framework/MIDI/Phrase;
#lib/POE/Framework/MIDI/Ruleset;
#lib/POE/Framework/MIDI/Rule;
#lib/POE/Framework/MIDI/Utility;
#lib/POE/Framework/MIDI/Key;
#lib/POE/Framework/MIDI/Note;
#lib/POE/Framework/MIDI/Rest;
#lib/POE/Framework/MIDI/Noop;
	
	return $bar;
}

1;
