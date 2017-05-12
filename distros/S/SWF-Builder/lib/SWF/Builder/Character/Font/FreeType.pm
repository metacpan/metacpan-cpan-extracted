package SWF::Builder::Character::Font::FreeType;

our $VERSION="0.02";

####

package SWF::Builder::Character::Font::Def;

use strict;
use utf8;

use SWF::Builder::ExElement;
use SWF::Builder::Shape;
use Font::FreeType;
use Carp;

@SWF::Builder::Character::Font::FreeType::ISA = qw/ SWF::Builder::Character::Font::Def /;

sub _init_font {
    my ($self, $fontfile, $fontname) = @_;

    my $tag = $self->{_tag};

    my $font = Font::FreeType->new->face($fontfile, load_flags => FT_LOAD_NO_HINTING)
	or croak "Can't open font file '$fontfile'";

    if ($font->number_of_faces > 1 and $fontname and $fontname ne $font->family_name and $fontname ne $font->postscript_name) {
	for (my $i = 1; $i < $font->number_of_faces; $i++) {
	    $font = Font::FreeType->new->face($fontfile, index => $i, load_flags => FT_LOAD_NO_HINTING);
	    last if ($fontname eq $font->family_name or $fontname eq $font->postscript_name);
	}
    }
    $self->{_freetype} = $font;
    unless ($fontname ||= $font->family_name || $font->postscript_name) {
	($fontname) = ($fontfile =~ /.*\/([^\\\/.]+)/);
    }
    utf2bin($fontname);
    $tag->FontName($fontname);
    $font->set_char_size(72, 72, 1024, 1024);
    $tag->FontAscent($font->ascender);
    $tag->FontDescent(-$font->descender);
    $tag->FontLeading($font->height - $font->ascender + $font->descender);
    $tag->FontFlagsBold(1) if $font->is_bold;
    $tag->FontFlagsItalic(1) if $font->is_italic;

    $self;
}

sub get_fontnames {
    my ($self, $fontfile) = @_;
    my $font =  Font::FreeType->new->face($fontfile)
	or croak "Can't open font file '$fontfile'";
    my @names;
    for my $i (1..$font->number_of_faces) {
	$font = Font::FreeType->new->face($fontfile, $i);
	push @names, [$font->family_name, $font->postscript_name];
    }
    return \@names;
}

sub kern {
    my ($self, $code1, $code2) = @_;
    my $font = $self->{_freetype};
    my $g1 = $font->glyph_from_char_code($code1) or return 0;
    my $g2 = $font->glyph_from_char_code($code2) or return 0;
    return $font->kerning($g1->index, $g2->index, FT_KERNING_UNFITTED );
}

sub _draw_glyph {
    my ($self, $c, $gshape) = @_;

    return unless $self->{_embed};
    my $g = $self->{_freetype}->glyph_from_char_code(ord $c) or return;
    my $gs = $gshape->transform([ScaleY=>-1]);
    $g->outline_decompose
	( move_to => sub { $gs->_moveto_twips(@_) },
	  line_to => sub { $gs->_lineto_twips(@_) },
	  conic_to => sub { my @c = splice(@_, 0, 2); $gs->_curveto_twips(@_, @c) },
	  cubic_to => sub { my @c = splice(@_, 0, 2); @c = map {$_/20} @_, @c; $gs->curve3to(@c) },
	  );
    return $g->horizontal_advance/20;
}

1;
