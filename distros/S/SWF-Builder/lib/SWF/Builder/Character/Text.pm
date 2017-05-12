package SWF::Builder::Character::Text;

use strict;
use utf8;

our $VERSION="0.04";

@SWF::Builder::Character::Text::ISA = qw/ SWF::Builder::Character::UsableAsMask /;
@SWF::Builder::Character::Text::Imported::ISA = qw/ SWF::Builder::Character::Imported SWF::Builder::Character::Text /;
@SWF::Builder::Character::StaticText::Imported::ISA = qw/ SWF::Builder::Character::Text::Imported /;

####

package SWF::Builder::Character::Text::Def;

use Carp;
use SWF::Element;
use SWF::Builder::Character;
use SWF::Builder::Character::Font;
use SWF::Builder::ExElement;

@SWF::Builder::Character::Text::Def::ISA = qw/ SWF::Builder::Character::Text SWF::Builder::ExElement::Color::AddColor/;

sub new {
    my ($class, $font, $text) = @_;
    my $tag;
    my $self = bless {
	_bounds       => SWF::Builder::ExElement::BoundaryRect->new,
	_textrecords  => SWF::Element::Array::TEXTRECORDARRAY2->new,
	_kerning      => 1,
	_current_font => '',
	_current_size => 12,
	_max_ascent   => 0,
	_max_descent  => 0,
	_p_max_descent=> 0,
	_current_X    => 0,
	_current_Y    => 0,
	_leading      => 0,
	_nl           => undef,
	_nl_X         => 0,
	_nlbounds     => SWF::Builder::ExElement::BoundaryRect->new,
    }, $class;
    $self->_init_character;
    $self->_init_is_alpha;
    $self->{_nl} = $self->_get_last_record;    
    $self->font($font) if defined $font;
    $self->text($text) if defined $text;
    $self;
}

sub _get_last_record {
    my $self = shift;
    my $records = $self->{_textrecords};
    my $r;

    if (!@$records or $records->[-1]->GlyphEntries->defined) {
	$r = SWF::Element::TEXTRECORD2->new;
	push @$records, $r;
	return $r;
    } else {
	return $records->[-1];
    }
}

sub font {
    my ($self, $font) = @_;
    return if $font eq $self->{_current_font};
    croak "Invalid font" unless UNIVERSAL::isa($font, 'SWF::Builder::Character::Font');
    croak "The font applied to the static text needs to embed glyph data" unless $font->embed;
    my $r = $self->_get_last_record;
    my $size = $self->{_current_size};
    $r->TextHeight($size*20);
    $r->FontID($font->{ID});
    $self->{_current_font} = $font;
    $self->_depends($font);
    my $as  = $font->{_tag}->FontAscent  * $size / 1024;
    my $des = $font->{_tag}->FontDescent * $size / 1024;
    $self->{_max_ascent}  = $as  if $self->{_max_ascent}  < $as;
    $self->{_max_descent} = $des if $self->{_max_descent} < $des;
    $self;
}

sub size {
    my ($self, $size) = @_;
    my $r = $self->_get_last_record;
    $r->TextHeight($size*20);
    $r->FontID($self->{_current_font}->{ID});
    $self->{_current_size} = $size;
    my $as  = $self->{_current_font}{_tag}->FontAscent  * $size / 1024;
    my $des = $self->{_current_font}{_tag}->FontDescent * $size / 1024;
    $self->{_max_ascent}  = $as  if $self->{_max_ascent}  < $as;
    $self->{_max_descent} = $des if $self->{_max_descent} < $des;
    $self;
}

sub kerning {
    my ($self, $kern) = @_;

    if (defined $kern) {
	$self->{_kerning} = $kern;
	$self;
    } else {
	$self->{_kerning};
    }
}

sub leading {
    my ($self, $leading) = @_;
    if (defined $leading) {
	$self->{_leading} = $leading;
	$self;
    } else {
	$self->{_leading};
    }
}

sub color {
    my ($self, $color) = @_;
    my $r = $self->_get_last_record;
    $color = $self->_add_color($color);
    $r->TextColor($color);
    $self;
}

sub _bbox_adjust {
    my $self = $_[0];  # Don't use 'shift'
    my $nl = $self->{_nl};
    my $nlbbox = $self->{_nlbounds};
    return unless defined $nlbbox->[0];

    my $s = $self->{_current_Y} + $self->{_max_ascent} + $self->{_p_max_descent};

    $self->{_bounds}->set_boundary($nlbbox->[0], $nlbbox->[1]+$s*20, $nlbbox->[2], $nlbbox->[3]+$s*20);
    $self->{_nlbounds} = SWF::Builder::ExElement::BoundaryRect->new;
}

sub _line_adjust {
    my $self = $_[0];  # Don't use 'shift'
    &_bbox_adjust;
    $self->{_current_Y} += $self->{_max_ascent} + $self->{_p_max_descent};
    $self->{_nl}->YOffset($self->{_current_Y}*20);
    my $size = $self->{_current_size};
    my $ft = $self->{_current_font}{_tag};
    $self->{_max_ascent}  = $ft->FontAscent  * $size / 1024;
    $self->{_max_descent} = $ft->FontDescent * $size / 1024;
    $self->{_nl} = undef;
}

sub position {
    &_line_adjust;
    goto &_position;
}

