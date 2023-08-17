package Music::ModalFunction;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Inspect musical modal functions

our $VERSION = '0.0315';

use Moo;
use strictures 2;
use AI::Prolog ();
use Carp qw(croak);
use MIDI::Util qw(midi_format);
use Music::Note ();
use Music::Scales qw(get_scale_notes);
use namespace::clean;


has [qw(chord_note chord mode_note mode mode_function mode_roman key_note key key_function key_roman)] => (
    is => 'ro',
);

has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

has _modes => (
    is => 'lazy',
);
sub _build__modes {
    return {
        ionian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'dim', roman => 'r_vii', function => 'leading_tone' }
        ],
        dorian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'dim', roman => 'r_vi',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' }
        ],
        phrygian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'dim', roman => 'r_v',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'subtonic' }
        ],
        lydian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'dim', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'leading_tone' }
        ],
        mixolydian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'dim', roman => 'r_iii', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' }
        ],
        aeolian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'dim', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' }
        ],
        locrian => [
            { chord => 'dim', roman => 'r_i',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'subtonic' }
        ]
    }
}

has _database => (
    is => 'lazy',
);
sub _build__database {
    my ($self) = @_;

    # consider every note
    my @chromatic = get_scale_notes('c', 'chromatic', 0, 'b');
    my $database = '';

    # build a prolog fact for each base note
    for my $base (@chromatic) {
        my ($mode_base) = map { lc } midi_format($base);

        # consider each mode's properties
        for my $mode (sort keys %{ $self->_modes }) {
            # get the 7 notes of the base note mode
            my @notes = get_scale_notes($base, $mode);
            warn "Basics: $base $mode [@notes]\n" if $self->verbose;

            my @pitches; # notes suitable for the prolog database

            # convert the notes to flatted, lower-case
            for my $note (@notes) {
                my $n = Music::Note->new($note, 'isobase');
                $n->en_eq('flat') if $note =~ /#/;
                push @pitches, map { lc } midi_format($n->format('isobase'));
            }

            my $i = 0; # increment for each of 7 diatonic modes

            for my $pitch (@pitches) {
                # get the properties of the given mode
                my $chord    = $self->_modes->{$mode}[$i]{chord};
                my $function = $self->_modes->{$mode}[$i]{function};
                my $roman    = $self->_modes->{$mode}[$i]{roman};

                # append to the database of facts
                $database .= "chord_key($pitch, $chord, $mode_base, $mode, $function, $roman).\n";

                $i++;
            }
        }
    }
    # append the prolog rules
    $database .= <<'RULES';
% Can a chord in one key function in a second?
pivot_chord_keys(ChordNote, Chord, Key1Note, Key1, Key1Function, Key1Roman, Key2Note, Key2, Key2Function, Key2Roman) :-
    % bind the chord to the function of the first key
    chord_key(ChordNote, Chord, Key1Note, Key1, Key1Function, Key1Roman),
    % bind the chord to the function of the second key
    chord_key(ChordNote, Chord, Key2Note, Key2, Key2Function, Key2Roman),
    % the functions cannot be the same
    Key1Function \= Key2Function.

% TODO
roman_key(Mode, ModeRoman, Key, KeyRoman) :-
    chord_key(_, _, _, Mode, ModeFunction, ModeRoman),
    chord_key(_, _, _, Key, KeyFunction, KeyRoman),
    ModeFunction \= KeyFunction.
RULES
    warn "Database: $database\n" if $self->verbose;

    return $database;
}

has _prolog => (
    is => 'lazy',
);
sub _build__prolog {
    my ($self) = @_;
    return AI::Prolog->new($self->_database);
}


