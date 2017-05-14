# $Id: Utility.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Rule::Utility;
use strict;
use Carp 'croak';
use vars '$VERSION'; $VERSION = '0.02';
use base 'Exporter';
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

sub get_durations {
    my $phrase = shift;
    my @durations;

    for ($phrase->events) {
        @durations = map { $_->{cfg}{duration} } @$_;
    }

    return @durations;
}

sub note_interval {
    my ($A, $B) = @_;
    return note_number($B) - note_number($A);
}

sub note_number {
    my $note = shift;
    $note = (is_note_spec(normalize_note($note)))[1];
    return $note ? $note : -1;
}

sub normalize_note { ucfirst lc shift }

sub show_midi_notes {
    print map { sprintf "%-6s => %d\n", $_, $MIDI::Simple::Note{$_} }
        sort scale_sort keys %MIDI::Simple::Note
}

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

sub scale_sort {
    $MIDI::Simple::Note{$a} <=> $MIDI::Simple::Note{$b}
       ||
    $a cmp $b
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Rule::Utility - Utility functions

=head1 ABSTRACT

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 EXPORTED FUNCTIONS

=head2 get_notes()

Return an array of the note names of a phrase.

=head2 get_durations()

Return an array of the note durations of a phrase.

=head2 note_interval()

Return the numerical difference between the two given notes.

=head2 note_number()

Return the note number or -1 for a given note name.

=head2 normalize_note()

Make sure we are looking at a valid note name.

=head1 HELPER FUNCTIONS

These are not used for computation

=head2 show_midi_notes()

Show a simple note name to note number correspondence for every
note in the $MIDI::Simple::Note list.

=head2 show_note_spec()

Print the MIDI::Simple note specification - note name and the 
'Absolute' or 'Relative' nature.

=head2 scale_sort()

A "mostly correct" sort function for proper scale note names.

=head1 SEE ALSO

L<POE>

L<MIDI::Simple>

L<use POE::Framework::MIDI::Phrase>

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
