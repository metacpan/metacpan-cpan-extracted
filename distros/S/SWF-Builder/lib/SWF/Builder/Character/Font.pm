package SWF::Builder::Character::Font;

use strict;
use utf8;

our $VERSION="0.091";

our %indirect;

@indirect{ ('_sans', '_serif', '_typewriter', "_\x{30b4}\x{30b7}\x{30c3}\x{30af}", "_\x{660e}\x{671d}", "_\x{7b49}\x{5e45}") }
        = ('_sans', '_serif', '_typewriter', "_\x{30b4}\x{30b7}\x{30c3}\x{30af}", "_\x{660e}\x{671d}", "_\x{7b49}\x{5e45}");

@SWF::Builder::Character::Font::ISA = qw/ SWF::Builder::Character /;

####

package SWF::Builder::Character::Font::Imported;

@SWF::Builder::Character::Font::Imported::ISA = qw/ SWF::Builder::Character::Imported SWF::Builder::Character::Font /;

sub embed {1}  # ??
sub add_glyph{}

####

package SWF::Builder::Character::Font::Def;

use Carp;
use SWF::Element;
use SWF::Builder;
use SWF::Builder::ExElement;

@SWF::Builder::Character::Font::Def::ISA = qw/ SWF::Builder::Character::Font /;

sub new {
    my ($class, $fontfile, $fontname) = @_;
    my $tag;
    my $self = bless {
	_embed => 1,
	_average_width => 512,
	_read_only => 0,
	_code_hash => {},
	_glyph_hash => {},
	_tag => ($tag = SWF::Element::Tag::DefineFont2->new),
    }, $class;

    $self->_init_character;
    $tag->FontID($self->{ID});

    if (exists $indirect{$fontfile}) {
	utf2bin($fontfile);
	$tag->FontName($fontfile);
	$self->embed(0);
	return $self;
    }

    eval {$self->_init_font($fontfile, $fontname)};
    if ($@) {
	if ($@ =~ /Can\'t locate object method/) {
	    eval { require SWF::Builder::Character::Font::FreeType }
	    or eval { require SWF::Builder::Character::Font::TTF }
	    or croak "Failed loading font module. It is necessary to install Font-FreeType or Font-TTF to use outline fonts";
	    $self->_init_font($fontfile, $fontname);
	} else {
	    die;
	}
    }
    $self;
}

sub embed {
    my ($self, $embed) = @_;

    if (defined $embed) {
	$self->{_embed} = $embed;
    }
    return $self->{_embed};
}

sub is_readonly {
    shift->{_read_only};
}

sub get_average_width {
    shift->{_average_width};
}

sub glyph_shape {
    my ($self, $char) = @_;

    if (exists $self->{_glyph_hash}{$char} and defined $self->{_glyph_hash}{$char}[1]) {
	return $self->{_glyph_hash}{$char}[1];
    } else {
	my $gshape = SWF::Builder::Character::Font::Glyph->new;
	$self->{_glyph_hash}{$char}[1] = $gshape;
	return $gshape;
    }
}

sub add_glyph {
    my ($self, $string, $e_char) = @_;
    my @chars;

    return unless $self->{_embed};

    my $hash = $self->{_glyph_hash};

    if (defined $e_char) {
	@chars = map {chr} (ord($string) .. ord($e_char));
    } else {
	@chars = split //, $string;
    }

    for my $c (@chars) {
	next if $hash->{$c};

	my $gshape = $self->glyph_shape($c);
	my $adv = $self->_draw_glyph($c, $gshape);
	$hash->{$c} = [$adv, $gshape];
    }
}

sub LanguageCode {
    my ($self, $code) = @_;

    unless (defined $code) {
	my $l = $self->{_tag}->LanguageCode->value;
	return ('none', 'Latin', 'Japanese', 'Korean', 'Simplified Chinese', 'Traditional Chinese')[$l];
    } elsif ($code!~/\d+/) {
	($code) = 'none:0 Latin:1 Japanese:2 Korean:3 Simplified Chinese:4 Traditional Chinese:5'=~/\b$code.*?:(\d)/i;
    }
    $self->{_tag}->LanguageCode($code);
}

