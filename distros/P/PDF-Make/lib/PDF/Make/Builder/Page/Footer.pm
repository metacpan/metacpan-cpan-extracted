package PDF::Make::Builder::Page::Footer;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Page::HeaderFooterContext;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Page::Footer',
        'h:Num:default(30)',
        'padding:Num:default(20)',
        'show_page_num:Str',
        'page_num_text:Str:default(Page {num})',
        'cb:CodeRef',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Page::Footer');
}

sub render {
    my ($self, $builder, $page, $page_num) = @_;
    my $canvas = $page->canvas;
    my $pw = $page->w;
    my $pad = padding $self;
    my $fh = $self->h;

    # Footer region: bottom of page
    my $footer_y = $pad + $fh;

    # Custom callback
    my $callback = cb $self;
    if ($callback) {
        my $ctx = PDF::Make::Builder::Page::HeaderFooterContext->new(
            builder => $builder,
            page    => $page,
            canvas  => $canvas,
            x0      => 0,
            y0      => $pad,
            w       => $pw,
            h       => $fh,
            padding => $pad,
            num     => $page_num,
            role    => 'footer',
        );
        $callback->($self, $builder,
            ctx    => $ctx,
            canvas => $canvas, y => $footer_y, w => $pw, h => $fh,
            page_num => $page_num);
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
               ->Tm(1, 0, 0, 1, $tx, $pad + 4)
               ->Tj($text)
               ->ET;
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Page::Footer - Repeating page footer for PDF::Make

=head1 SYNOPSIS

    use PDF::Make::Builder;

    my $builder = PDF::Make::Builder->new(
        footer => {
            h             => 30,
            show_page_num => 'left',
            page_num_text => 'Page {num}',
        },
    );

=head1 DESCRIPTION

Defines a footer region rendered at the bottom of every page.  Supports
automatic page numbering and an optional custom render callback.

=head1 PROPERTIES

=over 4

=item B<h> (Num, default 30)

Height of the footer region in points.

=item B<padding> (Num, default 20)

Horizontal padding inside the footer.

=item B<show_page_num> (Str)

Where to show the page number: C<'left'>, C<'center'>, or C<'right'>.
Omit to hide.

=item B<page_num_text> (Str, default C<'Page {num}'>)

Template string for the page number.  C<{num}> is replaced with the current
page number.

=item B<cb> (CodeRef)

Custom render callback invoked as

    $cb->($self, $builder,
          ctx      => $ctx,
          canvas   => $canvas, y => $y, w => $w, h => $h,
          page_num => $page_num);

C<$ctx> is a L<PDF::Make::Builder::Page::HeaderFooterContext> providing
region-aware helpers (C<text>, C<page_num>, C<line>, C<box>, C<image>,
C<note>, C<link>) and region accessors (C<left>, C<right>, C<top>,
C<bottom>, C<center_x>, C<center_y>, C<inset>).  The raw C<canvas>,
C<y>, C<w>, C<h>, C<page_num> args are retained for backward compatibility.

=back

=head1 EXAMPLE

    $builder->add_page_footer(
        h  => 30,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $ctx = $args{ctx};
            $ctx->line(y1 => $ctx->top - 2, y2 => $ctx->top - 2,
                       colour => '#ccc');
            $ctx->text(text => 'Confidential', align => 'left',
                       font => { size => 8, colour => '#666' });
            $ctx->page_num(format => 'Page {num} of {total}', align => 'right');
        },
    );

=head1 METHODS

=over 4

=item B<render($builder, $page, $page_num)>

Renders the footer onto the given page.

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Page>, L<PDF::Make::Builder::Page::Header>

=cut
