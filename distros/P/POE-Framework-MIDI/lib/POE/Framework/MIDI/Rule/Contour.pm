# $Id: Contour.pm,v 1.2 2002/09/21 06:51:36 ology Exp $

=head1 DESCRIPTION

gene@ology.net

=cut

package POE::Framework::MIDI::Rule::Contour;
use strict;
use warnings;
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = (qw($Revision: 1.2 $))[1];
use base qw(POE::Framework::MIDI::Rule);
use POE::Framework::MIDI::Phrase;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rule::Utility;
use String::Similarity;

=head2 test()

Does the phrase object contour match the given "USD contour"?

* This regular expression functionality is just too cool, but is not 
that happening yet.  Right now, it's a simple Boolean operation - it 
does no tricky computation or RE parsing.  I would like to include 
numbers after the U/D directions in the contour strin.  This would 
indicate some kind of magnitude or percentage...  That is the 
Indeterminate Future[tm].

=cut

sub test {
    my ($self, $phrase, $contour) = @_;

    # Bail out unless we are given a phrase object and a contour string.
    croak 'Usage: $result = $rule->test($phrase_object, $contour_string)', "\n"
        unless ref ($phrase) =~ /Phrase/ && !(ref $contour);

    # Return 1 or 0 if the contour string looks like a regular
    # expression.  Otherwise return the String::Similarity (edit
    # distance) between the given, literal, contour and the computed
    # phrase contour.
    # * THIS FUNCTION DOES NO RE ERROR CHECKING.
    return $contour =~ /[^USD]/
        ? $self->get_contour($phrase) =~ /$contour/
        : similarity $self->get_contour($phrase), $contour;
}

=head2 get_contour()

Returns a string of the letters U, S, and D to represent phrase 
contour.

=cut

sub get_contour {
    my ($self, $phrase) = @_;

    # Extract the important information from the phrase object.
    my @notes = get_notes($phrase);

    # Build the USD string based on the interval of successive notes.
    my $contour = @notes == 1 ? 'S' : '';
    for (0 .. $#notes - 1) {
        my $interval = note_interval($notes[$_], $notes[$_ + 1]);

        $contour .= $interval < 0
            ? 'D' : $interval > 0
                ? 'U' : 'S';
    }

    return $contour;
}


1;