sub _position {
    my ($self, $x, $y) = @_;
    my $r = $self->_get_last_record;
    $r->XOffset($x*20);
    $r->YOffset($y*20);
    $self->{_bounds}->set_boundary($x*20, $y*20, $x*20, $y*20);
    $self->{_current_X} = $self->{_nl_X} = $x;
    $self->{_current_Y} = $y;
    $self->{_nl} = $r;
    $self->{_p_max_descent} = 0;
    $self;
}

sub text {
    my ($self, $text) = @_;
    my @text = split /([\x00-\x1f]+)/, $text;
    my $font = $self->{_current_font};
    my $scale = $self->{_current_size} / 51.2;
    my $glyph_hash = $font->{_glyph_hash};
    
    while (my($text, $ctrl) = splice(@text, 0, 2)) {
	my $bbox = $self->{_nlbounds};
	$font->add_glyph($text);
	my @chars = split //, $text;
	if (@chars) {
	    my $gent = $self->{_textrecords}[-1]->GlyphEntries;
	    my $c1 = shift @chars;
	    push @chars, undef;
	    my $x = $self->{_current_X};
	    for my $c (@chars) {
		my $ord_c1 = ord($c1);
		my $kern = ($self->{_kerning} and defined $c) ? $font->kern($ord_c1, ord($c)) : 0;
#		my $kern = 0;
		my $adv = ($glyph_hash->{$c1}[0] + $kern) * $scale;
		my $b = $glyph_hash->{$c1}[1]{_bounds};
		if (defined $b->[0]) {
		    $bbox->set_boundary($x*20+$b->[0]*$scale, $b->[1]*$scale, $x*20+$b->[2]*$scale, $b->[3]*$scale);
		} else {
		    $bbox->set_boundary($x*20, 0, $x*20, 0);
		}
		push @$gent, SWF::Builder::Text::GLYPHENTRY->new($ord_c1, $adv, $font);
		$x += $adv;
		$c1 = $c;
	    }
	    $self->{_current_X} = $x;
	}

	if ($ctrl and (my $n = $ctrl=~tr/\n/\n/)) {
	    my $md = $self->{_max_descent};
	    my $height = $self->{_max_ascent} + $md;
	    $self->_line_adjust;
#	    $self->_position($self->{_nl_X}, $self->{_current_Y} + $height * ($n-1) + ($font->{_tag}->FontLeading * $scale / 20 + $self->{_leading})*$n);
	    $self->_position($self->{_nl_X}, $self->{_current_Y} + $height * ($n-1) + $self->{_leading} * $n);
	    $self->{_p_max_descent} = $md;
	}
    }
    $self;
}

sub get_bbox {
    my $self = shift;
    $self->_bbox_adjust;
    return map{$_/20} @{$self->{_bounds}};
}

sub _pack {
    my ($self, $stream) = @_;
    
    $self->_line_adjust if $self->{_nl};
    
    my $x = $self->{_current_X} = 0;
    my $y = $self->{_current_Y} = 0;
    
    my $tag;
    if ($self->{_is_alpha}) {
	$tag = SWF::Element::Tag::DefineText2->new;
    } else {
	$tag = SWF::Element::Tag::DefineText->new;
    }
    $tag->configure( CharacterID => $self->{ID},
		     TextBounds  => $self->{_bounds},
		     TextRecords => $self->{_textrecords},
		     );
    $tag->pack($stream);

}


####

{
    package SWF::Builder::Text::GLYPHENTRY;
    @SWF::Builder::Text::GLYPHENTRY::ISA = ('SWF::Element::GLYPHENTRY');

    sub new {
	my ($class, $code, $adv, $font) = @_;
	bless [$code, $adv*20, $font->{_code_hash}], $class;
    }

    sub GlyphIndex {
	my $self = shift;

	return $self->[2]{$self->[0]};
    }

    sub GlyphAdvance {
	return shift->[1];
    }
}

1;
__END__


=head1 NAME

SWF::Builder::Character::Text - SWF static text object

=head1 SYNOPSIS

  my $text = $mc->new_static_text( $font )
    ->size(10)
    ->color('000000')
    ->text('This is a text.');

  my $text_i = $text->place;

=head1 DESCRIPTION

This module creates static texts, which cannot be changed at playing time.

=over 4

=item $text = $mc->new_static_text( [$font, $text] )

returns a new static text.
$font is an SWF::Builder::Font object.

=item $text->font( $font )

applies the font to the following text.
$font is an SWF::Builder::Font object.

=item $text->size( $size )

sets a font size to $size in pixel.

=item $text->color( $color )

sets color of the following text.
The color can take a six or eight-figure
hexadecimal string, an array reference of R, G, B, and optional alpha value, 
an array reference of named parameters such as [Red => 255],
and SWF::Element::RGB/RGBA object.

=item $text->text( $string )

writes the $string.  The glyph data of the applied font is embedded if needed.
The string can also include a newline code, "\n".

=item $text->position( $x, $y )

sets the position of the following text.
($x, $y) are coordinates in pixel relative to the I<origin> of the text object.

=item $text->leading( $leading )

sets the vertical distance between the lines in pixel.

=item $text->kerning( [$kerning] )

sets/gets a flag to adjust spacing between kern pair. 

=item $text->get_bbox

returns the bounding box of the text, a list of coordinates
( top-left X, top-left Y, bottom-right X, bottom-right Y ).

=item $text_i = $text->place( ... )

returns the display instance of the text. See L<SWF::Builder>.

=back

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
