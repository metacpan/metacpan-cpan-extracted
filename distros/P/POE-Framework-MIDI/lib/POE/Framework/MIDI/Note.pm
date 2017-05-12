# $Id: Note.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

# POE::Framework::MIDI::Note - a Note onject for use in musicians, rules and transformations

package POE::Framework::MIDI::Note;
use strict;
use POE::Framework::MIDI::Utility;

my $VERSION = 0.1;

sub new
{
	my ($self,$class) = ({},shift);
	bless $self,$class;
	$self->{cfg} = shift;
	return $self;	
}

sub duration
{
	my ($self,$new_duration) = @_;
	$new_duration 
		? $self->{cfg}->{duration} = $new_duration 
		: return $self->{cfg}->{duration}		
}

sub name
{
	my ($self,$new_name) = @_;
	$new_name 
		? $self->{cfg}->{name} = $new_name
		: return $self->{cfg}->{name}	
}

# an alias for name
sub note
{
	my ($self,$new_note) = @_;
	$self->name($new_note);	
	return $self->name;
}

sub channel
{
	my($self,$new_channel) = @_;
	$new_channel
		? $self->{cfg}->{channel} = $new_channel
		: return $self->{cfg}->{channel}	
}

1;

=head1 NAME

POE::Framework::MIDI::Note

=head1 DESCRIPTION

An object to represent the MIDI note event.  

=head1 USAGE

my $note = new POE::Framework::MIDI::Note({ name => 'D', duration => 'hn' });

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
