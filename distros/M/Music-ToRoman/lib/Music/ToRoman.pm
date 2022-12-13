package Music::ToRoman;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Convert notes and chords to Roman numeral notation

our $VERSION = '0.1902';

use strictures 2;
use List::SomeUtils qw(any first_index);
use Moo;
use Music::Note ();
use Music::Scales qw(get_scale_notes);
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

    my $note_re = qr/[A-G][#b]?[#b]?/;

    # Get the roman representation of the scale
    my @scale = $self->get_scale_mode;
    print "SCALE: @scale\n" if $self->verbose;

    my @notes;

    # If the note has a double sharp and is not in major, manually rotate the scale notes, since Music::Scales does not.
    if ( $self->scale_note =~ /##/ && $self->scale_name ne 'major' && $self->scale_name ne 'ionian' ) {
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

        # Rotate the major scale to the correct mode
        push @notes, shift @notes for 1 .. $modes{ $self->scale_name } - 1;
    }
    else {
        @notes = get_scale_notes( $self->scale_note, $self->scale_name );
    }
    print "NOTES: @notes\n" if $self->verbose;

# XXX Not working?
#    my %ss_enharmonics = (
#        'C##' => 'D',
#        'D##' => 'E',
#        'F##' => 'G',
#        'G##' => 'A',
#        'A##' => 'B',
#    );
#    for ( @notes ) {
#        $_ = $ss_enharmonics{$_}
#            if $ss_enharmonics{$_};
#    }
#use Data::Dumper;warn(__PACKAGE__,' ',__LINE__," MARK: ",Dumper\@notes);

    # Convert a diminished chord
    $chord =~ s/dim/o/;

    # Get just the note part of the chord name
    ( my $note = $chord ) =~ s/^($note_re).*$/$1/;

    my %bb_enharmonics = (
        Cbb => 'Bb',
        Dbb => 'C',
        Ebb => 'D',
        Fbb => 'Eb',
        Gbb => 'F',
        Abb => 'G',
        Bbb => 'A',
    );

    $note = $bb_enharmonics{$note}
        if $note =~ /bb$/;

    # Get the roman representation based on the scale position
    my $position = first_index { $_ eq $note } @notes;

    if ( $position < 0 && ( $note eq 'Cb' || $note eq 'Fb' ) ) {
        $note = 'B'
            if $note eq 'Cb';
        $note = 'E'
            if $note eq 'Fb';
        $position = first_index { $_ eq $note } @notes;
    }
    elsif ( $note eq 'E#' ) { # XXX Why does this work?
        $note = 'F';
    }

    my $accidental = '';
    if ( $position < 0 && $note =~ /[#b]+$/ ) {
        my $n = Music::Note->new( $note, 'isobase' );
        my $name = $n->format('isobase');
        ( $accidental = $name ) =~ s/^[A-G]([#b]+)$/$1/;
        $n->en_eq( $accidental =~ /^#/ ? 'b' : '#' );
        $note = $n->format('isobase');
        $position = first_index { $_ eq $note } @notes;
        $accidental = '';
    }

    # If the note is not in the scale find the new position and accidental
    if ( $position < 0 ) {
        ( $position, $accidental ) = _pos_acc( $note, $position, \@notes );
    }

    my $roman = $scale[$position];
    print "ROMAN 1: $roman\n" if $self->verbose;

    # Get everything but the note part
    ( my $decorator = $chord ) =~ s/^(?:$note_re)(.*)$/$1/;

    # Are we minor or diminished?
    my $minor = $decorator =~ /[-moø]/ ? 1 : 0;
    print "CHORD: $chord, NOTE: $note, NEW ACCI: $accidental, DECO: $decorator, MINOR: $minor, POSN: $position\n" if $self->verbose;

    # Convert the case of the roman representation based on minor or major
    if ( $self->chords ) {
        $roman = $minor && $decorator !~ /maj/i ? lc($roman) : uc($roman);
    }

    # Add any accidental found in a non-scale note
    $roman = $accidental . $roman if $accidental;
    print "ROMAN 2: $roman\n" if $self->verbose;

    # Handle these unfortunate edge cases:
    $roman = _up_to_flat( $roman, \@scale );
    print "ROMAN 3: $roman\n" if $self->verbose;

    # Handle the decorator variations
    if ( $decorator =~ /maj/i || $decorator =~ /min/i ) {
        $decorator = lc $decorator;
    }
    elsif ( $decorator =~ /△/ ) {
        $decorator =~ s/△/maj/;
    }
    elsif ( $decorator =~ /ø/ ) {
        $decorator =~ s/ø/7b5/;
    }
    else {
        # Drop the minor and major part of the chord name
        $decorator =~ s/[-Mm]//i;
    }
    print "DECO: $decorator\n" if $self->verbose;

    # A remaining note name is a bass decorator
    if ( $decorator =~ /($note_re)/ ) {
        my $name = $1;

        $position = first_index { $_ eq $name } @notes;
        print "BASS NOTE: $name, POSN: $position\n" if $self->verbose;

        if ( $position >= 0 ) {
            $decorator =~ s/$note_re/$scale[$position]/;
        }
        else {
            ( $position, $accidental ) = _pos_acc( $name, $position, \@notes );
            print "NEW POSN: $position, ACCI: $accidental\n" if $self->verbose;

            my $bass = $accidental . $scale[$position];
            $decorator =~ s/$note_re/$bass/;

            # Handle these unfortunate edge cases
            $decorator = _up_to_flat( $decorator, \@scale );
        }
        print "NEW DECO: $decorator\n" if $self->verbose;
    }

    # Append the remaining decorator to the roman representation
    $roman .= $decorator;

    $roman =~ s/bI\b/vii/g;
    $roman =~ s/bIV\b/iii/g;

    print "ROMAN 4: $roman\n" if $self->verbose;

    return $roman;
}


sub get_scale_mode {
    my ($self) = @_;

    my @scale = qw( I ii iii IV V vi vii ); # Default to major/ionian

    if ( $self->scale_name eq 'dorian' ) {
        @scale = qw( i ii III IV v vi VII );
    }
    elsif ( $self->scale_name eq 'phrygian' ) {
        @scale = qw( i II III iv v VI vii );
    }
    elsif ( $self->scale_name eq 'lydian' ) {
        @scale = qw( I II iii iv V vi vii );
    }
    elsif ( $self->scale_name eq 'mixolydian' ) {
        @scale = qw( I ii iii IV v vi VII );
    }
    elsif ( $self->scale_name eq 'minor' || $self->scale_name eq 'aeolian' ) {
        @scale = qw( i ii III iv v VI VII );
    }
    elsif ( $self->scale_name eq 'locrian' ) {
        @scale = qw( i II iii iv V VI vii );
    }

    return @scale;
}


sub get_scale_chords {
    my ($self) = @_;

    my %diminished = (
      ionian     => 'vii',
      dorian     => 'vi',
      phrygian   => 'v',
      lydian     => 'iv',
      mixolydian => 'iii',
      aeolian    => 'ii',
      locrian    => 'i',
    );
    my @chords = map { m/^$diminished{ $self->scale_name }$/ ? 'dim' : m/^[A-Z]+$/ ? '' : 'm' } $self->get_scale_mode;

    return @chords;
}

sub _up_to_flat {
    my ($numeral, $roman) = @_;

    # Change a roman sharp to a flat of the succeeding scale position
    $numeral =~ s/#([IV]+)/b$roman->[ ( ( first_index { lc($1) eq lc($_) } @$roman ) + 1 ) % @$roman ]/i;

    return $numeral;
};

sub _pos_acc {
    my ( $note, $position, $notes ) = @_;

    my $accidental;

    # If the note has no accidental...
    if ( length($note) == 1 ) {
        # Find the scale position of the closest similar note
        $position = first_index { $_ =~ /^$note/ } @$notes;

        # Get the accidental of the scale note
        ( $accidental = $notes->[$position] ) =~ s/^[A-G](.)$/$1/;

        # TODO: Explain why.
        $accidental = $accidental eq '#' ? 'b' : '#';
    }
    else {
        # Enharmonic double sharp equivalents
        my %previous_enharmonics = (
            'C#' => 'C##',
            'Db' => 'C##',
            'F#' => 'F##',
            'Gb' => 'F##',
            'G#' => 'G##',
            'Ab' => 'G##',
        );
        $note = $previous_enharmonics{$note}
            if exists $previous_enharmonics{$note} && any { $_ =~ /[CFG]##/ } @$notes;

        # Get the accidental of the given note
        ( my $letter, $accidental ) = $note =~ /^([A-G])(.+)$/;

        # Get the scale position of the closest similar note
        $position = first_index { $_ =~ /^$letter/ } @$notes;

        $accidental = $accidental eq '##' ? 'b' : $accidental;
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

version 0.1902

=head1 SYNOPSIS

  use Music::ToRoman;

  my $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
  );

  my $roman = $mtr->parse('Am');  # i (minor)
  $roman = $mtr->parse('Bdim');   # iio (diminished)
  $roman = $mtr->parse('B dim');  # ii o
  $roman = $mtr->parse('Bo');     # iio
  $roman = $mtr->parse('Bø');     # ii7b5 (half-diminished)
  $roman = $mtr->parse('Bb');     # bII (flat-two major)
  $roman = $mtr->parse('CM');     # III (major)
  $roman = $mtr->parse('C');      # III
  $roman = $mtr->parse('Cm9/G');  # iii9/VII (minor-nine with seven bass)
  $roman = $mtr->parse('Cm9/Bb'); # iii9/bii (minor-nine with flat-two bass)
  $roman = $mtr->parse('Dsus4');  # IVsus4 (suspended)
  $roman = $mtr->parse('D sus4'); # IV sus4
  $roman = $mtr->parse('D maj7'); # IV maj7 (major seventh)
  $roman = $mtr->parse('DMaj7');  # IVmaj7
  $roman = $mtr->parse('D△7');    # IVmaj7
  $roman = $mtr->parse('E7');     # V7 (dominant seventh)
  $roman = $mtr->parse('Fmin7');  # vimin7 (minor seventh)
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
  $roman = $mtr->parse('Amin7');  # imin7
  $roman = $mtr->parse('Bo');     # iio
  $roman = $mtr->parse('CMaj7');  # IIImaj7
  $roman = $mtr->parse('D7');     # IV7
  $roman = $mtr->parse('Em');     # v

  my @mode = $mtr->get_scale_mode;
  my @chords = $mtr->get_scale_chords;

=head1 DESCRIPTION

C<Music::ToRoman> converts named chords to Roman numeral notation.
Also individual "chordless" notes may be converted given a diatonic
mode B<scale_name>.

=head1 ATTRIBUTES

=head2 scale_note

Note on which the scale is based.  Default: C<C>

This must be an uppercase letter from C<A-G> either alone or followed
by C<#> or C<b>.

Note that the keys of C<A#> and C<D#> are better represented by C<Gb>
and C<Eb> respectively, because the scales contain notes with double
sharps.  Double flat scales are not supported.

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
double-sharp, and the B<scale_name> is not C<major> (or C<ionian>).

Again, double flat scales are not supported.

=head2 chords

Are we given chords to parse with major (C<M>) or minor
(C<m>/C<o>/C<dim>/C<ø>) designations?

Default: C<1>

If this is set to C<0>, single notes can be used to return the
major/minor Roman numeral for the given diatonic mode B<scale_name>.

=head2 verbose

Show the progress of the B<parse> method.

Default: C<0>

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

This can be overridden by parsing say, C<B7> (B dominant seventh),
thus producing C<II7>.

If a major/minor chord designation is not provided, C<M> major is
assumed.

If the B<chords> attribute is set to C<0>, the B<scale_name> is used
to figure out the correct Roman numeral representation.

A diminished chord may be given as either C<o> or C<dim>.
Half-diminished (C<m7b5>) chords can be given as C<ø>.  A decoration
of C<△> may be given for say the C<△7> major seventh chord.

Parsing a double flatted chord will only work in select cases.

=head2 get_scale_mode

  @mode = $mtr->get_scale_mode;

Return the Roman representation of the mode.

=head2 get_scale_chords

  @mode = $mtr->get_scale_chords;

Return the chords of the mode.

=head1 SEE ALSO

L<List::MoreUtils>

L<Moo>

L<Music::Note>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Roman_numeral_analysis>

For example usage, check out the test files F<t/*-methods.t> in this
distribution.  Also see F<eg/roman> and F<eg/basslines> in
L<Music::BachChoralHarmony>.

L<App::MusicTools> C<vov> is the reverse of this module, and is
significantly powerful.

=head1 THANK YOU

Dan Book (L<DBOOK|https://metacpan.org/author/DBOOK>) for the list
rotation logic

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