sub AUTOLOAD {
    my $self = shift; 
    our $AUTOLOAD;
    my ($sub) = $AUTOLOAD=~/::([^:]+)$/;
    return if $sub eq 'DESTROY';
    my $tag = $self->{_tag};

    if ($tag->can($sub)) {
	$tag->$sub(@_);
    } elsif ($tag->can(my $fsub="FontFlags$sub")) {
	$tag->$fsub(@_);
    } else {
	croak "Can\'t locate object method \"$sub\" via package \"".ref($self).'"';
    }
}

my $emprect = SWF::Element::RECT->new(Xmin => 0, Ymin => 0, Xmax => 0, Ymax => 0);

sub _pack {
    my ($self, $stream) = @_;

    my $tag = $self->{_tag};
    my $hash = $self->{_glyph_hash};
    my ($code_t, $adv_t, $glyph_t, $bounds_t, $kern_t) = 
	($tag->CodeTable, $tag->FontAdvanceTable, $tag->GlyphShapeTable, $tag->FontBoundsTable, $tag->FontKerningTable);

    for my $c (sort keys %{$self->{_glyph_hash}}) {
	push @$code_t, ord($c);
	push @$adv_t, (defined($hash->{$c}[0]) ? $hash->{$c}[0]*20 : $hash->{$c}[1]{_bounds}->Xmax);
	push @$glyph_t, SWF::Element::SHAPE->new(ShapeRecords => $hash->{$c}[1]{_edges});
	push @$bounds_t, $emprect;
    }
    @{$self->{_code_hash}}{@$code_t} = (0..$#$code_t);
    $self->{_tag}->pack($stream);
}

####

package SWF::Builder::Character::Font::Glyph;

use SWF::Builder::Shape;

@SWF::Builder::Character::Font::Glyph::ISA = ('SWF::Builder::Shape');

sub new {
    my $class = shift;

    my $self = $class->SUPER::new;
    $self->fillstyle(1)->linestyle(0);
}


1;
__END__


=head1 NAME

SWF::Builder::Character::Font - SWF font object

=head1 SYNOPSIS

  my $font = $mc->new_font('c:/windows/font/arial.ttf');
  $font->add_glyph('0123456789');

=head1 DESCRIPTION

This module creates SWF fonts from TrueType fonts.

=over 4

=item $font = $mc->new_font( $fontfile [, $fontname] )

returns a new font.
$fontfile is a outline font file name or an indirect font name. 
The font file name should be specified a full path name.  
Supported indirect font names are '_sans', '_serif', '_typewriter', 
"_\x{30b4}\x{30b7}\x{30c3}\x{30af}" ('gosikku' in Japanese katakana), 
"_\x{660e}\x{671d}" ('mincho' in Japanese kanji), 
and "_\x{7b49}\x{5e45}" ('tofuku' in Japanese kanji).
When you use outline fonts, either Font::TTF or Font::FreeType is necessary.
Font::TTF supports TrueType fonts (*.ttf/*.ttc).  Font::FreeType supports TrueType, 
OpenType, and PostScript fonts (*.ttf/*.ttc/*.otf/*.pfb).
Optional $fontname is a font name referred by HTMLs in dynamic texts.
The font name is taken from the TrueType file if not defined.

=item $font->embed( [$embed] )

sets/gets a flag to embed the font or not.

=item $font->is_readonly

gets a permission flag to use the font only 'preview & print'.
If the flag is set, the font cannot be used for text field.
This works properly only when Font::TTF are used and 'OS/2' table are defined in the font.

=item $font->get_average_width

gets the average character width.
This works properly only when Font::TTF are used and 'OS/2' table are defined in the font.

=item $font->add_glyph( $char_string [, $e_char] )

adds glyph data of the characters of the string to the font.
Usually, L<SWF::Builder::character::Text> adds required glyph
data automatically.
It is necessary to do add_glyph if the font is used for a dynamic text 
or a text field which will be changed at playing time. 
if $e_char is present, add_glyph adds glyphs of characters from 
first character of $char_string to first character of $e_char. 
For example, $font->add_glyph('a', 'z') adds glyphs of all lower case alphabet.

=item $font->LanguageCode( $code )

sets the spoken language of texts to which the font is applied.
$code can take 'none', 'Latin', 'Japanese', 'Korean', 'Simplified Chinese', and
'Traditional Chinese'. It can also take a number, 0, 1, 2, 3, 4, and 5,
or an initial, 'n', 'L', 'J', 'K', 'S'(or 'C'), and 'T', respectively.

=back

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
