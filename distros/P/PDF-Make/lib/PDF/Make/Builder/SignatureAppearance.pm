package PDF::Make::Builder::SignatureAppearance;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Canvas;
use PDF::Make::Builder::Font;
use PDF::Make::Image;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::SignatureAppearance',
        'w:Num:required',
        'h:Num:required',
        'canvas:Any',
        'doc:Any',
        'fonts:HashRef:default({})',
        'xobjects:HashRef:default({})',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::SignatureAppearance');
}

sub BUILD {
    my ($self) = @_;
    canvas $self, PDF::Make::Canvas->new;
}

# ── Coordinate accessors ──────────────────────────────────

sub left      { 0 }
sub bottom    { 0 }
sub right     { my $s = shift; $s->w }
sub top       { my $s = shift; $s->h }
sub center_x  { my $s = shift; $s->w / 2 }
sub center_y  { my $s = shift; $s->h / 2 }

# ── Font registry ─────────────────────────────────────────

my %STD14_BASEFONT = (
    Helvetica        => 'Helvetica',
    'Helvetica-Bold' => 'Helvetica-Bold',
    Times            => 'Times-Roman',
    'Times-Bold'     => 'Times-Bold',
    'Times-Italic'   => 'Times-Italic',
    Courier          => 'Courier',
    'Courier-Bold'   => 'Courier-Bold',
);

sub _register_font {
    my ($self, $family, $bold, $italic) = @_;
    $family //= 'Helvetica';
    my $base;
    if ($family =~ /^Helvetica/i) {
        $base = $bold ? 'Helvetica-Bold' : 'Helvetica';
    } elsif ($family =~ /^Times/i) {
        $base = $bold && $italic ? 'Times-BoldItalic'
              : $bold            ? 'Times-Bold'
              : $italic          ? 'Times-Italic'
              :                    'Times-Roman';
    } elsif ($family =~ /^Courier/i) {
        $base = $bold ? 'Courier-Bold' : 'Courier';
    } else {
        $base = $family;
    }
    my $res_name = 'F_' . $base;
    $res_name =~ s/-/_/g;
    $self->fonts->{$res_name} = $base;
    return ($res_name, $base);
}

# ── Drawing primitives ────────────────────────────────────

sub text {
    my ($self, %args) = @_;
    my $text = $args{text} // '';
    return $self unless length $text;

    my $size   = $args{size}   // 10;
    my $colour = $args{colour} // $args{color} // '#000';
    my $family = $args{family} // 'Helvetica';
    my $bold   = $args{bold}   // 0;
    my $italic = $args{italic} // 0;

    my ($res, $base) = $self->_register_font($family, $bold, $italic);

    # Measure for alignment.
    my $font = PDF::Make::Builder::Font->new(
        family => ($base =~ /^Times/   ? 'Times'   :
                   $base =~ /^Courier/ ? 'Courier' : 'Helvetica'),
        bold => $bold, italic => $italic, size => $size,
    );
    my $tw = $font->measure_text($text);
    my ($r, $g, $b) = $font->hex_to_rgb($colour);

    my $align = $args{align} // 'left';
    my $x = $args{x};
    my $y = $args{y};
    if (!defined $x) {
        if    ($align eq 'right')  { $x = $self->w - $tw - 4 }
        elsif ($align eq 'center') { $x = ($self->w - $tw) / 2 }
        else                       { $x = 4 }
    }
    $y = $self->h - $size - 4 unless defined $y;

    $self->canvas
         ->BT
         ->rg($r, $g, $b)
         ->Tf($res, $size)
         ->Tm(1, 0, 0, 1, $x, $y)
         ->Tj($text)
         ->ET;
    return $self;
}

