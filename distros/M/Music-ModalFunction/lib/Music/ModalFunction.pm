package Music::ModalFunction;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Inspect musical modal functions

our $VERSION = '0.0501';

use strictures 2;
use AI::Prolog ();
use Carp qw(croak);
use MIDI::Util qw(midi_format);
use Moo;
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

has use_scales => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

has hash_results => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

has _chord_key => (
    is      => 'ro',
    default => sub { [qw(method chord_note chord key_note key key_function key_roman)] },
);

has _pivot_chord_keys => (
    is      => 'ro',
    default => sub { [qw(method chord_note chord mode_note mode mode_function mode_roman key_note key key_function key_roman)] },
);

has _roman_key => (
    is      => 'ro',
    default => sub { [qw(method mode mode_roman key key_roman)] },
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
            { chord => 'dim', roman => 'r_vii', function => 'leading_tone' },
        ],
        dorian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'dim', roman => 'r_vi',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' },
        ],
        phrygian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'dim', roman => 'r_v',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'subtonic' },
        ],
        lydian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'dim', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'leading_tone' },
        ],
        mixolydian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'dim', roman => 'r_iii', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' },
        ],
        aeolian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'dim', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' },
        ],
        locrian => [
            { chord => 'dim', roman => 'r_i',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'subtonic' },
        ],
    }
}

