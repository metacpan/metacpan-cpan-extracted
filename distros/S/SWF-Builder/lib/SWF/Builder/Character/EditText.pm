package SWF::Builder::Character::EditText;

use strict;
use utf8;

our $VERSION="0.02";

@SWF::Builder::Character::EditText::ISA = qw/ SWF::Builder::Character::Displayable SWF::Builder::ExElement::Color::AddColor/;

####

@SWF::Builder::Character::EditText::Imported::ISA = qw/ SWF::Builder::Character::Imported SWF::Builder::Character::EditText /;

####

package SWF::Builder::Character::EditText::Def;

use Carp;
use SWF::Element;
use SWF::Builder::ExElement;
use SWF::Builder::Character;

@SWF::Builder::Character::EditText::Def::ISA = qw/ SWF::Builder::Character::EditText /;

sub new {
    my ($class, $font, $text) = @_;
    my $tag;
    
    my $self = bless {
	_current_font => '',
	_tag          => ($tag = SWF::Element::Tag::DefineEditText->new),
    }, $class;
    $self->_init_character;
    $tag->CharacterID($self->{ID});
    $self->_init_is_alpha(1);

    $self->size(12);
    $self->font($font) if defined $font;
    $self->text($text) if defined $text;
    $self;
}

sub font {
    my ($self, $font) = @_;

    croak "Invalid font" unless UNIVERSAL::isa($font, 'SWF::Builder::Character::Font');
    $self->{_tag}->UseOutlines(1) if $font->embed;
    $self->{_tag}->FontID($font->{ID});
    $self->{_current_font} = $font;
    $self->{_depends}{$font} = $font;
    $self;
}

sub size {
    my ($self, $size) = @_;

    $self->{_tag}->FontHeight($size*20);
    $self;
}

sub leading {
    my ($self, $leading) = @_;

    $self->{_tag}->Leading($leading);
    $self;
}

sub color {
    my ($self, $color) = @_;

    $self->{_tag}->TextColor($self->_add_color($color));
    $self;
}

sub text {
    my ($self, $text) = @_;
    
    $self->{_current_font}->add_glyph($text) if $self->{_current_font};
    utf2bin($text);
    my $i = $self->{_tag}->InitialText;
    $self->{_tag}->InitialText($i.$text);
    $self;
}

sub box_size {
    my ($self, $w, $h) = @_;

    $w *= 20 if (defined $w);
    $h *= 20 if (defined $h);
    $self->_box_size_in_twips($w, $h);
    $self;
}

sub _box_size_in_twips {
    my ($self, $w, $h) = @_;

    my $tag = $self->{_tag};
    $tag->AutoSize(0);
    unless (defined $w) {
	$w = $tag->Bounds->Xmax - $tag->Bounds->Xmin;
    }
    unless (defined $h) {
	$h = $tag->Bounds->Ymax - $tag->Bounds->Ymin;
    }
    $tag->Bounds([Xmin=>0, Ymin=>0, Xmax=>$w, Ymax=>$h]);
    $self;
}


sub draw_border {
    my $self =shift;

    $self->{_tag}->Border(1);
    $self;
}

{
    my %align = (left=>0, right=>1, center=>2, justify=>3);

    sub align {
	my ($self, $align) = @_;

	$self->{_tag}->Align($align{lc($align)});
	$self;
    }
}

sub _pack {
    my ($self, $stream) = @_;
    
    $self->{_tag}->pack($stream);
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    my ($sub) = $AUTOLOAD =~ /::([^:]+)$/;
    return if $sub eq 'DESTROY';
    if ($self->{_tag}->can($sub)) {
	$self->{_tag}->$sub(@_);
	$self;
    } else {
	croak "Can\'t locate object method \"$sub\" via package \"".ref($self).'"';
    }
}

####

package SWF::Builder::Character::HTMLText;

@SWF::Builder::Character::HTMLText::ISA = qw/ SWF::Builder::Character::EditText::Def /;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new;

    $self->ReadOnly(1);
    $self->Multiline(1);
    $self->AutoSize(1);
    $self->HTML(1);
    $self->text($_[0]) if @_;
    $self;
}

sub use_font {
    my $self = shift;

    for my $font (@_) {
      Carp::croak "Invalid font" unless UNIVERSAL::isa($font, 'SWF::Builder::Character::Font');
	$self->{_tag}->UseOutlines(1) if $font->embed;
	$self->{_depends}{$font} = $font;
    }
    $self;
}

####

package SWF::Builder::Character::DynamicText;

@SWF::Builder::Character::DynamicText::ISA = qw/ SWF::Builder::Character::EditText::Def /;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->ReadOnly(1);
    $self->Multiline(1);
    $self->AutoSize(1);
    $self;
}


####

package SWF::Builder::Character::TextArea;

@SWF::Builder::Character::TextArea::ISA = qw/ SWF::Builder::Character::EditText::Def /;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new;

    $self->box_size(@_);
    $self->Multiline(1);
    $self->Border(1);
    $self->WordWrap(1);
    $self;
}

####

package SWF::Builder::Character::InputField;

@SWF::Builder::Character::InputField::ISA = qw/ SWF::Builder::Character::EditText::Def /;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;

    $self->MaxLength($_[0]) if @_;
    $self->Border(1);
    $self->SUPER::box_size(0, 0);
    $self->{_modified_width} = $self->{_modified_height} = 0;
    $self;
}

