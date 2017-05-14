# $Id: Musician.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Musician;
use strict;
no strict 'refs';
use vars '$VERSION'; $VERSION = '0.02';

sub new {
    my( $self, $class ) = ( {},  shift );
    bless( $self, $class );
    
    #my %params = @_;
    #$self->{cfg} = \%params;
    use Data::Dumper;
    
    $self->{cfg} = shift;
   unless($self->{cfg}->{package}) {
    die "no package provided to POE::Framework::MIDI::Musician.. it needs a package to know what to play.  Dump: " . Dumper($self->{cfg}) . "\n\n" . caller;
   }
    #die "no channel passed to $self->{cfg}->{package}::new" unless $self->{cfg}->{package};
    #die "no name passed to $self->{cfg}->{package}:new" unless $self->{cfg}->{name};
    return $self;
}

sub package {
    my $self = shift;
    return $self->{cfg}->{package};
}

sub name {
    my $self = shift;
    return $self->{cfg}->{name};    
}

sub instrument_name {
	my $self = shift;
	return $self->name;
}

sub channel {
    my $self = shift;
    return $self->{cfg}->{channel};
}

sub data {
	my $self = shift;
	return $self->{cfg}->{data};
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Musician - Non-POE Musician functionality

=head1 ABSTRACT

=head1 DESCRIPTION

Non-POE Musician functionality. This package takes a package name as a 
configuration parameter, and uses that package to create musical 
events, and run them through rules and transformations.

This module is configured as per the 'musicians' array reference 
defined in the spawn method of POEConductor and coordinated by the 
POEConductor to procduce a MIDI event stream.

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