sub chord_key {
    my ($self) = @_;
    my $query = sprintf 'chord_key(%s, %s, %s, %s, %s, %s).',
        defined $self->chord_note   ? $self->chord_note   : 'ChordNote',
        defined $self->chord        ? $self->chord        : 'Chord',
        defined $self->key_note     ? $self->key_note     : 'KeyNote',
        defined $self->key          ? $self->key          : 'Key',
        defined $self->key_function ? $self->key_function : 'KeyFunction',
        defined $self->key_roman    ? $self->key_roman    : 'KeyRoman';
    return $self->_querydb($query);
}


sub pivot_chord_keys {
    my ($self) = @_;
    my $query = sprintf 'pivot_chord_keys(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s).',
        defined $self->chord_note    ? $self->chord_note    : 'ChordNote',
        defined $self->chord         ? $self->chord         : 'Chord',
        defined $self->mode_note     ? $self->mode_note     : 'ModeNote',
        defined $self->mode          ? $self->mode          : 'Mode',
        defined $self->mode_function ? $self->mode_function : 'ModeFunction',
        defined $self->mode_roman    ? $self->mode_roman    : 'ModeRoman',
        defined $self->key_note      ? $self->key_note      : 'KeyNote',
        defined $self->key           ? $self->key           : 'Key',
        defined $self->key_function  ? $self->key_function  : 'KeyFunction',
        defined $self->key_roman     ? $self->key_roman     : 'KeyRoman';
    return $self->_querydb($query);
}


sub roman_key {
    my ($self) = @_;
    my $query = sprintf 'roman_key(%s, %s, %s, %s).',
        defined $self->mode       ? $self->mode       : 'Mode',
        defined $self->mode_roman ? $self->mode_roman : 'ModeRoman',
        defined $self->key        ? $self->key        : 'Key',
        defined $self->key_roman  ? $self->key_roman  : 'KeyRoman';
    return $self->_querydb($query);
}

