# $Id: POEMusician.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::POEMusician;
use strict;
use vars '$VERSION'; 
use base 'POE::Framework::MIDI::Musician';
use POE;
use POE::Framework::MIDI::Musician;

# Changelog: 
#
# 0.02 - Updated to remove calls to deprecated POE::Session->new and replace
# them with POE::Session->spawn instead;
#

$VERSION = 0.2;

# session builder - ala dngor
sub spawn {
    my $class 	= shift;
    my $self 		= $class->new(@_);
    
    POE::Session->create(
    	object_states => [   $self => [qw(_start _stop make_a_bar)]] );
    my ( $package,  $patch,  $channel ) = ( $self->{cfg}->{package}, $self->{cfg}->{patch},
    	$self->{cfg}->{channel} );	
    
     $self->{musician_object} = $package->new( {
     	package 		=> $package,
     	name 			=> $self->{cfg}->{name}, 
     	patch 			=> $patch,
     	channel 		=> $channel,
     	data 			=> $self->{cfg}->{data}, })
     	or die "couldn't make a new $self->{cfg}->{package}" ;
    return undef;
}

sub _start {
    my ( $self,  $kernel,  $session,  $heap ) = @_[OBJECT, KERNEL, SESSION, HEAP];
    $kernel->alias_set( $self->name );
    print $self->name . " has started\n" if $self->{cfg}->{verbose};
}

sub _stop {
    my ( $self, $kernel, $session, $heap ) = @_[OBJECT, KERNEL, SESSION, HEAP];
}

# trigger the local musician sub-object to make a bar.
sub make_a_bar {
    my ($self, $kernel, $session, $heap, $sender, $barnum ) = 
        @_[OBJECT, KERNEL, SESSION, HEAP, SENDER, ARG0];
    
    $kernel->post(   $sender, 'made_bar', $barnum,
        $self->{musician_object}->make_bar($barnum), $self->{musician_object}
    );
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::POEMusician - POE functionality for POE Musicians

=head1 ABSTRACT

=head1 DESCRIPTION

POE functionality for the Musicians - handles communication of events
between the conductor and the internal POE::Framework::MIDI::Musician::* 
object

=head1 SYNOPSIS

Used internally by POE::Framework::POEMusician

=head1 SEE ALSO

L<POE>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Primary: Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: SMCNABB

Secondary: Gene Boggs E<lt>cpan@ology.netE<gt>

CPAN ID: GENE

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
