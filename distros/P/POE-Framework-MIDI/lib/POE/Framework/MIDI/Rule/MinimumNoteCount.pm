# this is a rather uninteresting rule to test the rules mechanimsm
#
# it's boolean:  it either matches, or doesn't.  
#
# eventually we'll have ternary rules that can match, not
# match or partially  match
# 
# author: Steve McNabb  (steve@justsomeguy.com)

package POE::Framework::MIDI::Rule::MinimumNoteCount;

use strict;
use vars qw/@ISA/;
use POE::Framework::MIDI::Rule;

@ISA = qw(POE::Framework::MIDI::Rule);


# test whatever we're passed  
sub test
{
		my ($self,$thing_to_test) = @_;
		unless(ref($thing_to_test) eq 'ARRAY') { die 'usage: $result = $rule->test(\@a_bar)' }
		$self->{notecount} = undef;
		for(@$thing_to_test)
		{
		 	$_->{note} ? ++$self->{notecount} : next;	
		}
		print "saw $self->{notecount} notes in $thing_to_test\n" if $self->{params}->{verbose};
		$self->{notecount} >= $self->min_notes ? return 1 : return;
}		

sub min_notes
{
	my $self = shift;
	
	die 'no min_notes set in ' .__PACKAGE__.'  params' unless $self->{params}->{min_notes};
	return $self->{params}->{min_notes};	
}

sub notecount
{
	my $self = shift;
	unless ($self->{notecount}) { $self->{notecount} = '0' }		
	return $self->{notecount};
}


1;