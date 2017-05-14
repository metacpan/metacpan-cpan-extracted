# $Id: Phrase.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Phrase;
use strict;
use vars '$VERSION'; $VERSION = '0.02';
use POE::Framework::MIDI::Utility;

sub new {
	my ( $self,  $class ) = ( {},  shift );
	bless $self, $class;
	$self->{cfg} = shift;
	return $self;	
}

sub add_event {
    my ( $self, $event ) = @_;
    push @{$self->{events}}, $event;    
}

sub add_events {
    my( $self, @events ) = @_;
    push @{$self->{events}}, @events;    
}

# return the stack of notes/rests/intervals/bars
sub events {
	my ( $self, $new_events ) = @_;
	$new_events 
		? $self->{events} = $new_events : return $self->{events}
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Phrase

=head1 ABSTRACT

=head1 DESCRIPTION

=head1 SYNOPSIS

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
