#! perl

use strict;
use warnings;

package Music::ChordBot::Opus::Section;

=head1 NAME

Music::ChordBot::Opus::Section - ChordBot song section.

=cut

our $VERSION = 0.01;

use parent 'Music::ChordBot::Opus::Base';

use Music::ChordBot::Opus::Section::Chord;
use Music::ChordBot::Opus::Section::Style;

=head1 SYNOPSIS

    use Music::ChordBot::Opus::Section;
    my $sect = Music::ChordBot::Opus::Section->new;
    $sect->name("First movement");
    $sect->set_style("Kubiac");
    $sect->add_chord(...);
    $sect->add_chord(...);

=cut

#### TODO: Repeat sections.
#
# A repeat section has a name, optionally a style, and no chords. The
# field 'repeat' contains the index of the original section that is to
# be repeated. This can be tricky when inserting/deleting sections.

=head1 METHODS

=head2 new [ args ]

Creates a new Music::ChordBot::Opus::Section object.

Initial attributes may be passed as a hash.

Attributes:

=over 4

=item name

The name of the section.

=item chords

An arrayref containing Music::ChordBot::Opus::Section::Chord objects,
more commonly known as 'chords',

=item style

A hashref representing the attributes of a style. See
L<Music::ChordBot::Opus::Section::Style>.

=cut

sub new {
    my $pkg = shift;
    my $data = { name => "Section 1",
		 chords => [],
		 style => { chorus => 4, reverb => 8,
			    tracks => [ { volume => 7, id => 95 } ] },
		 @_ };
    bless { data => $data }, $pkg;
}

=head2 name [ I<value> ]

Sets or gets the name of the section.

=cut

sub name { shift->_setget( "name", @_ ) }

=head2 add_chord I<chord>

Adds a chord to the section.

I<chord> must be a Music::ChordBot::Opus::Section::Chord object, or a
string denoting a chord, e.g. "C Maj 4". For convenience, the three
elements may also be passed separately, e.g., C<add_chord("C", "Maj",
4)>.

A bass note can be specified by adding the note to the key, separated
by a slash, e.g., C<"C/B">.

=cut

sub add_chord {
    my ( $self, $chord ) = @_;
    my $ok = 0;
    eval { push( @{$self->{data}->{chords}}, $chord->{data} ); $ok = 1 };
    return if $ok;
    shift;
    push( @{$self->{data}->{chords}},
	  Music::ChordBot::Opus::Section::Chord->new(@_)->data );
}

sub chords {
    wantarray
      ? @{ $_[0]->{data}->{chords} }
      : $_[0]->{data}->{chords};
}

=head2 no_style

A newly created Music::ChordBot::Opus::Section object has a default
style associated. Calling this method removes the style from the
section.

=cut

sub no_style {
    delete $_[0]->{data}->{style};
}

=head2 set_style [ I<style> ]

Sets the style for the section.

I<style> must be a Music::ChordBot::Opus::Section::Style object, or the
name of a predefined (preset) style.

If I<style> is omitted, the current style is removed from the section.

=cut

sub set_style {
    my ( $self, $style ) = @_;
    $self->no_style, return unless defined $style;
    my $ok = 0;
    eval { $self->{data}->{style} = $style->{data}; $ok = 1 };
    return if $ok;
    $self->{data}->{style} =
      Music::ChordBot::Opus::Section::Style->preset($style)->data;
}

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Music::ChordBot>.

=cut

1;
