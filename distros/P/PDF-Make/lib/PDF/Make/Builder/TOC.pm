package PDF::Make::Builder::TOC;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::TOC',
        'title:Str:default(Table of Contents)',
        'title_font_args:HashRef:default({})',
        'title_padding:Num:default(10)',
        'font_args:HashRef:default({})',
        'padding:Num:default(0)',
        'level_indent:Num:default(2)',
        'entries:ArrayRef:default([])',
        'page_index:Int:default(0)',
        'x:Num', 'y:Num', 'w:Num', 'h:Num',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::TOC');
}

sub outline {
    my ($self, $builder, $level, %args) = @_;
    my $e = entries $self;
    push @$e, {
        text     => $args{text},
        page_num => $args{page_num},
        level    => $level,
    };
    entries $self, $e;
}

sub render {
    my ($self, $builder) = @_;
    my $all_pages = $builder->pages // [];
    my $toc_page_idx = page_index($self);
    my $page = ($toc_page_idx >= 0 && $toc_page_idx < @$all_pages)
        ? $all_pages->[$toc_page_idx]
        : $builder->page;

    return unless $page;

    my $canvas = $page->canvas;
    my $font = $builder->font;

    # Title
    my $tf = title_font_args $self;
    my $title_size = $tf->{size} // 30;
    my $res = $font->ensure_loaded($page->xs_page, 'bold');
    my ($tr, $tg, $tb) = $font->hex_to_rgb($tf->{colour} // '#000');

    my $cx = $page->content_x;
    my $cy = $page->cursor_y - $title_size;
    my $tw = $page->width;
    my $right_x = $cx + $tw;

    $canvas->BT
           ->rg($tr, $tg, $tb)
           ->Tf($res, $title_size)
           ->Tm(1, 0, 0, 1, $cx, $cy)
           ->Tj(title $self)
           ->ET;

    $cy -= title_padding $self;

    # Entries
    my $ef = font_args $self;
    my $entry_size = $ef->{size} // 11;
    my $entry_lh = $ef->{line_height} // ($entry_size + 4);
    my $entry_res = $font->ensure_loaded($page->xs_page, 'normal');
    my ($er, $eg, $eb) = $font->hex_to_rgb($ef->{colour} // '#333');
    my $indent_w = $font->space_width * (level_indent $self);
    my $pad = padding $self;

    for my $entry (@{entries $self}) {
        $cy -= $entry_lh;
        my $indent = $indent_w * ($entry->{level} - 1);
        my $text = defined $entry->{text} ? $entry->{text} : '';
        my $pnum = $entry->{page_num};
        my $pnum_str = defined($pnum) ? "$pnum" : '?';
        my $pnum_w = $font->measure_text($pnum_str) * ($entry_size / $font->size);
        my $text_w = $font->measure_text($text) * ($entry_size / $font->size);
        my $text_x = $cx + $indent;
        my $pnum_x = $right_x - $pnum_w;

        my $leader_start = $text_x + $text_w + 4;
        my $leader_end   = $pnum_x - 2;

        # Left text
        $canvas->BT
               ->rg($er, $eg, $eb)
               ->Tf($entry_res, $entry_size)
               ->Tm(1, 0, 0, 1, $text_x, $cy)
               ->Tj($text)
               ->ET;

        # Dot leaders: draw vector dots so spacing is visual, not font-dependent
        if ($leader_end > $leader_start + 2) {
            my $dot_y = $cy + ($entry_size * 0.22);
            my $step = $entry_size * 0.42;
            my $dot_len = 0.01;
            my $dot_width = $entry_size * 0.11;

            $canvas->q
                   ->RG($er, $eg, $eb)
                   ->w($dot_width)
                   ->J(1);

            for (my $x = $leader_start; $x <= $leader_end; $x += $step) {
                $canvas->m($x, $dot_y)
                       ->l($x + $dot_len, $dot_y)
                       ->S;
            }

            $canvas->Q;
        }

        # Right page number
        $canvas->BT
               ->rg($er, $eg, $eb)
               ->Tf($entry_res, $entry_size)
               ->Tm(1, 0, 0, 1, $pnum_x, $cy)
               ->Tj($pnum_str)
               ->ET;

        # Make TOC row clickable (internal GoTo)
        if (defined $pnum && $pnum =~ /^\d+$/ && $pnum > 0) {
            my $y1 = $cy - 2;
            my $y2 = $cy + $entry_size + 2;
            $builder->add_link(
                on_page => $toc_page_idx,
                page    => $pnum - 1,
                rect    => [ $text_x, $y1, $right_x, $y2 ],
            );
        }

        $cy -= $pad;
    }

    $page->y($cy);
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::TOC - Table of contents for PDF::Make

=head1 SYNOPSIS

    my $builder = PDF::Make::Builder->new(
        toc => {
            title       => 'Contents',
            font_args   => { size => 11 },
            level_indent => 3,
        },
    );

    # Headings with toc => 1 auto-register entries
    $builder->add_h1(text => 'Chapter 1', toc => 1);

    # Render the TOC (usually on a dedicated page)
    $builder->toc->render($builder);

=head1 DESCRIPTION

Collects heading entries during document construction and renders a formatted
table of contents with dot leaders and page numbers.

=head1 PROPERTIES

=over 4

=item B<title> (Str, default C<'Table of Contents'>)

Title displayed above the TOC entries.

=item B<title_font_args> (HashRef, default C<{}>)

Font overrides for the title (e.g. C<< { size => 30, colour => '#000' } >>).

=item B<title_padding> (Num, default 10)

Vertical space below the title before the first entry.

=item B<font_args> (HashRef, default C<{}>)

Font overrides for the TOC entries.

=item B<padding> (Num, default 0)

Extra vertical padding between entries.

=item B<level_indent> (Num, default 2)

Number of space-widths per indentation level.

=item B<entries> (ArrayRef, default C<[]>)

Internal list of collected TOC entries.

=back

=head1 METHODS

=over 4

=item B<outline($builder, $level, %args)>

Adds a TOC entry.  C<$level> is the heading depth (1-6).  C<%args> must
include C<text> and C<page_num>.

=item B<render($builder)>

Renders the full table of contents onto the builder's current page.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::TOC::Outline>,
L<PDF::Make::Builder::Text::H1>

=cut