sub _querydb {
    my ($self, $query) = @_;

    warn "Query: $query\n" if $self->verbose;

    $self->_prolog->query($query);

    my @return;

    while (my $result = $self->_prolog->results) {
        push @return, $result;
    }

    return \@return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::ModalFunction - Inspect musical modal functions

=head1 VERSION

version 0.0315

=head1 SYNOPSIS

  use Music::ModalFunction ();

  # What mode(s) have a Dmaj dominant chord?
  my $m = Music::ModalFunction->new(
    chord_note   => 'd',
    chord        => 'maj',
    key_function => 'dominant',
  );
  my $results = $m->chord_key;
  # [['chord_key','d','maj','g','ionian','dominant','r_V'],
  #  ['chord_key','d','maj','g','lydian','dominant','r_V']]

  # In what mode(s) can a Gmaj chord function as a subdominant pivot chord?
  $m = Music::ModalFunction->new(
    chord_note   => 'g',
    chord        => 'maj',
    mode_note    => 'c',
    key_function => 'subdominant',
  );
  $results = $m->pivot_chord_keys;
  # [['pivot_chord_keys','g','maj','c','ionian','dominant','d','dorian','subdominant','r_IV'],
  #  ['pivot_chord_keys','g','maj','c','ionian','dominant','d','ionian','subdominant','r_IV'],
  #  ['pivot_chord_keys','g','maj','c','ionian','dominant','d','mixolydian','subdominant','r_IV'],
  #  ['pivot_chord_keys','g','maj','c','lydian','dominant','d','dorian','subdominant','r_IV'],
  #  ['pivot_chord_keys','g','maj','c','lydian','dominant','d','ionian','subdominant','r_IV'],
  #  ['pivot_chord_keys','g','maj','c','lydian','dominant','d','mixolydian','subdominant','r_IV']]

=head1 DESCRIPTION

C<Music::ModalFunction> allows querying of a musical database of
Prolog facts and rules that bind notes, chords, modes, keys and
diatonic functionality. In this database, the facts are all called
C<chord_key> and the rules are C<pivot_chord_keys> and C<roman_key>.

To bind a value to a fact or rule argument, declare it in the object
constructor. Unbound arguments will return all the possible values
that make the query true.

The essential question is, "Can a chord in one key function in a
second?" Any parts of this open-ended question may be unbound, thereby
resulting in all possible truths.

=head1 ATTRIBUTES

=head2 chord_note

C<c>, C<df>, C<d>, C<ef>, C<e>, C<f>, C<gf>, C<g>, C<af>, C<a>, C<bf>, or C<b>

* Sharps are not used - only flats.

=head2 chord

C<maj>, C<min>, or C<dim>

=head2 mode_note

C<c>, C<df>, C<d>, C<ef>, C<e>, C<f>, C<gf>, C<g>, C<af>, C<a>, C<bf>, or C<b>

=head2 mode

C<ionian>, C<dorian>, C<phrygian>, C<lydian>, C<mixolydian>, C<aeolian>, or C<locrian>

=head2 mode_function

C<tonic>, C<supertonic>, C<mediant>, C<subdominant>, C<dominant>, C<submediant>, C<leading_tone>, or C<subtonic>

=head2 mode_roman

C<r_I>, C<r_ii>, C<r_iii>, C<r_IV>, C<r_V>, C<r_vi>, or C<r_vii>

=head2 key_note

C<c>, C<df>, C<d>, C<ef>, C<e>, C<f>, C<gf>, C<g>, C<af>, C<a>, C<bf>, or C<b>

=head2 key

C<ionian>, C<dorian>, C<phrygian>, C<lydian>, C<mixolydian>, C<aeolian>, or C<locrian>

=head2 key_function

C<tonic>, C<supertonic>, C<mediant>, C<subdominant>, C<dominant>, C<submediant>, C<leading_tone>, or C<subtonic>

=head2 key_roman

C<r_I>, C<r_ii>, C<r_iii>, C<r_IV>, C<r_V>, C<r_vi>, or C<r_vii>

=head2 verbose

Default: C<0>

=head1 METHODS

=head2 new

  $m = Music::ModalFunction->new(%args);

Create a new C<Music::ModalFunction> object.

=head2 chord_key

  $results = $m->chord_key;

Ask the database a question about what chords are in what keys.

Constructor arguments:

  chord_note, chord, key_note, key, key_function, key_roman

Here, B<chord_note> and B<chord> together are the named chord defined
within the context of the B<key_note> and B<key>. The chord's function
in the key is the B<key_function> and basically indicates the relative
scale position. The B<key_roman> argument serves as an indicator of
both the chord quality and the position in the scale.

If defined, argument values will be bound to a variable. Otherwise an
unbound variable is used.

=head2 pivot_chord_keys

  $results = $m->pivot_chord_keys;

Ask the database a question about what chords share common keys.

Constructor arguments:

  chord_note, chord, mode_note, mode, mode_function, mode_roman, key_note, key, key_function, key_roman

Here, B<chord_note> and B<chord> together are the named chord defined
within the context of the B<mode_note> and B<mode>. The chord's
function in the mode is the B<mode_function> and basically indicates
the relative scale position. The B<mode_roman> argument serves as an
indicator of both the chord quality and the position in the scale. The
B<key_note> and B<key> are the final "destination" of the query
transformation (often a pivot). The function of the chord in the
"destination" is B<key_function>. As with mode_roman, B<key_roman> is
the resulting chord quality and scale position.

If defined, argument values will be bound to a variable. Otherwise an
unbound variable is used.

=head2 roman_key

  $results = $m->roman_key;

Ask the database a question about what Roman numeral functional chords
share common keys.

Constructor arguments:

  mode, mode_roman, key, key_roman

If defined, argument values will be bound to a variable. Otherwise an
unbound variable is used.

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> files in this distribution

L<Moo>

L<AI::Prolog>

L<MIDI::Util>

L<Music::Note>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Prolog>

L<https://en.wikipedia.org/wiki/Common_chord_(music)>

L<https://ology.github.io/2023/06/05/querying-a-music-theory-database/>
is the write-up about using this module

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