sub _box_size_in_twips {
    my ($self, $w, $h) = @_;

    $self->SUPER::_box_size_in_twips($w, $h);
    $self->{_modified_width} = 1 if defined $w;
    $self->{_modified_height} = 1 if defined $h;
    $self;
}

sub _pack {
    my ($self, $stream) = @_;

    my $tag = $self->{_tag};
    unless ($self->{_modified_width}) {
	my $w = $self->{_current_font} ? $self->{_current_font}->get_average_width*1.1 : 570;
	my $size = $tag->FontHeight || 1024;
	my $len = $tag->MaxLength || 20;
	$self->_box_size_in_twips($size * $w * $len / 1024 +80);
    }
    unless ($self->{_modified_height}) {
	$self->_box_size_in_twips(undef, $tag->FontHeight+120);
    }
    $self->SUPER::_pack($stream);
}

####

package SWF::Builder::Character::PasswordField;

@SWF::Builder::Character::PasswordField::ISA = qw/ SWF::Builder::Character::InputField /;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $tag = $self->{_tag};

    $tag->Password(1);
    $self;
}

sub font {
    my ($self, $font) = @_;

    $self->SUPER::font($font);
    $self->{_current_font}->add_glyph('*');
    $self;
}

1;
__END__


=head1 NAME

SWF::Builder::Character::EditText - SWF dynamic editable text object

=head1 SYNOPSIS

  my $text = $mc->new_dynamic_text( $font )
    ->size(10)
    ->color('000000')
    ->text('This is a text.');

  my $text_i = $text->place;

  my $field = $mc->new_input_field;
  $field->place;

=head1 DESCRIPTION

This module creates dynamic editable text objects, which can be changed at playing time. 

=head2 Basic dynamic editable text object

=over 4

=item $etext = $mc->new_edit_text( [$font, $text] )

returns a new basic dynamic editable text object. 
It has interfaces to raw DefineEditText tag.
$font is an SWF::Builder::Font object.

=item $etext->font( $font )

applies the font to the text.
$font is an SWF::Builder::Font object.
Unlike static text, the font is applied to the whole text.
If the text will be changed in the playing time, 
you should add glyph data of all characters which will be used 
to the font by $font->add_glyph or turn off the embed flag
of the font.

=item $etext->size( $size )

sets a font size to $size in pixel.
Unlike static text, the font size of the whole text is changed.

=item $etext->color( $color )

sets color of the text.
The color can take a six or eight-figure
hexadecimal string, an array reference of R, G, B, and optional alpha value, 
an array reference of named parameters such as [Red => 255],
and SWF::Element::RGB/RGBA object.
Unlike static text, the color is applied to the whole text.

=item $etext->text( $string )

writes the $string. 

=item $etext->leading( $leading )

sets the vertical distance between the lines in pixel.

=item $etext->box_size( $width, $height )

sets the bounding box of the text and stops auto-sizing the box.
When either $width or $height is undef, it is unchanged.
Fixing bounding box may cause unexpected text clipping.
You should set DefineEditText flag
Multiline and/or WordWrap. See L<SWF::Element>.

=item $etext->draw_border

draws the border.

=item $etext->align( 'left' / 'right' / 'center' / 'justify' )

sets the text alignment.

=item $etext->I<methos for SWF::Element::Tag::DefineEditText>

You can control details of the texts to call methods for DefineEditText tag.
See L<SWF::Element>.

=back

=head2 Preset dynamic text object

The following objects are inheritants of the basic dynamic editable text.
These are preset some proper flags of DefineEditText tag.

=over 4

=item $dtext = $mc->new_dynamic_text( [$font, $text] )

returns a new dynamic text.
It is read-only, multiline text enabled, and auto-sized its bounding box.

=item $htmltext = $mc->new_html_text( [$html] )

returns a new HTML text.
It is read-only, multiline text enabled, and auto-sized its bounding box.
The text is treated as a subset of HTML. Supported tags are E<lt>aE<gt>, 
E<lt>bE<gt>, E<lt>brE<gt>, E<lt>fontE<gt>, E<lt>iE<gt>, E<lt>imgE<gt>,
E<lt>liE<gt>, E<lt>pE<gt>, E<lt>spanE<gt>, E<lt>uE<gt>, and two special
tags, E<lt>tabE<gt> and E<lt>textformatE<gt>.
See Macromedia Flash File Format Specification
and ActionScript Reference Guide for further information.

=item $htmltext->use_font( $font, ... )

tells $htmltext what fonts are used in the HTML.
In general, upright, italic, bold, and bold italic font are in the different
TrueType font files. You should prepare 2-4 fonts if you use E<lt>bE<gt> and 
E<lt>iE<gt> tags, like this:

 my $fp = $ENV{SYSTEMROOT}.'/fonts';  # for Windows.
 my $font = $m->new_font("$fp/arial.ttf");
 $font->add_glyph('a', 'z');
 my $fonti = $m->new_font("$fp/ariali.ttf");
 $fonti->add_glyph('a', 'z');
 my $ht = $m->new_html_text;
 $ht->text('<font face="arial">test <i>string</i></font>');
 $ht->use_font($font, $fonti);

=item $mc->new_text_area( $width, $height )

returns a new editable text area.
It takes area width and height in pixel.

=item $mc->new_input_field( [$length] )

returns a new one-line input field.
$length is a max length of input string.

=item $mc->new_password_field( [$length] )

returns a new one-line password field.
$length is a max length of input string.

=back

=head1 COPYRIGHT

Copyright 2004 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
