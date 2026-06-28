package PDF::Make::Builder::Page::HeaderFooterContext;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Font;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Page::HeaderFooterContext',
        'builder:Any:required',
        'page:Any:required',
        'canvas:Any:required',
        'x0:Num:required',
        'y0:Num:required',
        'w:Num:required',
        'h:Num:required',
        'padding:Num:default(20)',
        'num:Int:default(0)',
        'role:Str:default(header)',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Page::HeaderFooterContext');
}

# ── Region accessors ──────────────────────────────────────

sub left     { my $s = shift; x0 $s }
sub right    { my $s = shift; x0($s) + w($s) }
sub bottom   { my $s = shift; y0 $s }
sub top      { my $s = shift; y0($s) + h($s) }
sub center_x { my $s = shift; x0($s) + w($s) / 2 }
sub center_y { my $s = shift; y0($s) + h($s) / 2 }

sub baseline {
    my ($self, $offset) = @_;
    $offset //= 0;
    return y0($self) + $offset;
}

sub inset {
    my ($self, $dx, $dy) = @_;
    $dy = $dx unless defined $dy;
    return (x0($self) + $dx, y0($self) + $dy,
            w($self) - 2 * $dx, h($self) - 2 * $dy);
}

# ── Font helpers ──────────────────────────────────────────

sub _font {
    my ($self, $override) = @_;
    my $base = $self->builder->font;
    return $base unless $override;
    return PDF::Make::Builder::Font->new(
        colour      => $override->{colour}      // $base->colour,
        size        => $override->{size}        // $base->size,
        family      => $override->{family}      // $base->family,
        bold        => $override->{bold}        // $base->bold,
        italic      => $override->{italic}      // $base->italic,
        line_height => $override->{line_height} // $base->effective_line_height,
    );
}

sub _default_baseline_y {
    my ($self, $font_size) = @_;
    if ($self->role eq 'footer') {
        return $self->bottom + 4;
    }
    return $self->top - $font_size;
}

# ── Text ──────────────────────────────────────────────────

sub text {
    my ($self, %args) = @_;
    my $txt = $args{text};
    return $self unless defined $txt && length $txt;

    my $font = $self->_font($args{font});
    my $size = $font->size;
    my $res  = $font->ensure_loaded($self->page->xs_page);
    my ($r, $g, $b) = $font->hex_to_rgb($font->colour);

    my $tw = $font->measure_text($txt);

    my $align = $args{align} // 'left';
    my $pad   = defined $args{padding} ? $args{padding} : $self->padding;

    my $x = $args{x};
    if (!defined $x) {
        if    ($align eq 'right')  { $x = $self->right    - $pad - $tw }
        elsif ($align eq 'center') { $x = $self->center_x - $tw / 2 }
        else                       { $x = $self->left     + $pad }
    }

    my $y = $args{y};
    $y = $self->_default_baseline_y($size) unless defined $y;

    $self->canvas->BT
          ->rg($r, $g, $b)
          ->Tf($res, $size)
          ->Tm(1, 0, 0, 1, $x, $y)
          ->Tj($txt)
          ->ET;
    return $self;
}

sub page_num {
    my ($self, %args) = @_;
    my $format = $args{format} // $args{text} // 'Page {num}';
    my $n      = $self->num;
    $format =~ s/\{num\}/$n/g;
    if ($format =~ /\{total\}/) {
        my $total = $self->builder->page_count;
        $format =~ s/\{total\}/$total/g;
    }

    my $font = $args{font} // {};
    my %font = (
        size   => $font->{size}   // 8,
        colour => $font->{colour} // '#666',
        (exists $font->{family} ? (family => $font->{family}) : ()),
        (exists $font->{bold}   ? (bold   => $font->{bold})   : ()),
        (exists $font->{italic} ? (italic => $font->{italic}) : ()),
    );
    return $self->text(
        text    => $format,
        align   => $args{align} // 'right',
        x       => $args{x},
        y       => $args{y},
        padding => $args{padding},
        font    => \%font,
    );
}

# ── Shapes ────────────────────────────────────────────────

