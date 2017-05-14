# $Id: Bar.pm,v 1.2 2004/12/04 18:08:17 stv Exp $

package POE::Framework::MIDI::Bar;

use strict;
use vars '$VERSION'; $VERSION = '0.02';
use POE::Framework::MIDI::Utility;

sub new {

    my ( $self,  $class ) = ( {},  shift );
    bless $self, $class;
    my %params = @_;
    $self->{cfg} = \%params;
    warn 'please provide a value for the number => $n parameter when generating bars'
    unless $self->{cfg}->{number}; 
    return $self;    
}

sub number {
    my $self = shift;
    return $self->{cfg}->{number};     
}


# return the stack of notes/rests/intervals
sub events {
    my ( $self,  $new_events ) = @_;
    $new_events  ? $self->{events} = $new_events : return $self->{events}
}

sub add_event {
    my ( $self, $event ) = @_;
    push @{$self->{events}}, $event;    
}

sub add_events {
    my ( $self, @events ) = @_;
    push @{$self->{events}}, @events;    
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Bar - Container for MIDI events

=head1 ABSTRACT

=head1 DESCRIPTION

This package acts as a container for MIDI events

=head1 SYNOPSIS

  my $bar = new POE::Framework::MIDI::Bar;

  $bar->add_event($some_event);

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
