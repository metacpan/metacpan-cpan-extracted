# $Id: Phrase.pm,v 1.3 2002/09/21 06:16:54 ology Exp $

# POE::Framework::MIDI::Phrase - a pre-defined bundle of MIDI events

package POE::Framework::MIDI::Phrase;

use strict;
use POE::Framework::MIDI::Utility;
use constant VERSION => 0.1;

sub new
{
	my ($self,$class) = ({},shift);
	bless $self,$class;
	$self->{cfg} = shift;
	return $self;	
}

# add an event to the event stack
sub add_event
{
	my ($self,$event) = @_;
	push @{$self->{events}}, $event;	
}

# return the stack of notes/rests/intervals/bars
sub events
{
	my ($self,$new_events) = @_;
	$new_events 
		? $self->{events} = $new_events
		: return $self->{events}
}

1;

=head1 NAME

POE::Framework::MIDI::Phrase

=head1 DESCRIPTION

A pre-defined bundle of MIDI events

=head1 AUTHOR

	Steve McNabb
	CPAN ID: JUSTSOMEGUY
	steve@justsomeguy.com
	http://justsomeguy.com/code/POE/POE-Framework-MIDI 

=head1 COPYRIGHT

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1). POE.  Perl-MIDI

=cut
