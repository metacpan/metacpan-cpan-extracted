# $Id: Generic.pm,v 1.2 2002/09/17 21:14:02 ology Exp $

############
# use this package as a starting point for making musicians.  
#

package POE::Framework::MIDI::Musician::Generic;
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
	
	my $bar = new POE::Framework::MIDI::Bar( { number => $barnum } );
	
	# add some events to the bar with $bar->add_event($note);
	# or rest, or noop once that does something.
	
	return $bar;
}

1;
