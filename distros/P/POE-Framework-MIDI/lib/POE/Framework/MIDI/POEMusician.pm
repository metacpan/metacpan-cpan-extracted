# $Id: POEMusician.pm,v 1.3 2002/09/17 21:14:01 ology Exp $

# generic musician session - POE-based functionality

package POE::Framework::MIDI::POEMusician;
use POE::Framework::MIDI::Musician;
use POE;
use strict;
my $VERSION = '0.1a';
use vars qw/@ISA/;

@ISA = qw(POE::Framework::MIDI::Musician);

# session builder - ala dngor
sub spawn
{
        my $class = shift;
        my $self = $class->new(@_);
        POE::Session->new( 
        $self => [ qw (_start _stop make_a_bar) ]);
           
        $self->{musician_object} = $self->{cfg}->{package}->new($self->{cfg})
        or die "couldn't make a new $self->{cfg}->{package}" ;
        return undef;
}

sub _start
{
	my ($self, $kernel, $session, $heap) = @_[OBJECT, KERNEL, SESSION, HEAP];
	$kernel->alias_set($self->name);
	print $self->name . " has started\n" if $self->{cfg}->{verbose};
}

sub _stop
{
	my ($self, $kernel, $session, $heap) = @_[OBJECT, KERNEL, SESSION, HEAP];

}

# trigger the local musician sub-object to make a bar.
sub make_a_bar
{
	my ($self, $kernel, $session, $heap, $sender, $barnum ) = 
	@_[OBJECT, KERNEL, SESSION, HEAP, SENDER, ARG0];
	
	$kernel->post($sender,'made_bar', $barnum, $self->{musician_object}->make_bar($barnum), $self->{musician_object});
}

1;

=head1 NAME

POE::Framework::MIDI::POEMusician

=head1 DESCRIPTION

POE functionality for the Musicians - handles communication of events
between the conductor and the internal POE::Framework::MIDI::Musician::* 
object

=head1 USAGE

Used internally by POE::Framework::POEMusician

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
