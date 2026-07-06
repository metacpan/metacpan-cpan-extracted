# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for working with SIRTX font files

package SIRTX::Font::Renderer;

use v5.20;
use strict;
use warnings;

use Carp;
use List::Util ();
use Image::Magick ();

use SIRTX::Font;

our $VERSION = v0.08;



sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {}, $pkg;
    my $font = delete($opts{font}) // croak 'No font given';

    croak 'Stray options passed' if scalar keys %opts;

    $self->{font} = $font;
    $self->{proportional} = undef;

    return $self;
}


#@returns SIRTX::Font
sub font {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{font};
}


sub slant {
    my ($self, @opts) = @_;
    return $self->font(@opts)->get_attribute('slant');
}


sub reverse_slant {
    my ($self, @opts) = @_;
    return $self->font(@opts)->get_attribute('reverse_slant');
}


sub weight {
    my ($self, @opts) = @_;
    return $self->font(@opts)->get_attribute('weight');
}

# reverse_slant weight


sub proportional {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    if (scalar(@_) > 1) {
        $self->{proportional} = $n;
    }

    return $self->{proportional};
}




#@returns Image::Magick
sub render {
    my ($self, $string, @opts) = @_;
    my @lines = split(/\r?\n/, $string);
    my $max_line = List::Util::max(map {length} @lines);
    my $font = $self->font;
    my $width = $font->width;
    my $height = $font->height;
    my $proportional = $self->proportional;
    my $p = Image::Magick->new;
    my %handle_cache;

    croak 'Stray options passed' if scalar @opts;

    $p->Set(size => sprintf('%ux%u', $self->size_of_text($string)));
    $p->Read('canvas:white');

    for (my $row = 0; $row < scalar(@lines); $row++) {
        my $line = $lines[$row];
        my $len  = length($line);
        my $dx = 0;

        for (my $column = 0; $column < $len; $column++) {
            my $c = substr($line, $column, 1);
            my $cp = ord $c;
            my $glyph = $font->glyph_for($cp);
            my $handle = $handle_cache{$cp} //= $font->export_glyph_as_image_magick($glyph);
            my $resync = eval {$font->get_glyph_attribute($glyph, 'resync') } // 0;
            my $preskip = 0;
            my $postskip = 0;

            if ($proportional) {
                $preskip  = eval {$font->get_glyph_attribute($glyph, 'preskip') } // 0;
                $postskip = eval {$font->get_glyph_attribute($glyph, 'postskip') } // 0;
            }

            $dx = $column * $width if $resync;
            $p->CopyPixels(image => $handle, width => $width - $postskip - $preskip, height => $height, x => $preskip, y => 0, dx => $dx, dy => $row * $height);
            $dx += $width - $postskip - $preskip;
        }
    }

    return $p;
}


sub size_of_text {
    my ($self, $string, @opts) = @_;
    my @lines = split(/\r?\n/, $string);
    my $font = $self->font;
    my $width = $font->width;
    my $height = $font->height;
    my $proportional = $self->proportional;
    my $x = 0;
    my $y = scalar(@lines) * $height;

    croak 'Stray options passed' if scalar @opts;

    foreach my $line (@lines) {
        my $len  = length($line);
        my $dx = 0;

        for (my $column = 0; $column < $len; $column++) {
            my $c = substr($line, $column, 1);
            my $cp = ord $c;
            my $glyph = $font->glyph_for($cp);
            my $resync = eval {$font->get_glyph_attribute($glyph, 'resync') } // 0;
            my $preskip = 0;
            my $postskip = 0;

            if ($proportional) {
                $preskip  = eval {$font->get_glyph_attribute($glyph, 'preskip') } // 0;
                $postskip = eval {$font->get_glyph_attribute($glyph, 'postskip') } // 0;
            }
            $dx  = $column * $width if $resync;
            $dx += $width - $postskip - $preskip;
        }

        $x = $dx if $dx > $x;
    }

    return ($x, $y);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::Font::Renderer - module for working with SIRTX font files

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use SIRTX::Font;
    use SIRTX::Font::Renderer;

    my SIRTX::Font $font = SIRTX::Font->new;
    my SIRTX::Font::Renderer = $font->renderer;

(since v0.08)

This module implements an renderer for SIRTX font files.

All methods in this module C<die> on error unless documented otherwise.

=head1 METHODS

=head2 new

    my SIRTX::Font::Renderer $renderer = SIRTX::Font::Renderer->new(font => $font);

(since v0.08)

Creates a new renderer object.

=head2 font

    my SIRTX::Font $font = $renderer->font;

(since v0.08)

Returns the font used by the renderer.

=head2 slant

    my $slant = $renderer->slant;

(since v0.08)

Returns the currently selected slant. If unknown this method dies. See also L<SIRTX::Font/slant>.

=head2 reverse_slant

    my $bool = $renderer->reverse_slant;

(since v0.08)

Returns the currently selected reverse slant. If unknown this method dies. See also L<SIRTX::Font/reverse_slant>.

=head2 weight

    my $weight = $renderer->weight;

(since v0.08)

Returns the currently selected weight. If unknown this method dies. See also L<SIRTX::Font/weight>.

=head2 proportional

    my $bool = $renderer->proportional;
    # or:
    $renderer->proportional($bool)

(since v0.08)

Gets or sets the state of the proportional rendering flag.

=head2 render

    my Image::Magick $image = $renderer->render($string);
    # e.g.:
    my Image::Magick $image = $renderer->render("Hello World!");
    $image->Transparent(color => 'white'); # transparent background
    $image->Write('hello.png');

(experimental since v0.08)

Renders a text using the loaded font.

=head2 size_of_text

    my ($width, $height) = $renderer->size_of_text($string);

(experimental since v0.08)

Calculate the size (in pixel) required to render the given string.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
