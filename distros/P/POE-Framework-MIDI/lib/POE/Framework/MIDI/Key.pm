# $Id: Key.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

package POE::Framework::MIDI::Key;
use strict;
use vars qw/$lexicon/;
use MIDI::Simple;
my $VERSION =  '0.1a';

#
# a lexcion of key types and a key for building them from a root note
#
#
my $lexicon =
{
	# major scale is tone tone semitone, tone tone tone semitone
	maj => [0,2,2,1,2,2,2,1], major => [0,2,2,1,2,2,2,1],  
	# declaring it twice is probably dumb
	
};


sub new
{
	my ($self,$class) = ({}, shift);
	bless $self,$class;
	$self->{cfg} = shift;
	$self->make_root_numeric;
	$self->{intervals} = $lexicon->{$self->{cfg}->{name}} 
		or die "sorry - $self->{cfg}->{name} is not supported yet";
	return $self;	
}

# the root note
sub root
{
	my ($self,$new_root) = @_;
	$new_root ? 
		$self->{cfg}->{root} = $new_root
		: return $self->{cfg}->{root}
}

#chord's name
sub name
{
	my ($self,$new_name) = @_;
	$new_name ?
		$self->{cfg}->{name} = $new_name
		: return $self->{cfg}->{name}			
}

sub make_root_numeric
{
	my $self = shift;	
	if($self->{cfg}->{root} =~ /\D/)
	{
		$self->{cfg}->{root} = $self->note_to_number($self->{cfg}->{root});			
	}		
}

sub note_to_number
{
	my ($self,$note) = @_;
	my ($letters,$numbers) = $note =~ /(\D+)(\d+)/; 
	my $position = $MIDI::Simple::Note{$letters};
	my $end_position = $position + ($numbers * 12);
	return $end_position; 
}

# what is the position of this note in the key?
sub noteposition
{
	my ($self,$note) = @_;
	my $numeric_position = $self->note_to_number($note);
	print $self->root  . "\n";
	my $scale = $self->numeric_scale;

	# we need to generate a "monster scale" that extends this tonal
	# pattern off to 0 and 127 
	
	for(@$scale)
	{
		print "$_\n";
	}		
	
}

# use the intervals from the lexicon to make the scale
# based on the root for this key.  For example, if use
# C4 for the root, (note #)
sub numeric_scale
{
	my $self = shift;
	my @scale;
	my $last_note = $self->root;
	for(@{$self->{intervals}})
	{
		push @scale, $last_note + $_;
		$last_note = $scale[-1]; # (negative subscripting)++		
	}
	return \@scale;
}

sub intervals
{
	my $self = shift;
	return $self->{intervals};	
}

1;

=head1 NAME

POE::Framework::MIDI::Key

=head1 DESCRIPTION

This package provides a lexicon of key types (major, minor, etc)
and an interval key for building them from a root note.  For
example: consider a piano keyboard.  The space from any note
to its next nearest neighbour might be a black key or a white key.
That's a semitone.  Two semitones, or the key next to the key's
nearest neighbour is a Tone (or "Full Tone"). If you start on any
key, and count up one semitone at a time, you get an ascending 
chromatic (play every semitone) scale.  If you count "Tone, Tone,
Semitone, Tone, Tone, Tone, Semitone" from the starting note, 
you get a major scale.  This module aims to provide easy calculations
for things like "What's the third note in a major scale starting with C#?"

=head1 USAGE

my $key = new POE::Framework::MIDI::Key({ name => 'maj', root => 'E4' });
print "The third of that scale is ", ${$key->numeric_scale}[2],"\n";

=head1 BUGS

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
