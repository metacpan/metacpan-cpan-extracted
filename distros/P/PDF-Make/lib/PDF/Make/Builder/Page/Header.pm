package PDF::Make::Builder::Page::Header;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Page::HeaderFooterContext;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Page::Header',
        'h:Num:default(30)',
        'padding:Num:default(20)',
        'show_page_num:Str',
        'page_num_text:Str:default(Page {num})',
        'cb:CodeRef',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Page::Header');
}

sub render {
    my ($self, $builder, $page, $page_num) = @_;
    my $canvas = $page->canvas;
    my $pw = $page->w;
    my $ph = $page->h;
    my $pad = padding $self;
    my $hh = $self->h;

    # Header region: top of page
    my $header_y = $ph - $pad;

    # Custom callback
    my $callback = cb $self;
    if ($callback) {
        my $ctx = PDF::Make::Builder::Page::HeaderFooterContext->new(
            builder => $builder,
            page    => $page,
            canvas  => $canvas,
            x0      => 0,
            y0      => $header_y - $hh,
            w       => $pw,
            h       => $hh,
            padding => $pad,
            num     => $page_num,
            role    => 'header',
        );
        $callback->($self, $builder,
            ctx    => $ctx,
            canvas => $canvas, y => $header_y, w => $pw, h => $hh);
    }

    # Page number
    my $show = show_page_num $self;
    if ($show) {
        my $text = page_num_text $self;
        $text =~ s/\{num\}/$page_num/g;
        my $font = $builder->font;
        my $res = $font->ensure_loaded($page->xs_page, 'normal');
        my $font_size = 8;
        my ($r, $g, $b) = $font->hex_to_rgb('#666');
        my $tw = $font->measure_text($text) * ($font_size / ($font->size || 9));
        my $tx;
        if ($show eq 'right') {
            $tx = $pw - $pad - $tw;
        } elsif ($show eq 'center') {
            $tx = ($pw - $tw) / 2;
        } else {
            $tx = $pad;
        }
        $canvas->BT
               ->rg($r, $g, $b)
               ->Tf($res, $font_size)
               ->Tm(1, 0, 0, 1, $tx, $header_y - $font_size)
               ->Tj($text)
               ->ET;
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Page::Header - Repeating page header for PDF::Make

=head1 SYNOPSIS

    use PDF::Make::Builder;

    my $builder = PDF::Make::Builder->new(
        header => {
            h             => 30,
            show_page_num => 'right',
            page_num_text => 'Page {num}',
        },
    );

=head1 DESCRIPTION

Defines a header region rendered at the top of every page.  Supports automatic
page numbering and an optional custom render callback.

=head1 PROPERTIES

=over 4

=item B<h> (Num, default 30)

Height of the header region in points.

=item B<padding> (Num, default 20)

Horizontal padding inside the header.

=item B<show_page_num> (Str)

Where to show the page number: C<'left'>, C<'center'>, or C<'right'>.
Omit to hide.

=item B<page_num_text> (Str, default C<'Page {num}'>)

Template string for the page number.  C<{num}> is replaced with the current
page number.

=item B<cb> (CodeRef)

Custom render callback invoked as

    $cb->($self, $builder,
          ctx    => $ctx,
          canvas => $canvas, y => $y, w => $w, h => $h);

C<$ctx> is a L<PDF::Make::Builder::Page::HeaderFooterContext> providing
region-aware helpers (C<text>, C<page_num>, C<line>, C<box>, C<image>,
C<note>, C<link>) and region accessors (C<left>, C<right>, C<top>,
C<bottom>, C<center_x>, C<center_y>, C<inset>).  The raw C<canvas>,
C<y>, C<w>, C<h> args are retained for backward compatibility.

=back

=head1 EXAMPLE

    $builder->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $ctx = $args{ctx};
            $ctx->text(text => 'My Document', align => 'left',
                       font => { size => 10, bold => 1 });
            $ctx->page_num(format => 'Page {num} of {total}', align => 'right');
            $ctx->line(y1 => $ctx->bottom + 2, y2 => $ctx->bottom + 2,
                       colour => '#999');
        },
    );

=head1 METHODS

=over 4

=item B<render($builder, $page, $page_num)>

Renders the header onto the given page.

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Page>, L<PDF::Make::Builder::Page::Footer>

=cut
