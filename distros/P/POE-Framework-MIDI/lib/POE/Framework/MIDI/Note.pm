# $Id: Note.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Note;
use strict;
use vars '$VERSION'; $VERSION = '0.02';
use POE::Framework::MIDI::Utility;

sub new {
	my ( $self, $class ) = ( {}, shift );
	bless $self,$class;
	my %params = @_;
	$self->{cfg} = \%params;
	
	# validate note names.
	my $_name 	= $self->name;
	my ($letter) 	= $_name =~ /^([a-gA-G])/;
	die "$_name doesn't look like a valid note name.  Examples:  A, C3, G2, CS4 etc"
	 unless $letter;
	 
	 die "You forgot to set a duration for the note $_name" unless $self->{cfg}->{duration};
	$self->{cfg}->{name} = $self->{cfg}->{name};
	return $self;	
}

sub duration {
	my ( $self, $new_duration )  = @_;
	$new_duration  ? $self->{cfg}->{duration} = $new_duration : return $self->{cfg}->{duration}		
}

sub name {
	my ( $self, $new_name ) = @_;
	$new_name ? $self->{cfg}->{name} = $new_name : return $self->{cfg}->{name}	
}

# an alias for name
sub note {
	my ( $self, $new_note ) = @_;
	$self->name($new_note);	
	return $self->name;
}




1;

__END__

=head1 NAME

POE::Framework::MIDI::Note - An object to represent the MIDI note event

=head1 ABSTRACT

=head1 DESCRIPTION

This package represents a note object for use in musicians, rules and 
transformations.

=head1 SYNOPSIS

my $note = new POE::Framework::MIDI::Note( name => 'D', duration => 'hn' );

=head1 SEE ALSO

L<POE>

L<POE::Framework::MIDI::Utility>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Primary: Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: SMCNABB

Secondary: Gene Boggs E<lt>cpan@ology.netE<gt>

CPAN ID: GENE

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 Steve McNabb. All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
