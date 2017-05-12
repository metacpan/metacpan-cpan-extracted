# $Id: Notes.pm,v 1.2 2002/09/21 06:20:09 ology Exp $

package POE::Framework::MIDI::Rule::Notes;
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

Does the phrase match the given note list?

This function either returns an array of boolean values for each 
note, or the string similarity between the notes of the phrase and 
the given note list, depending on the value of the flag.

=cut

sub test {
    my ($self, $phrase, $notes, $flag) = @_;

    # Bail out if we are not given a phrase object and a list of notes.
    croak 'Usage: $result = $rule->test($phrase_object, \@note_list)', "\n"
        unless ref ($phrase) =~ /Phrase/ && ref ($notes) eq 'ARRAY';

    # Extract the interesting information from the phrase object.
    my @p_notes = get_notes($phrase);

    # Two return possibilites:  If we are given a true flag, consider
    # the note list as a literal series.  If not, consider the given 
    # note list as a collection, rather than a literal series.
    # Confused?  ;-)  It's simpler than I've described.
    if ($flag) {
        return similarity join ('', @p_notes), join ('', @$notes);
    }
    else {
        # Construct a "bit string" for the given list of notes -
        # included or no.
        my @bit_vec;
        my $found = 0;
        for my $note (@$notes) {
            # Make the note look like a standard note (ie. parsable
            # by MIDI::Simple).
            $note = normalize_note($note);

            # Append 1 to the bit string if the note is present and
            # increment the counter of found notes.  Append 0 if not.
            if (grep { $note eq $_ } @p_notes) {
                push @bit_vec, 1;
                $found++;
            }
            else {
                push @bit_vec, 0
            }
        }

        # If called in a scalar context, return the average number of
        # notes found.  If called in a list context, return the bit
        # string, itself.
        return wantarray ? @bit_vec : $found / @bit_vec;
    }
}

1;
