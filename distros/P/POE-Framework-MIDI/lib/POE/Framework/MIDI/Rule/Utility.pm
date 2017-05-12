# $Id: Utility.pm,v 1.2 2002/09/21 06:43:40 ology Exp $

=head1 DESCRIPTION

Author:  gene@ology.net
Created: 010827
Revised: 011024, 011123

=cut

package POE::Framework::MIDI::Rule::Utility;
use strict;
use warnings;
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = (qw($Revision: 1.2 $))[1];
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT = @EXPORT_OK = qw(
  get_notes
  get_durations
  normalize_note
  note_interval
  note_number
  scale_sort
  show_midi_notes
  show_note_spec
);
use MIDI::Simple;
use POE::Framework::MIDI::Phrase;

=head2 get_notes()

Return an array of the note names of a phrase.

=cut

sub get_notes {
    my $phrase = shift;
    my @notes = ();

    for (@{ $phrase->events }) {
        if (ref =~ /Note/) {
          push @notes, normalize_note($_->name);
        }
        elsif (ref =~ /Rest/) {
          push @notes, '-';
        }
    }

    return @notes;
}

=head2 get_durations()

Return an array of the note durations of a phrase.

=cut

sub get_durations {
    my $phrase = shift;
    return map { $_->duration } $phrase->events;
}


=head2 note_interval()

Return the numerical difference between the two given notes.

=cut

sub note_interval {
    my ($A, $B) = @_;
    return note_number($B) - note_number($A);
}

=head2 note_number()

Return the note number or -1 for a given note name.

=cut

sub note_number {
    my $note = shift;
    $note = (is_note_spec(normalize_note($note)))[1];
    return $note ? $note : -1;
}

=head2 normalize_note()

Make sure we are looking at a valid note name.

=cut

sub normalize_note { ucfirst lc shift }

=head1 HELPER FUNCTIONS

These are not used for computation

=head2 show_midi_notes()

Show a simple note name to note number correspondence for every
note in the $MIDI::Simple::Note list.

=cut

sub show_midi_notes {
    print map { sprintf "%-6s => %d\n", $_, $MIDI::Simple::Note{$_} }
        sort scale_sort keys %MIDI::Simple::Note
}

=head2 show_note_spec()

Print the MIDI::Simple note specification - note name and the 
'Absolute' or 'Relative' nature.

=cut

sub show_note_spec {
    my $note = shift || '';

    if (my @spec = is_note_spec(normalize_note($note))) {
        printf "Note: %s (%d): %s\n", $note, $spec[1],
            $spec[0] ? 'Absolute' : 'Relative'
    }
    else {
        print "No known note specification.\n"
    }
}

=head2 scale_sort()

A "mostly correct" sort function for proper scale note names.

=cut

sub scale_sort {
    $MIDI::Simple::Note{$a} <=> $MIDI::Simple::Note{$b}
       ||
    $a cmp $b
}

1;
