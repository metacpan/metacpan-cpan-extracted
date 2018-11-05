package Music::ToRoman;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Convert chords to Roman numeral notation

our $VERSION = '0.0300';

use Moo;
use strictures 2;
use namespace::clean;

use List::MoreUtils 'first_index';
use Music::Scales;


has scale_note => (
    is      => 'ro',
    default => sub { 'C' },
);


has scale_name => (
    is      => 'ro',
    default => sub { 'major' },
);


has chords => (
    is      => 'ro',
    default => sub { 1 },
);


sub parse {
    my ( $self, $chord ) = @_;

    # XXX Assume minor if not major!
    my @roman = $self->scale_name eq 'major'
        ? qw( I ii iii IV V vi vii )
        : qw( i ii III iv v VI VII );

    # Get the scale notes
    my @notes = get_scale_notes( $self->scale_note, $self->scale_name );

    # Get just the note part of the chord name
    ( my $note = $chord ) =~ s/^(\w[#b]?).*$/$1/;

    # Get the roman representation based on the scale position
    my $position = first_index { $_ eq $note } @notes;
    my ( $roman, $accidental );
    if ( $position == -1 ) {
        if ( length($note) == 1 ) {
            $position = first_index { $_ =~ /$note/ } @notes;
            ( $accidental = $notes[$position] ) =~ s/^\w(.)$/$1/;
            $accidental = $accidental eq '#' ? 'b' : '#';
        }
        else {
            my $letter;
            ( $letter, $accidental ) = $note =~ /^(\w)(.)$/;
            $position = first_index { $_ eq $letter } @notes;
        }
    }
    $roman = $roman[$position];

    # Get everything but the note part
    ( my $decorator = $chord ) =~ s/^(?:\w[#b]?)(.*)$/$1/;

    # Are we minor or diminished?
    my $minor = $decorator =~ /[mo]/ ? 1 : 0;

    # Convert the case of the roman representation based on minor or major
    if ( $self->chords ) {
        $roman = $minor ? lc($roman) : uc($roman);
    }

    # Add any accidental found in a non-scale note
    $roman = $accidental . $roman if $accidental;

    # Drop the minor and major part of the chord name
    $decorator =~ s/M//i;

    if ( $decorator =~ /([A-G])/ ) {
        my $letter = $1;
        $position = first_index { $_ eq $letter } @notes;
        $decorator =~ s/[A-G]/$roman[$position]/;
    }

    # Append the remaining decorator to the roman representation
    $roman .= $decorator;

    return $roman;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::ToRoman - Convert chords to Roman numeral notation

=head1 VERSION

version 0.0300

=head1 SYNOPSIS

  use Music::ToRoman;

  my $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
  );
  my $roman = $mtr->parse('Am'); # i (minor)
  $roman = $mtr->parse('Bo');    # iio (diminished)
  $roman = $mtr->parse('CM');    # III (major)
  $roman = $mtr->parse('Em7');   # v7 (minor seventh)
  $roman = $mtr->parse('A+');    # I+ (augmented)
  $roman = $mtr->parse('BbM');   # bII (flat-two major)

  # Also:
  $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
    chords     => 0,
  );
  $roman = $mtr->parse('A'); # i
  $roman = $mtr->parse('B'); # ii
  $roman = $mtr->parse('C'); # III

=head1 DESCRIPTION

C<Music::ToRoman> converts chords to Roman numeral notation.

=head1 ATTRIBUTES

=head2 scale_note

Note on which the scale is based.  This can be one of C, D, E, F, G, A or B.

Default: C

=head2 scale_name

Name of the scale.  See L<Music::Scales/SCALES> for the possible names.

Default: major

=head2 chords

Are we given chords with major ("M") and minor ("m") designations?

Default: 1

=head1 METHODS

=head2 new()

  $mtr = Music::ToRoman->new(%arguments);

Create a new C<Music::ToRoman> object.

=head2 parse()

  $roman = $mtr->parse($chord);

Parse a given chord name into a Roman numeral representation.

=head1 SEE ALSO

L<Moo>

L<List::MoreUtils>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Roman_numeral_analysis>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
