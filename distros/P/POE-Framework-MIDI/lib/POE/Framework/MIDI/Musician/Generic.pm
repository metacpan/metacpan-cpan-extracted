# $Id: Generic.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

############
# use this package as a starting point for making musicians.  

package POE::Framework::MIDI::Musician::Generic;
use strict;
use vars '$VERSION'; $VERSION = '0.02';
use vars '@ISA';
@ISA = 'POE::Framework::MIDI::Musician';

use POE::Framework::MIDI::Musician;
use POE::Framework::MIDI::Bar;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rest;

sub new {
    my ($self, $class) = ({}, shift);
    $self->{cfg} = shift;
    bless($self, $class);
    return $self;
}

sub make_bar {
    my $self = shift;
    my $barnum = shift;
    
    my $bar = POE::Framework::MIDI::Bar->new({ number => $barnum });

    # add some events to the bar with $bar->add_event($note);
    # or rest, or noop once that does something.

    return $bar;
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Musician::Generic

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