sub line {
    my ($self, %args) = @_;
    my ($x1, $y1, $x2, $y2);
    if ($args{from} && $args{to}) {
        ($x1, $y1) = @{$args{from}};
        ($x2, $y2) = @{$args{to}};
    } else {
        $x1 = $args{x1} // $self->left;
        $y1 = $args{y1} // $self->bottom;
        $x2 = $args{x2} // $self->right;
        $y2 = $args{y2} // $y1;
    }
    my $colour = $args{colour} // $args{fill_colour} // '#000';
    my $font = $self->builder->font;
    my ($r, $g, $b) = $font->hex_to_rgb($colour);
    my $canvas = $self->canvas;

    $canvas->q->w($args{width} // 1)->RG($r, $g, $b);

    my $type = $args{type} // 'solid';
    if ($args{dash}) {
        $canvas->d($args{dash}, 0);
    } elsif ($type eq 'dashed') {
        $canvas->d([6, 3], 0);
    } elsif ($type eq 'dots') {
        $canvas->J(1)->d([0, 4], 0);
    }

    $canvas->m($x1, $y1)->l($x2, $y2)->S->Q;
    return $self;
}

sub box {
    my ($self, %args) = @_;
    my $x = $args{x} // $self->left;
    my $y = $args{y} // $self->bottom;
    my $w = $args{w} // $self->w;
    my $h = $args{h} // $self->h;
    my $colour = $args{fill_colour} // $args{colour} // '#000';
    my $font = $self->builder->font;
    my ($r, $g, $b) = $font->hex_to_rgb($colour);
    my $canvas = $self->canvas;

    $canvas->q;
    if ($colour eq 'transparent') {
        $canvas->w($args{width} // 1)->RG($r, $g, $b)->re($x, $y, $w, $h)->S;
    } else {
        $canvas->rg($r, $g, $b)->re($x, $y, $w, $h)->f;
    }
    $canvas->Q;
    return $self;
}

# ── Image ─────────────────────────────────────────────────

sub image {
    my ($self, %args) = @_;
    require PDF::Make::Image;

    my $src = $args{src} // $args{image}
        or die "HeaderFooterContext::image requires src or image";
    my $img = PDF::Make::Image->from_file($src);
    my $img_w = $img->width;
    my $img_h = $img->height;

    my $doc = $self->builder->doc;
    my $obj_num = $img->write_to_doc($doc);
    my $res_name = 'Im' . $obj_num;
    $self->page->xs_page->add_image($res_name, $obj_num);

    my $draw_w = $args{w};
    my $draw_h = $args{h};
    if (!defined $draw_w && !defined $draw_h) {
        $draw_h = $self->h;
        $draw_w = $draw_h * ($img_w / $img_h);
    } elsif (!defined $draw_h) {
        $draw_h = $draw_w * ($img_h / $img_w);
    } elsif (!defined $draw_w) {
        $draw_w = $draw_h * ($img_w / $img_h);
    }

    my $align = $args{align} // 'left';
    my $pad   = defined $args{padding} ? $args{padding} : $self->padding;
    my $x = $args{x};
    if (!defined $x) {
        if    ($align eq 'right')  { $x = $self->right    - $pad - $draw_w }
        elsif ($align eq 'center') { $x = $self->center_x - $draw_w / 2 }
        else                       { $x = $self->left     + $pad }
    }
    my $y = $args{y} // ($self->bottom + ($self->h - $draw_h) / 2);

    $self->canvas->image($res_name, $x, $y, $draw_w, $draw_h);
    return $self;
}

# ── Annotations ───────────────────────────────────────────

sub _rect {
    my ($self, %args) = @_;
    return $args{rect} if $args{rect};
    my $x = $args{x};
    my $y = $args{y};
    my $w = $args{w};
    my $h = $args{h};
    die "HeaderFooterContext: annotation requires rect or x/y/w/h"
        unless defined $x && defined $y && defined $w && defined $h;
    return [$x, $y, $x + $w, $y + $h];
}

sub note {
    my ($self, %args) = @_;
    my $rect = $self->_rect(%args);
    my $text = $args{text} // '';
    my $icon = $args{icon} // 'Note';
    my $open = $args{open} // 0;
    my $xs_doc = $self->builder->doc;
    my $annot_num = $xs_doc->add_text_annot(@$rect, $text, $icon, $open);
    $self->page->xs_page->add_annot($annot_num) if $annot_num;
    return $self;
}

sub link {
    my ($self, %args) = @_;
    my $rect = $self->_rect(%args);
    my $xs_doc = $self->builder->doc;
    my $hl = $args{highlight} // 'Invert';
    my $annot_num;
    if ($args{url}) {
        $annot_num = $xs_doc->add_link_uri(@$rect, $args{url});
    } elsif (defined $args{page}) {
        $annot_num = $xs_doc->add_link_goto(@$rect, $args{page});
    } elsif ($args{action}) {
        $annot_num = $xs_doc->add_link_named_action(@$rect, $args{action}, $hl);
    } elsif ($args{file}) {
        my $action = $xs_doc->action_gotor(
            $args{file}, $args{file_page} // 0, $args{new_window} // 0);
        $annot_num = $xs_doc->add_link_with_action(@$rect, $action, $hl);
    } else {
        die "HeaderFooterContext::link requires url, page, action, or file";
    }
    $self->page->xs_page->add_annot($annot_num) if $annot_num;
    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Page::HeaderFooterContext - Region-aware helpers for
header/footer render callbacks

=head1 SYNOPSIS

    $builder->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $ctx = $args{ctx};

            $ctx->text(text => 'My Document',  align => 'left',  font => { size => 10, bold => 1 });
            $ctx->page_num(format => 'Page {num} of {total}', align => 'right');
            $ctx->line(y1 => $ctx->bottom + 2, y2 => $ctx->bottom + 2, colour => '#999');
        },
    );

=head1 DESCRIPTION

Passed as the C<ctx> keyword to header/footer C<cb> callbacks.  Provides
region-scoped helpers for drawing text, shapes, images, and annotations
into a header or footer without recomputing coordinates or re-implementing
canvas primitives.

=head1 REGION ACCESSORS

=over 4

=item B<left>, B<right>, B<bottom>, B<top>

Edge coordinates of the region.

=item B<center_x>, B<center_y>

Center of the region.

=item B<baseline($offset)>

Returns C<< y0 + $offset >>.

=item B<inset($dx, $dy)>

Returns C<($x, $y, $w, $h)> of the region inset by C<$dx> / C<$dy>.

=back

=head1 HELPERS

=over 4

=item B<text(text =E<gt> ..., align =E<gt> ..., x =E<gt> ..., y =E<gt> ..., font =E<gt> {...})>

Draw a single line of text.  C<align> is C<left>, C<center>, or C<right>
within the region.  C<x>/C<y> override alignment and default baseline.

=item B<page_num(format =E<gt> 'Page {num}', align =E<gt> 'right', font =E<gt> {...})>

Draw a page number.  C<{num}> and C<{total}> are substituted.  Defaults:
size 8, colour C<#666>, align C<right>.

=item B<line(from =E<gt> [x,y], to =E<gt> [x,y], type =E<gt> 'solid'|'dashed'|'dots', ...)>

Draw a straight line.  Alternatively pass C<x1/y1/x2/y2>.

=item B<box(x =E<gt> ..., y =E<gt> ..., w =E<gt> ..., h =E<gt> ..., fill_colour =E<gt> ...)>

Draw a filled or stroked rectangle.  C<fill_colour =E<gt> 'transparent'>
produces a stroked outline.

=item B<image(src =E<gt> ..., align =E<gt> ..., w =E<gt> ..., h =E<gt> ...)>

Embed an image.  Aspect ratio is preserved when only one dimension is
given.  Defaults to the region height when neither is set.

=item B<note(rect =E<gt> [x0,y0,x1,y1], text =E<gt> ..., icon =E<gt> ...)>

Add a PDF text annotation, attached to the current page.

=item B<link(rect =E<gt> [...], url|page|action|file =E<gt> ...)>

Add a link annotation, attached to the current page.

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Page::Header>, L<PDF::Make::Builder::Page::Footer>

=cut