sub line {
    my ($self, %args) = @_;
    my $x1 = $args{x1} // $self->left;
    my $y1 = $args{y1} // $self->bottom;
    my $x2 = $args{x2} // $self->right;
    my $y2 = $args{y2} // $y1;
    my $colour = $args{colour} // $args{color} // '#000';
    my $font = PDF::Make::Builder::Font->new(family => 'Helvetica', size => 10);
    my ($r, $g, $b) = $font->hex_to_rgb($colour);
    $self->canvas->q->w($args{width} // 0.5)->RG($r, $g, $b)
         ->m($x1, $y1)->l($x2, $y2)->S->Q;
    return $self;
}

sub image {
    my ($self, %args) = @_;
    my $file = $args{file} // $args{image}
        or die "SignatureAppearance::image: 'file' argument required";

    my $doc = $self->doc
        or die "SignatureAppearance::image: appearance was constructed without a doc reference";

    my $img = PDF::Make::Image->from_file($file);
    my $obj_num = $img->write_to_doc($doc);
    my $res_name = 'Im' . $obj_num;
    $self->xobjects->{$res_name} = $obj_num;

    my $img_w = $img->width;
    my $img_h = $img->height;

    my $draw_w = $args{w};
    my $draw_h = $args{h};
    if (!defined $draw_w && !defined $draw_h) {
        $draw_w = $self->w;
        $draw_h = $draw_w * ($img_h / $img_w);
    } elsif (!defined $draw_h) {
        $draw_h = $draw_w * ($img_h / $img_w);
    } elsif (!defined $draw_w) {
        $draw_w = $draw_h * ($img_w / $img_h);
    }

    my $x = $args{x} // (($self->w - $draw_w) / 2);
    my $y = $args{y} // (($self->h - $draw_h) / 2);

    $self->canvas
         ->q
         ->cm($draw_w, 0, 0, $draw_h, $x, $y)
         ->Do($res_name)
         ->Q;
    return $self;
}

sub box {
    my ($self, %args) = @_;
    my $x = $args{x} // $self->left;
    my $y = $args{y} // $self->bottom;
    my $w = $args{w} // $self->w;
    my $h = $args{h} // $self->h;
    my $colour = $args{fill_colour} // $args{colour} // $args{color} // '#000';
    my $font = PDF::Make::Builder::Font->new(family => 'Helvetica', size => 10);
    my ($r, $g, $b) = $font->hex_to_rgb(
        $colour eq 'transparent' ? '#000' : $colour);
    my $c = $self->canvas;
    $c->q;
    if ($colour eq 'transparent') {
        $c->w($args{width} // 0.5)->RG($r, $g, $b)->re($x, $y, $w, $h)->S;
    } else {
        $c->rg($r, $g, $b)->re($x, $y, $w, $h)->f;
    }
    $c->Q;
    return $self;
}

# ── Consumption ───────────────────────────────────────────

sub stream { my $self = shift; $self->canvas->to_bytes }

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::SignatureAppearance - Builder helper for custom
visible-signature appearance streams

=head1 SYNOPSIS

    $pdf->sign(
        pkcs12 => 'mycert.p12', password => '…',
        visible => 1, page => 1, rect => [360, 72, 540, 150],
        appearance => sub {
            my ($sa) = @_;
            $sa->box(fill_colour => '#fff');
            $sa->box(fill_colour => 'transparent');
            $sa->text(text => 'Signed by Alice',
                      size => 12, bold => 1, y => $sa->top - 18);
            $sa->text(text => 'Date: 2026-04-23',
                      size => 10, y => $sa->top - 36);
            $sa->line(y1 => 4, y2 => 4, colour => '#888');
        },
    );

=head1 DESCRIPTION

When passed a coderef as C<appearance => sub { ... }>, C<$pdf->sign> invokes
it with an instance of this class.  The callback draws into a local
canvas whose origin is at the bottom-left of the widget's rectangle and
whose extent is C<$sa->w × $sa->h>.  The finished content stream and any
standard-14 fonts used are returned to the signing code as a C<stream +
fonts> pair, wrapped into a PDF Form XObject and installed as the
widget's C</AP /N> appearance.

=head1 METHODS

=head2 text(text => ..., align => ..., size => ..., bold => ..., italic => ..., family => ..., colour => ..., x => ..., y => ...)

Draw a single line of text.  Without explicit coordinates the line is
inset 4pt from the left edge and baseline is near the top.

=head2 line(x1, y1, x2, y2, colour, width)

=head2 box(x, y, w, h, fill_colour)

Rectangle — either filled or, with C<fill_colour =E<gt> 'transparent'>,
stroked outline.

=head2 image(file => ..., x => ..., y => ..., w => ..., h => ...)

Embed a raster image (PNG/JPEG) into the widget — typical use-case is
a scanned scribbled-signature PNG.  The image is added to the
document as an indirect image XObject, registered in the widget's
appearance-Form /Resources /XObject dict, and drawn via q/cm/Do/Q.
Omitted dimensions are derived from the image's native aspect ratio,
and omitted coordinates centre the image inside the widget.

=head2 w / h / left / right / top / bottom / center_x / center_y

Region accessors.  C<top> is the height; coordinates use PDF conventions
(origin bottom-left).

=cut
