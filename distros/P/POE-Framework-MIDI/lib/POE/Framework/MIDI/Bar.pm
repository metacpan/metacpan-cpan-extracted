# $Id: Bar.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

# POE::Framework::MIDI::Bar - object representing a bar

package POE::Framework::MIDI::Bar;

use strict;
use POE::Framework::MIDI::Utility;
use constant VERSION => 0.1;

sub new
{
	my ($self,$class) = ({},shift);
	bless $self,$class;
	$self->{cfg} = shift;
	warn 'please provide a number => $n param when generating bars'
	unless $self->{cfg}->{number};
	return $self;	
}

sub bar_number
{
	my $self = shift;
	return $self->{cfg}->{number}; 	
}

# return the stack of notes/rests/intervals
sub events
{
	my ($self,$new_events) = @_;
	$new_events 
		? $self->{events} = $new_events
		: return $self->{events}
}

sub add_event
{
	my ($self,$event) = @_;
	push @{$self->{events}},$event;	
}

sub add_events
{
	my($self,@events) = @_;
	push @{$self->{events}},@events;	
}

1;

=head1 NAME

POE::Framework::MIDI::Bar

=head1 DESCRIPTION

This package acts as a container for MIDI events

=head1 USAGE

my $bar = new POE::Framework::MIDI::Bar;
$bar->add_event($some_event);

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
