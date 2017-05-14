# $Id: Test.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Musician::Test;
use strict;
use vars '$VERSION'; $VERSION = '0.02';
use vars '@ISA';
@ISA = 'POE::Framework::MIDI::Musician';

use POE::Framework::MIDI::Musician;
use POE::Framework::MIDI::Bar;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rest;

sub new {
    my ($self, $class) = ({},shift);
    $self->{cfg} = shift;
    bless $self, $class;
    return $self;
}

sub make_bar {
    my $self = shift;
    my $barnum = shift;
    
    # make a bar
    my $bar = POE::Framework::MIDI::Bar->new({ number => $barnum });
    # add some notes & rests 
    my $note1 = POE::Framework::MIDI::Note->new({ name => 'C', duration => 'sn' });
    my $note2 = POE::Framework::MIDI::Note->new({ name => 'D', duration => 'en' });
    my $rest1 = POE::Framework::MIDI::Rest->new({ duration => 'qn' });
    
    $bar->add_events($note1, $rest1, $note1, $note2);  
    
    # can't really test Noops yet - not supported.
    
#lib/POE/Framework/MIDI/Phrase;
#lib/POE/Framework/MIDI/Ruleset;
#lib/POE/Framework/MIDI/Rule;
#lib/POE/Framework/MIDI/Utility;
#lib/POE/Framework/MIDI/Key;
#lib/POE/Framework/MIDI/Note;
#lib/POE/Framework/MIDI/Rest;
#lib/POE/Framework/MIDI/Noop;
    
    return $bar;
}

1;

__END__

=head1 NAME 

POE::Framework::MIDI::Musician::Test - A musician used by the test script

=head1 ABSTRACT

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SEE ALSO

L<POE>

L<POE::Framework::MIDI::Musician>

L<POE::Framework::MIDI::Bar>

L<POE::Framework::MIDI::Note>

L<POE::Framework::MIDI::Rest>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: JUSTSOMEGUY

Gene Boggs E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 Steve McNabb. All rights reserved.  This program 
is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
