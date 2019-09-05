package Music::ToRoman;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Convert notes and chords to Roman numeral notation

our $VERSION = '0.1200';

use List::MoreUtils qw/ any first_index /;
use Moo;
use Music::Scales;

use strictures 2;
use namespace::clean;


has scale_note => (
    is      => 'ro',
    isa     => sub { die 'Invalid note' unless _valid_note( $_[0] ) },
    default => sub { 'C' },
);


has scale_name => (
    is      => 'ro',
    isa     => sub { die 'Invalid scale' unless _valid_scale( $_[0] ) },
    default => sub { 'major' },
);


has major_tonic => (
    is      => 'ro',
    isa     => sub { die 'Invalid note' unless _valid_note( $_[0] ) },
    default => sub { 'C' },
);


has chords => (
    is      => 'ro',
    isa     => sub { die 'Invalid boolean' unless $_[0] == 0 || $_[0] == 1 },
    default => sub { 1 },
);


has verbose => (
    is      => 'ro',
    default => sub { 0 },
);


sub parse {
    my ( $self, $chord ) = @_;

    die 'No chord to parse'
        unless $chord;

    my $note_re  = qr/[A-G][#b]?[#b]?/;
    my $upper_re = qr/^[A-Z]+$/;
    my $lower_re = qr/^[a-z]+$/;

    # Literal diatonic modes when chords attribute is zero
    my @roman = qw( I ii iii IV V vi vii ); # Default to major/ionian
    if ( $self->scale_name eq 'dorian' ) {
        @roman = qw( i ii III IV v vi VII );
    }
    elsif ( $self->scale_name eq 'phrygian' ) {
        @roman = qw( i II III iv v VI vii );
    }
    elsif ( $self->scale_name eq 'lydian' ) {
        @roman = qw( I II iii iv V vi vii );
    }
    elsif ( $self->scale_name eq 'mixolydian' ) {
        @roman = qw( I ii iii IV v vi VII );
    }
    elsif ( $self->scale_name eq 'minor' || $self->scale_name eq 'aeolian' ) {
        @roman = qw( i ii III iv v VI VII );
    }
    elsif ( $self->scale_name eq 'locrian' ) {
        @roman = qw( i II iii iv V VI vii );
    }
    print "ROMAN: @roman\n" if $self->verbose;

    # Get the scale notes
    my @notes;
    if ( ( $self->scale_note =~ /##/ || $self->scale_note =~ /bb/ ) && $self->scale_name ne 'major' && $self->scale_name ne 'ionian' ) {
        my %modes = (
            dorian     => 2,
            phrygian   => 3,
            lydian     => 4,
            mixolydian => 5,
            aeolian    => 6,
            minor      => 6,
            locrian    => 7,
        );

        @notes = get_scale_notes( $self->major_tonic, 'major' );

        push @notes, shift @notes for 1 .. $modes{ $self->scale_name } - 1;
    }
    else {
        @notes = get_scale_notes( $self->scale_note, $self->scale_name );
    }
    print "NOTES: @notes\n" if $self->verbose;

    # Convert a diminished chord
    $chord =~ s/dim/o/; # TODO: Handle U+00F8 too

    # Get just the note part of the chord name
    ( my $note = $chord ) =~ s/^($note_re).*$/$1/;

    # Get the roman representation based on the scale position
    my $position = first_index { $_ eq $note } @notes;
    # If the note is not in the scale find a new position and accidental
    my $accidental;
    if ( $position == -1 ) {
        ( $position, $accidental ) = _pos_acc( $note, $position, \@notes );
    }
    $accidental ||= '';
    my $roman = $roman[$position];
    print "ROMAN 1: $roman\n" if $self->verbose;

    # Get everything but the note part
    ( my $decorator = $chord ) =~ s/^(?:$note_re)(.*)$/$1/;

    # Are we minor or diminished?
    my $minor = $decorator =~ /[-mo]/ ? 1 : 0;
    print "NOTE: $note, MINOR: $minor, CHORD: $chord, POSN: $position, ACCI: $accidental, DECO: $decorator\n" if $self->verbose;

    # Convert the case of the roman representation based on minor or major
    if ( $self->chords ) {
        $roman = $minor && $decorator !~ /maj/i ? lc($roman) : uc($roman);
    }

    # Add any accidental found in a non-scale note
    $roman = $accidental . $roman if $accidental;
    print "ROMAN 2: $roman\n" if $self->verbose;

    if ( $decorator =~ /maj/i || $decorator =~ /min/i ) {
        $decorator = lc $decorator;
    }
    else {
        # Drop the minor and major part of the chord name
        $decorator =~ s/M//i;
        $decorator =~ s/-//i;
    }

    # Handle these unfortunate edge cases
    $roman =~ s/#I\b/bII/;
    $roman =~ s/#i\b/bii/;
    $roman =~ s/#II\b/bIII/;
    $roman =~ s/#ii\b/biii/;
    $roman =~ s/#IV\b/bV/;
    $roman =~ s/#iv\b/bv/;
    $roman =~ s/#V\b/bVI/;
    $roman =~ s/#v\b/bvi/;
    $roman =~ s/#VI\b/bVII/;
    $roman =~ s/#vi\b/bvii/;
    print "ROMAN 3: $roman\n" if $self->verbose;

    # A remaining note name is a bass decorator
    if ( $decorator =~ /($note_re)/ ) {
        my $name = $1;
        $position = first_index { $_ eq $name } @notes;
        print "BASS NOTE: $name, POSN: $position\n" if $self->verbose;
        if ( $position >= 0 ) {
            $decorator =~ s/$note_re/$roman[$position]/;
        }
        else {
            ( $position, $accidental ) = _pos_acc( $name, $position, \@notes );
            print "NEW POSN: $position, ACCI: $accidental\n" if $self->verbose;
            my $bass = $accidental . $roman[$position];
            $decorator =~ s/$note_re/$bass/;

            # Handle these unfortunate edge cases
            if ( $decorator =~ /#I\b/i && $roman[1] =~ /$upper_re/ ) {
                $decorator =~ s/#I\b/bII/i;
            }
            elsif ( $decorator =~ /#I\b/i && $roman[1] =~ /$lower_re/ ) {
                $decorator =~ s/#I\b/bii/i;
            }
            elsif ( $decorator =~ /#II\b/i && $roman[2] =~ /$upper_re/ ) {
                $decorator =~ s/#II\b/bIII/i;
            }
            elsif ( $decorator =~ /#II\b/i && $roman[2] =~ /$lower_re/ ) {
                $decorator =~ s/#II\b/biii/i;
            }
            elsif ( $decorator =~ /#IV\b/i && $roman[4] =~ /$upper_re/ ) {
                $decorator =~ s/#IV\b/bV/i;
            }
            elsif ( $decorator =~ /#IV\b/i && $roman[4] =~ /$lower_re/ ) {
                $decorator =~ s/#IV\b/bv/i;
            }
            elsif ( $decorator =~ /#V\b/i && $roman[5] =~ /$upper_re/ ) {
                $decorator =~ s/#V\b/bVI/i;
            }
            elsif ( $decorator =~ /#V\b/i && $roman[5] =~ /$lower_re/ ) {
                $decorator =~ s/#V\b/bvi/i;
            }
            elsif ( $decorator =~ /#VI\b/i && $roman[6] =~ /$upper_re/ ) {
                $decorator =~ s/#VI\b/bVII/i;
            }
            elsif ( $decorator =~ /#VI\b/i && $roman[6] =~ /$lower_re/ ) {
                $decorator =~ s/#VI\b/bvii/i;
            }
        }
        print "NEW DECO: $decorator\n" if $self->verbose;
    }

    # Append the remaining decorator to the roman representation
    $roman .= $decorator;
    print "ROMAN 4: $roman\n" if $self->verbose;

    return $roman;
}

sub _pos_acc {
    my ( $note, $position, $notes ) = @_;

    my $accidental;

    # If the note has no accidental...
    if ( length($note) == 1 ) {
        # Find the scale position of the closest note
        $position = first_index { $_ =~ /$note/ } @$notes;
        # Get the accidental of the scale note
        ( $accidental = $notes->[$position] ) =~ s/^[A-G](.)$/$1/;
        # TODO: Why?
        $accidental = $accidental eq '#' ? 'b' : '#';
    }
    else {
        # Get the accidental of the given note
        ( my $letter, $accidental ) = $note =~ /^([A-G])(.)$/;
        # Get the scale position of the closest note
        $position = first_index { $_ eq $letter } @$notes;
    }

    return $position, $accidental;
}

sub _valid_note {
    my ($note) = @_;

    my @valid = ();

    my @notes = 'A' .. 'G';

    push @valid, @notes;
    push @valid, map { $_ . '#' } @notes;
    push @valid, map { $_ . '##' } @notes;
    push @valid, map { $_ . 'b' } @notes;
    push @valid, map { $_ . 'bb' } @notes;

    return any { $_ eq $note } @valid;
}

sub _valid_scale {
    my ($name) = @_;

    my @valid = qw(
        ionian
        major
        dorian
        phrygian
        lydian
        mixolydian
        aeolian
        minor
        locrian
    );

    return any { $_ eq $name } @valid;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::ToRoman - Convert notes and chords to Roman numeral notation

=head1 VERSION

version 0.1200

=head1 SYNOPSIS

  use Music::ToRoman;

  my $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
  );

  my $roman = $mtr->parse('Am');  # i (minor)
  $roman = $mtr->parse('Bo');     # iio (diminished)
  $roman = $mtr->parse('Bdim');   # iio (diminished)
  $roman = $mtr->parse('Bb');     # bII (flat-two major)
  $roman = $mtr->parse('CM');     # III (major)
  $roman = $mtr->parse('C');      # III (major)
  $roman = $mtr->parse('Cm9/G');  # iii9/VII (minor ninth with seven bass)
  $roman = $mtr->parse('Cm9/Bb'); # iii9/bii (minor ninth with flat-two bass)
  $roman = $mtr->parse('D sus4'); # IV sus4 (major suspended)
  $roman = $mtr->parse('DMaj7');  # IV maj7 (major seventh)
  $roman = $mtr->parse('E7');     # V7 (dominant seventh)
  $roman = $mtr->parse('Em7');    # v7 (minor seventh)
  $roman = $mtr->parse('Fmin7');  # vi min7 (minor seventh)
  $roman = $mtr->parse('G+');     # VII+ (augmented)

  $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'dorian',
    chords     => 0,
  );

  $roman = $mtr->parse('A');      # i
  $roman = $mtr->parse('B');      # ii
  $roman = $mtr->parse('C');      # III
  $roman = $mtr->parse('D');      # IV
  $roman = $mtr->parse('E');      # v
  $roman = $mtr->parse('F#');     # vi
  $roman = $mtr->parse('G');      # VII
  $roman = $mtr->parse('Amin7');  # i min7
  $roman = $mtr->parse('Bo');     # iio
  $roman = $mtr->parse('CMaj7');  # III maj7
  $roman = $mtr->parse('D7');     # IV7
  $roman = $mtr->parse('Em');     # v

=head1 DESCRIPTION

C<Music::ToRoman> converts named chords to Roman numeral notation.
Also individual "chordless" notes may be converted given a diatonic
mode B<scale_name>.

=head1 ATTRIBUTES

=head2 scale_note

Note on which the scale is based.  Default: C<C>

This must be an uppercase letter from C<A-G> either alone or followed
by C<#> or C<b>.

Note that the keys of C<A#>, C<D#>, C<E#> and C<Fb> are better
represented by C<Gb>, C<Eb>, C<F> and C<E> respectively, because they
contain notes with double accidentals.

=head2 scale_name

Name of the scale.  Default: C<major>

The diatonic mode names supported are:

  ionian / major
  dorian
  phrygian
  lydian
  mixolydian
  aeolian / minor
  locrian

=head2 major_tonic

Note on which the C<major> scale is based.  Default: C<'C'>

This must be an uppercase letter from C<A-G> and followed by a C<#> or
C<b>.

This attribute is required when the B<scale_note> is set to a
double-accidental, and the B<scale_name> is not C<major> (or
C<ionian>).

=head2 chords

Are we given chords to parse with major (C<M>) or minor
(C<m>/C<o>/C<dim>) designations?

Default: C<1>

If this is set to C<0>, single notes can be used to return the
major/minor Roman numeral for the given diatonic mode B<scale_name>.

=head2 verbose

Show the progress of the B<parse> method.  Default C<0>

=head1 METHODS

=head2 new

  $mtr = Music::ToRoman->new(
    scale_note  => $note,
    scale_name  => $name,
    major_tonic => $tonic,
    chords      => $chords,
    verbose     => $verbose,
  );

Create a new C<Music::ToRoman> object.

=head2 parse

  $roman = $mtr->parse($chord);

Parse a note or chord name into a Roman numeral representation.

For instance, the Roman numeral representation for the C<aeolian> (or
minor) mode is: C<i ii III iv v VI VII> - where the case indicates the
major/minor status of the given chord.

This can be overridden by parsing say, C<BM7> (B dominant seventh),
thus producing C<II7>.

If a major/minor chord designation is not provided, C<M> major is
assumed.

A diminished chord may be given as either C<o> or C<dim>.

If the B<chords> attribute is set to C<0>, the B<scale_name> is used
to figure out the correct Roman numeral representation.

If the B<scale_note> is a double-accidental, and the B<scale_name> is
not C<major> (or C<ionian>), the B<major_tonic> must be set in the
constructor.

=head1 SEE ALSO

L<List::MoreUtils>

L<Moo>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Roman_numeral_analysis>

For example usage, check out the test files F<t/*-methods.t> in this
distribution.  Also see F<eg/roman> and F<eg/basslines> in
L<Music::BachChoralHarmony>.

L<App::MusicTools> C<vov> is the reverse of this module, and is
significantly powerful.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
