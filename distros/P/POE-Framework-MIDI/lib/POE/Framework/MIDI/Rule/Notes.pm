# $Id: Notes.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Rule::Notes;
use strict;
use warnings;
use Carp 'croak';
use vars '$VERSION'; $VERSION = '0.02';
use base 'POE::Framework::MIDI::Rule';
use POE::Framework::MIDI::Phrase;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rule::Utility;
use String::Similarity;

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

__END__

=head1 NAME

POE::Framework::MIDI::Rule::Notes

=head1 ABSTRACT

=head1 DESCRIPTION

=head1 EXPORTED FUNCTIONS

=head2 test()

Does the phrase match the given note list?

This function either returns an array of boolean values for each 
note, or the string similarity between the notes of the phrase and 
the given note list, depending on the value of the flag.

=head1 SEE ALSO

L<POE>

L<POE::Framework::MIDI::Rule>

L<POE::Framework::MIDI::Phrase>

L<POE::Framework::MIDI::Note>

L<POE::Framework::MIDI::Rule::Utility>

L<String::Similarity>

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