has _scales => (
    is => 'lazy',
);
sub _build__scales {
    return {
        harmonic_minor => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'dim', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'aug', roman => 'r_III', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'dim', roman => 'r_vii', function => 'subtonic' },
        ],
        melodic_minor => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'aug', roman => 'r_III', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'dim', roman => 'r_vi',  function => 'submediant' },
            { chord => 'dim', roman => 'r_vii', function => 'subtonic' },
        ],
        pentatonic => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
        ],
        pentatonic_minor => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'dim', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
        ],
        blues => [
            { chord => 'min',  roman => 'r_i',   function => 'tonic' },
            { chord => 'maj',  roman => 'r_III', function => 'supertonic' },
            { chord => 'sus4', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'maj',  roman => 'r_bV',  function => 'flat5' },
            { chord => 'min',  roman => 'r_v',   function => 'dominant' },
            { chord => 'sus4', roman => 'r_VII', function => 'leading_tone' },
        ],
        diminished => [
            { chord => 'maj', roman => 'r_I',    function => 'tonic' },
            { chord => 'dim', roman => 'r_bII',  function => 'flat2' },
            { chord => 'maj', roman => 'r_bIII', function => 'flat3' },
            { chord => 'dim', roman => 'r_iii',  function => 'mediant' },
            { chord => 'maj', roman => 'r_bV',   function => 'flat5' },
            { chord => 'dim', roman => 'r_v',    function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',   function => 'submediant' },
            { chord => 'dim', roman => 'r_vii',  function => 'leading_tone' },
        ],
        augmented => [
            { chord => 'aug', roman => 'r_I',    function => 'tonic' },
            { chord => 'aug', roman => 'r_bIII', function => 'flat3' },
            { chord => 'maj', roman => 'r_III',  function => 'mediant' },
            { chord => 'maj', roman => 'r_V',    function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',   function => 'submediant' },
            { chord => 'aug', roman => 'r_VII',  function => 'leading_tone' },
        ],
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

    my $list = $self->use_scales ? $self->_scales : $self->_modes;

    # build a prolog fact for each base note
    for my $base (@chromatic) {
        my ($mode_base) = map { lc } midi_format($base);

        # consider each mode or scale properties
        for my $j (sort keys %$list) {
            # get the notes of the base note mode or scale
            my @notes = get_scale_notes($base, $j);
#            warn "Basics: $base $j [@notes]\n" if $self->verbose;

            my @pitches; # notes suitable for the prolog database

            # convert the notes to flatted, lower-case
            for my $note (@notes) {
                my $n = Music::Note->new($note, 'isobase');
                $n->en_eq('flat') if $note =~ /#/;
                push @pitches, map { lc } midi_format($n->format('isobase'));
            }

            my $i = 0; # increment for each diatonic modes or scales

            for my $pitch (@pitches) {
                # get the properties of the given mode or scale
                my ($chord, $function, $roman);
                if ($self->use_scales) {
                    $chord    = $self->_scales->{$j}[$i]{chord};
                    $function = $self->_scales->{$j}[$i]{function};
                    $roman    = $self->_scales->{$j}[$i]{roman};
                }
                else {
                    $chord    = $self->_modes->{$j}[$i]{chord};
                    $function = $self->_modes->{$j}[$i]{function};
                    $roman    = $self->_modes->{$j}[$i]{roman};
                }

                # append to the database of facts
                $database .= "chord_key($pitch, $chord, $mode_base, $j, $function, $roman).\n"
                    if $chord && $function && $roman;

                $i++;
            }
        }
    }
    # append the prolog rules
    $database .= <<'RULES';
pivot_chord_keys(ChordNote, Chord, Key1Note, Key1, Key1Function, Key1Roman, Key2Note, Key2, Key2Function, Key2Roman) :-
    % bind the chord to the function of the first key
    chord_key(ChordNote, Chord, Key1Note, Key1, Key1Function, Key1Roman),
    % bind the chord to the function of the second key
    chord_key(ChordNote, Chord, Key2Note, Key2, Key2Function, Key2Roman),
    % the functions cannot be the same
    Key1Function \= Key2Function.

roman_key(Mode, ModeRoman, Key, KeyRoman) :-
    chord_key(_, _, _, Mode, ModeFunction, ModeRoman),
    chord_key(_, _, _, Key, KeyFunction, KeyRoman),
    ModeFunction \= KeyFunction.
RULES
#    warn "Database: $database\n" if $self->verbose;

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
    return $self->_querydb('chord_key', $query);
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
    return $self->_querydb('pivot_chord_keys', $query);
}


sub roman_key {
    my ($self) = @_;
    my $query = sprintf 'roman_key(%s, %s, %s, %s).',
        defined $self->mode       ? $self->mode       : 'Mode',
        defined $self->mode_roman ? $self->mode_roman : 'ModeRoman',
        defined $self->key        ? $self->key        : 'Key',
        defined $self->key_roman  ? $self->key_roman  : 'KeyRoman';
    return $self->_querydb('roman_key', $query);
}

sub _querydb {
    my ($self, $method, $query) = @_;

    warn "$method query: $query\n" if $self->verbose;

    $self->_prolog->query($query);

    my $attr = '_' . $method;

    my @return;

    while (my $result = $self->_prolog->results) {
#warn __PACKAGE__,' L',__LINE__,' ',,"R: @$result\n";
        if ($self->hash_results) {
            my %result;
            @result{ @{ $self->$attr } } = @$result;
            push @return, \%result;
        }
        else {
            push @return, $result;
        }
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

version 0.0501

=head1 SYNOPSIS

  use Music::ModalFunction ();

  # What chords do C major and A minor have in common?
  my $m = Music::ModalFunction->new(
    mode_note    => 'c',
    mode         => 'ionian',
    key_note     => 'a',
    key          => 'aeolian',
  );
  my $results = $m->pivot_chord_keys; # 7 common chords

  # What chords do C major and F♯ (G♭) major have in common?
  $m = Music::ModalFunction->new(
    mode_note    => 'c',
    mode         => 'ionian',
    key_note     => 'gb',
    key          => 'ionian',
  );
  $results = $m->pivot_chord_keys; # No chords in common!

  # What modes can have a Dmaj dominant chord?
  $m = Music::ModalFunction->new(
    chord_note   => 'd',
    chord        => 'maj',
    key_function => 'dominant',
  );
  $results = $m->chord_key;
  # [[ 'chord_key', 'd', 'maj', 'g', 'ionian', 'dominant', 'r_V' ],
  #  [ 'chord_key', 'd', 'maj', 'g', 'lydian', 'dominant', 'r_V' ]]
  # So the answers are G Ionian and G Lydian.

  # In what modes can a Gmaj chord function as a subdominant pivot chord?
  $m = Music::ModalFunction->new(
    chord_note   => 'g',
    chord        => 'maj',
    key_function => 'subdominant',
    hash_results => 1,
  );
  $results = $m->pivot_chord_keys;
  # [{ method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'ionian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'dorian', key_function => 'subdominant', key_roman => 'r_IV' },
  #  { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'ionian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'ionian', key_function => 'subdominant', key_roman => 'r_IV' },
  #  { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'ionian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'mixolydian', key_function => 'subdominant', key_roman => 'r_IV' },
  #  ... ]
  # Inspecting all the results, we see that the answers are D Dorian, D Ionian, and D Mixolydian.

  # compare non-modal scales
  $m = Music::ModalFunction->new(
      mode_note  => 'c',
      mode       => 'diminished',
      key_note   => 'c',
      key        => 'harmonic_minor',
      use_scales => 1,
  );
  $results = $m->pivot_chord_keys;
  # [ 'pivot_chord_keys', 'd', 'dim', 'c', 'diminished', 'flat2', 'r_bII', 'c', 'harmonic_minor', 'supertonic', 'r_ii' ],
  # [ 'pivot_chord_keys', 'b', 'dim', 'c', 'diminished', 'leading_tone', 'r_vii', 'c', 'harmonic_minor', 'subtonic', 'r_vii' ],

=head1 DESCRIPTION

C<Music::ModalFunction> allows querying of a musical database of
Prolog facts and rules that bind notes, chords, modes/scales, keys and
diatonic functionality. In this database, the facts are all called
C<chord_key> and the rules are C<pivot_chord_keys> and C<roman_key>.

Wikipedia puts it this way, "A common chord, in the theory of harmony,
is a chord that is diatonic to more than one key or, in other words,
is common to (shared by) two keys."

To bind a value to a fact or rule argument, declare it in the object
constructor. Unbound arguments will return all the possible values
that make the query true.

The essential question is, "Can a chord in one key function in a
second?" Any parts of this open-ended question may be unbound, thereby
resulting in all possible truths.

nb: The names "mode" (and "scale"), and "key" below, are both used to
mean modes (or scales) 1 and 2, respectively. But for some reason I
chose to use "key" even though that is confusing. Argh! :|

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

=head2 hash_results

Return the query results as a list of named hash references.

Default: C<0>

=head2 use_scales

Use alternative scales instead of modes.

Default: C<0>

=head2 scales

C<augmented>, C<blues>, C<diminished>, C<harmonic_minor>,
C<melodic_minor>, C<pentatonic>, or C<pentatonic_minor>

=head2 verbose

Default: C<0>

=head1 METHODS

=head2 new

  $m = Music::ModalFunction->new(%args);

Create a new C<Music::ModalFunction> object.

If defined, argument values will be bound to a variable. Otherwise an
unbound variable is used for the queries detailed below.

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

=head2 roman_key

  $results = $m->roman_key;

Ask the database a question about what Roman numeral functional chords
share common keys.

Constructor arguments:

  mode, mode_roman, key, key_roman

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> files in this distribution

L<Moo>

L<AI::Prolog>

L<MIDI::Util>

L<Music::Note>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Prolog>

L<https://en.wikipedia.org/wiki/Common_chord_(music)>

L<https://en.wikipedia.org/wiki/Closely_related_key>

L<https://ology.github.io/2023/06/05/querying-a-music-theory-database/>
is the write-up about using this module

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2024 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
