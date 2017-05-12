package Music::Chord::Note;

use warnings;
use strict;
use Carp qw( croak );

our $VERSION = '0.07';

my @tone_list = ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
                 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B');

my $base_chord_list = {
    'base'     => '0,4,7',
    '-5'       => '0,4,6',
    '6'        => '0,4,7,9',
    '6(9)'     => '0,4,7,9,14',         '69'       => '0,4,7,9,14',
    'M7'       => '0,4,7,11',
    'M7(9)'    => '0,4,7,11,14',        'M79'       => '0,4,7,11,14',
    'M9'       => '0,4,7,11,14',
    'M11'      => '0,4,7,11,14,17',
    'M13'      => '0,4,7,11,14,17,21',
    '7'        => '0,4,7,10',
    '7(b5)'    => '0,4,6,10',           '7b5'      => '0,4,6,10',
    '7(-5)'    => '0,4,6,10',           '7-5'      => '0,4,6,10',
    '7(b9)'    => '0,4,7,10,13',        '7b9'      => '0,4,7,10,13',
    '7(-9)'    => '0,4,7,10,13',        '7-9'      => '0,4,7,10,13',
    '-9'       => '0,4,7,10,13',
    '-9(#5)'   => '0,4,8,10,13',        '-9#5'     => '0,4,8,10,13',
    '7(b9,13)' => '0,4,7,10,13,21',     '7(-9,13)' => '0,4,7,10,13,21',
    '7(9,13)'  => '0,4,7,10,14,21',
    '7(#9)'    => '0,4,7,10,15',        '7#9'      => '0,4,7,10,15',
    '7(#11)'   => '0,4,7,10,15,18',     '7#11'     => '0,4,7,10,15,18',
    '7(#13)'   => '0,4,10,21',          '7#13'     => '0,4,10,21',
    '9'        => '0,4,7,10,14',
    '9(b5)'    => '0,4,6,10,14',        '9b5'      => '0,4,6,10,14',
    '9(-5)'    => '0,4,6,10,14',        '9-5'      => '0,4,6,10,14',
    '11'       => '0,4,7,10,14,17',
    '13'       => '0,4,7,10,14,17,21',
    'm'        => '0,3,7',
    'm6'       => '0,3,7,9',
    'm6(9)'    => '0,3,7,9,14',          'm69'     => '0,3,7,9,14',
    'mM7'      => '0,3,7,11',
    'm7'       => '0,3,7,10',
    'm7(b5)'   => '0,3,6,10',            'm7b5'    => '0,3,6,10',
    'm7(-5)'   => '0,3,6,10',            'm7-5'    => '0,3,6,10',
    'm7(9)'    => '0,3,7,10,14',         'm79'     => '0,3,7,10,14',
    'm9'       => '0,3,7,10,14',
    'm7(9,11)' => '0,3,7,10,14,17',
    'm11'      => '0,3,7,10,14,17',
    'm13'      => '0,3,7,10,14,17,21',
    'dim'      => '0,3,6',
    'dim7'     => '0,3,6,9',
    'aug'      => '0,4,8',
    'aug7'     => '0,4,8,10',
    'augM7'    => '0,4,8,11',
    'aug9'     => '0,4,8,10,14',
    'sus4'     => '0,5,7',
    '7sus4'    => '0,5,7,10',
    'add2'     => '0,2,4,7',
    'add4'     => '0,4,5,7',
    'add9'     => '0,4,7,14',
};

my $scalic_value = {
    'C'  => 0,
    'C#' => 1, 'Db' => 1,
    'D'  => 2,
    'D#' => 3, 'Eb' => 3,
    'E'  => 4,
    'E#' => 5, 'Fb' => 4, # joke!
    'F'  => 5,
    'F#' => 6, 'Gb' => 6,
    'G'  => 7,
    'G#' => 8, 'Ab' => 8,
    'A'  => 9,
    'A#' => 10, 'Bb' => 10,
    'B'  => 11,
    'Cb' => 11, 'B#' => 0, # joke!
};

sub new
{
    my $class = shift;
    bless {}, $class;
}

sub chord
{
    my ($self, $chord_name) = @_;

    croak "No CHORD_NAME!" unless $chord_name;
    my ($tonic, $kind) = ($chord_name =~ /([A-G][b#]?)(.+)?/);
    croak "unknown chord $chord_name" unless defined $tonic;
    $kind = 'base' unless $kind;
    my $scalic = $scalic_value->{$tonic};
    croak "undefined kind of chord $kind($chord_name)"
        unless defined $base_chord_list->{$kind};

    my @keys;
    for my $scale ( split /\,/, $base_chord_list->{$kind} ){
        my $note = $scale + $scalic;
        $note = int($note % 24) + 12 if $note > 23;
        push @keys, $tone_list[$note];
    }

    return @keys;
}

sub chord_num
{
    my ($self, $chord) = @_;

    $chord = 'base' unless $chord;
    croak "undefined kind of chord ($chord)" unless defined $base_chord_list->{$chord};

    return split /,/, $base_chord_list->{$chord};
}

sub scale
{
    my $self = shift;
    my $note = shift;

    $note =~ s/^([a-g])/uc($1)/e;
    croak "wrong note ($note)" if $note !~ /^[A-G](?:[#b])?$/;

    return $scalic_value->{$note};
}

sub all_chords_list
{
    my $self = shift;

    return [ grep { $_ ne 'base' } keys %{$base_chord_list} ];
}

1;

__END__


=head1 NAME

Music::Chord::Note - get Chord Tone List from Chord Name


=head1 SYNOPSIS

    use Music::Chord::Note;

    my $cn = Music::Chord::Note->new();

    my @tone = $cn->chord('CM7');

    print "@tone"; # C E G B

    my @tone_num = $cn->chord_num('M7');

    print "@tone_num"; # 0 4 7 11

    my $note = $cn->scale('D#');

    print "$note"; # 3


=head1 METHOD

=over

=item new()

constructor

=item chord($chord_name)

get tone list from chord name

=item chord_num($kind_of_chord)

get scalic value list(ex. M7 -> 0 4 7 11)

=item scale($note)

get scalic value from C (C=0, B=11)

=item all_chords_list

get all chords list(ARRAY ref)

=back


=head1 AUTHOR

Copyright (c) 2008, Dai Okabayashi C<< <bayashi@cpan.org> >>


=head1 LICENCE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
