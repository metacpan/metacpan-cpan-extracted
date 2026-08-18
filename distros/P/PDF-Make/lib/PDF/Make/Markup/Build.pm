package PDF::Make::Markup::Build;
use strict;
use warnings;
use Carp ();
use PDF::Make::Builder;
use PDF::Make::Markup::Style;

our $VERSION = '0.11';

my $S = 'PDF::Make::Markup::Style';

# What each element may contain.
#
#   block  - other blocks: rows, tables, paragraphs
#   inline - text and the inline styling tags
#   rows   - <tr> only
#   cells  - <cell>, <th>, <td> only
#   none   - nothing
#
# Checked rather than assumed: <text><row/></text> is a mistake worth an
# exception with a line number, and the alternative is a builder call that
# fails somewhere far away with no idea which template line caused it.
my %CONTENT = (
    doc    => 'block',  page   => 'block',  box    => 'block',
    header => 'block',  footer => 'block',
    cell   => 'inline', th     => 'inline', td     => 'inline',
    h1 => 'inline', h2 => 'inline', h3 => 'inline',
    h4 => 'inline', h5 => 'inline', h6 => 'inline',
    p  => 'inline', text => 'inline',
    b  => 'inline', i    => 'inline', span => 'inline',
    row => 'cells', table => 'rows', tr => 'cells',
    hr => 'none', pagebreak => 'none', img => 'none',
    style => 'none', bookmark => 'none',
);

my %IS_HEADING = map { $_ => 1 } qw(h1 h2 h3 h4 h5 h6);
my %IS_CELL    = map { $_ => 1 } qw(cell th td);

# What a tag IS, which is not what %CONTENT says a tag may HOLD. <h1> holds
# inline content and is itself a block; only these three are inline-level.
# Reading %CONTENT as the former is what made every block inside a <box>
# flow onto one line.
my %IS_INLINE  = map { $_ => 1 } qw(b i span);

sub _err {
    my ($node, $fmt, @args) = @_;
    my $where = $node && defined $node->{line}
        ? sprintf(' at line %d, column %d', $node->{line}, $node->{col}) : '';
    Carp::croak(sprintf($fmt, @args) . $where);
}

sub _kids  { return @{ $_[0]{children} || [] } }
sub _elems { return grep { $_->{kind} eq 'elem' } _kids($_[0]) }

# ---------------------------------------------------------------------------
# Inline runs
# ---------------------------------------------------------------------------

# Flatten a text-bearing element's children into styled runs. Nested inline
# tags contribute their own style; a block tag in here is an error.
sub _runs {
    my ($class, $node, $style, $out) = @_;
    $out ||= [];

    for my $c (_kids($node)) {
        if ($c->{kind} eq 'text') {
            push @$out, { %{ $S->font_args($style) }, text => $c->{text} };
            next;
        }
        my $tag = $c->{tag};
        _err($c, "<%s> cannot appear inside <%s>, which holds text", $tag,
             $node->{tag})
            unless ($CONTENT{$tag} || '') eq 'inline';

        my $own = $S->attrs($c);
        $own->{bold}   = 1 if $tag eq 'b';
        $own->{italic} = 1 if $tag eq 'i';
        $class->_runs($c, $S->inherit($style, $own), $out);
    }
    return $out;
}

# Text arguments for a block: a plain string when nothing inside it is
# styled, runs when something is. The plain case matters - it keeps the
# single-font path in Builder::Text, whose output existing documents depend
# on, and skips the run machinery entirely.
sub _text_args {
    my ($class, $node, $style) = @_;
    my $runs = $class->_runs($node, $style);
    return (text => '') unless @$runs;

    my $styled = 0;
    for my $r (@$runs) {
        $styled = 1, last if $r->{bold} || $r->{italic};
    }
    if (!$styled && @$runs == 1) {
        return (text => $runs->[0]{text}, font => $S->font_args($style));
    }
    return (runs => $runs, font => $S->font_args($style));
}

# Block-level arguments shared by the text blocks.
sub _block_args {
    my ($class, $style) = @_;
    my %a;
    $a{align}   = $style->{align}   if defined $style->{align};
    $a{indent}  = $style->{indent}  if defined $style->{indent};
    $a{spacing} = $style->{spacing} if defined $style->{spacing};
    $a{margin}  = $style->{margin}  if defined $style->{margin};
    $a{padding} = $style->{pad}     if defined $style->{pad};
    $a{preformatted} = $style->{preformatted}
        if defined $style->{preformatted};
    return %a;
}

# ---------------------------------------------------------------------------
# Blocks
# ---------------------------------------------------------------------------

sub _block {
    my ($class, $pdf, $node, $style) = @_;
    my $tag = $node->{tag};

    # <style> carries tag names as attributes, so it is not validated the way
    # every other element is; _configure has already read it.
    return if $tag eq 'style';

    my $own = $S->attrs($node);
    my $st  = $S->inherit($style, $own);

    if ($IS_HEADING{$tag}) {
        my $m = "add_$tag";
        $pdf->$m($class->_text_args($node, $st), $class->_block_args($st));
        return;
    }

    if ($tag eq 'p' || $tag eq 'text') {
        $pdf->add_text($class->_text_args($node, $st),
                       $class->_block_args($st));
        return;
    }

    if ($tag eq 'pagebreak') {
        $pdf->add_page($class->_page_args($pdf, {}));
        return;
    }

    if ($tag eq 'page') {
        $pdf->add_page($class->_page_args($pdf, $own));
        $class->_children($pdf, $node, $st);
        return;
    }

    if ($tag eq 'hr') {
        my $page = $pdf->page;
        my $y    = $page->cursor_y;
        my $x    = $page->content_x;
        my $w    = defined $st->{width} ? $st->{width} : $page->width;
        $pdf->add_line(
            x => $x, y => $y, ex => $x + $w, ey => $y,
            fill_colour => (defined $st->{colour} ? $st->{colour} : '#000000'),
        );
        my $gap = defined $st->{spacing} ? $st->{spacing} : 6;
        $page->y($y - $gap);
        return;
    }

    if ($tag eq 'img') {
        _err($node, '<img> needs a src') unless defined $own->{src};
        my %a = (image => $own->{src});
        $a{w}     = $own->{width}  if defined $own->{width};
        $a{h}     = $own->{height} if defined $own->{height};
        $a{align} = $own->{align}  if defined $own->{align};
        $pdf->add_image(%a);
        return;
    }

    if ($tag eq 'bookmark') {
        _err($node, '<bookmark> needs a title') unless defined $own->{title};
        $pdf->add_outline($own->{title}, page => $pdf->page_count - 1);
        return;
    }

    # A box is one cell in one row: the layout engine already draws a padded,
    # bordered, background-filled rectangle that grows with its content, and
    # a second implementation of that would be a second set of bugs.
    if ($tag eq 'box') {
        my $lay  = $pdf->layout;
        my $row  = $lay->row;
        my %cell = (weight => 1);
        $cell{pad}    = $st->{pad}    if defined $st->{pad};
        $cell{bg}     = $st->{bg}     if defined $st->{bg};
        $cell{border} = $st->{border} if defined $st->{border};
        my $cell = $row->cell(%cell);
        $class->_cell_content($cell, $node, $st, $pdf);
        $lay->render;
        return;
    }

    if ($tag eq 'row') {
        $class->_row($pdf, $node, $st, [ _elems($node) ]);
        return;
    }

    if ($tag eq 'table') {
        $class->_table($pdf, $node, $st);
        return;
    }

    if ($tag eq 'header' || $tag eq 'footer') {
        my $m = $tag eq 'header' ? 'add_page_header' : 'add_page_footer';
        my $runs = $class->_runs($node, $st);
        my $text = join '', map { $_->{text} } @$runs;
        return unless length $text;

        # Headers and footers draw through a callback with a context object -
        # they are not text blocks, and passing text => to add_page_header
        # does nothing at all, silently. The alignment and font come from the
        # element's own style so <footer align="center"> means what it says.
        my $font  = $S->font_args($st);
        my $align = defined $st->{align} ? $st->{align} : 'left';
        $pdf->$m(cb => sub {
            my (undef, undef, %a) = @_;
            $a{ctx}->text(text => $text, align => $align, font => $font);
        });
        return;
    }

    _err($node, "<%s> cannot appear here", $tag);
}

sub _page_args {
    my ($class, $pdf, $own) = @_;
    my %a;
    $a{page_size}  = $own->{'page-size'} if defined $own->{'page-size'};
    $a{padding}    = $own->{margin}      if defined $own->{margin};
    $a{columns}    = $own->{columns}     if defined $own->{columns};
    $a{background} = $own->{background}  if defined $own->{background};
    my $cur = $pdf->page;
    if ($cur) {
        # A new page keeps the shape of the one it follows unless told
        # otherwise; a pagebreak that silently resized the paper would be a
        # surprise nobody wants halfway through a statement run.
        $a{page_size}  = $cur->page_size  unless defined $a{page_size};
        $a{padding}    = $cur->padding    unless defined $a{padding};
        $a{columns}    = $cur->columns    unless defined $a{columns};
        $a{background} = $cur->background
            unless defined $a{background} || !defined $cur->background;
    }
    return %a;
}

# ---------------------------------------------------------------------------
# Rows, cells and tables
# ---------------------------------------------------------------------------

# A cell's contents. Text and inline styling become one run item; a block
# child (a heading or a paragraph, as in a <box>) becomes an item of its own,
# which is how a box stacks blocks without a second layout engine.
sub _cell_content {
    my ($class, $cell, $node, $style, $pdf) = @_;
    my $cfg = $pdf ? ($pdf->configure || {}) : {};

    my @pending;    # inline nodes accumulating into one item
    my $flush = sub {
        return unless @pending;
        my $runs = [];
        for my $c (@pending) {
            if ($c->{kind} eq 'text') {
                push @$runs, { %{ $S->font_args($style) }, text => $c->{text} };
            } else {
                my $own = $S->attrs($c);
                $own->{bold}   = 1 if $c->{tag} eq 'b';
                $own->{italic} = 1 if $c->{tag} eq 'i';
                $class->_runs($c, $S->inherit($style, $own), $runs);
            }
        }
        @pending = ();
        return unless @$runs;
        $class->_add_cell_item($cell, $runs, $style);
    };

    for my $c (_kids($node)) {
        if ($c->{kind} eq 'text' || $IS_INLINE{ $c->{tag} || '' }) {
            push @pending, $c;
            next;
        }

        _err($c, "<%s> cannot appear inside <%s>", $c->{tag}, $node->{tag})
            unless $IS_HEADING{ $c->{tag} }
                || $c->{tag} eq 'p' || $c->{tag} eq 'text';

        $flush->();
        my $own = $S->attrs($c);
        my $st  = $S->inherit($style, $own);
        my $runs = $class->_runs($c, $st);
        # <style h1="size:30"> reaches add_h1 through the builder's configure,
        # which a cell item never goes near - so fold the tag's declared font
        # in here, under anything the element said for itself.
        my $tagf = $cfg->{ $c->{tag} } ? $cfg->{ $c->{tag} }{font} : undef;
        $class->_add_cell_item($cell, $runs, $st, $tagf, $own) if @$runs;
    }
    $flush->();
    return;
}

# One item on the cell: runs when anything in it is styled differently from
# the block, a plain string otherwise. The plain form keeps the cell's
# original wrapping, which existing documents depend on.
sub _add_cell_item {
    my ($class, $cell, $runs, $style, $tag_font, $own) = @_;
    # inherited < the tag's <style> declaration < what the element itself said
    my %f = %{ $S->font_args($style) };
    if ($tag_font && %$tag_font) {
        %f = (%f, %$tag_font);
        %f = (%f, %{ $S->font_args($S->inherit({}, $own)) }) if $own;
    }
    # A cell has one alignment; its items each have their own, which is what
    # a <box> of centred blocks needs. spacing is per item for the same
    # reason: it is what separates the blocks stacked in one box.
    $f{align}   = $style->{align}   if defined $style->{align};
    $f{spacing} = $style->{spacing} if defined $style->{spacing};

    my $styled = 0;
    for my $r (@$runs) {
        my $same = 1;
        for my $k (qw(bold italic colour size family line_height)) {
            next unless defined $r->{$k} || defined $f{$k};
            $same = 0, last
                if (defined $r->{$k} ? $r->{$k} : '') ne
                   (defined $f{$k} ? $f{$k} : '');
        }
        $styled = 1, last unless $same;
    }

    if (!$styled && @$runs == 1) {
        $cell->text($runs->[0]{text}, %f);
    } else {
        $cell->runs($runs, %f);
    }
    return;
}

sub _cells {
    my ($class, $row, $node, $style, $cells, $colw) = @_;
    my $i = -1;
    for my $c (@$cells) {
        $i++;
        _err($c, "<%s> cannot appear inside <%s>, which holds cells",
             $c->{tag}, $node->{tag})
            unless $IS_CELL{ $c->{tag} };

        my $own = $S->attrs($c);
        my $st  = $S->inherit($style, $own);
        $st->{bold} = 1 if $c->{tag} eq 'th' && !exists $own->{bold};

        # A table's columns are the table's, not each row's. Without this a
        # header that declares weight="3" and body rows that declare nothing
        # produce two different column layouts stacked on top of each other,
        # which is what "the table is not aligned" looks like.
        my $weight = defined $own->{weight} ? $own->{weight}
                   : ($colw && defined $colw->[$i]) ? $colw->[$i]
                   : 1;
        my %a = (weight => $weight);
        $a{pad}    = $own->{pad}    if defined $own->{pad};
        $a{bg}     = $own->{bg}     if defined $own->{bg};
        $a{border} = $own->{border} if defined $own->{border};
        $a{align}  = $st->{align}   if defined $st->{align};
        $a{valign} = $own->{valign} if defined $own->{valign};

        my $cell = $row->cell(%a);
        $class->_cell_content($cell, $c, $st);
    }
}

sub _row {
    my ($class, $pdf, $node, $style, $cells, $lay) = @_;
    my $own = $S->attrs($node);
    my $mine = $lay || $pdf->layout;
    my %a;
    $a{gap}    = $own->{gap}    if defined $own->{gap};
    $a{height} = $own->{height} if defined $own->{height};
    my $row = $mine->row(%a);
    $class->_cells($row, $node, $style, $cells);
    $mine->render unless $lay;
    return $mine;
}

sub _table {
    my ($class, $pdf, $node, $style) = @_;
    my $own = $S->attrs($node);
    my $st  = $S->inherit($style, $own);

    # Column widths come from the first row - usually the header, which is
    # where anyone writing a table declares them - and every later row uses
    # them unless one of its own cells says otherwise.
    my @colw;
    {
        my ($first) = _elems($node);
        if ($first) {
            for my $c (_elems($first)) {
                my $a = eval { $S->attrs($c) } || {};
                push @colw, defined $a->{weight} ? $a->{weight} : 1;
            }
        }
    }

    for my $tr (_elems($node)) {
        _err($tr, "<%s> cannot appear inside <table>, which holds rows",
             $tr->{tag})
            unless $tr->{tag} eq 'tr';

        my $tr_own = $S->attrs($tr);
        my $lay    = $pdf->layout;
        my %a;
        $a{gap}    = $own->{gap}       if defined $own->{gap};
        $a{height} = $tr_own->{height} if defined $tr_own->{height};
        my $row = $lay->row(%a);
        $class->_cells($row, $tr, $S->inherit($st, $tr_own), [ _elems($tr) ], \@colw);
        $lay->render;
    }
}

# ---------------------------------------------------------------------------
# Walking
# ---------------------------------------------------------------------------

sub _children {
    my ($class, $pdf, $node, $style) = @_;
    for my $c (_kids($node)) {
        if ($c->{kind} eq 'text') {
            # Only whitespace survives the parser inside a container, and it
            # is indentation. Anything else is text somebody expected to see.
            next unless $c->{text} =~ /\S/;
            _err($c, "text directly inside <%s>: put it in a <text> block",
                 $node->{tag});
        }
        $class->_block($pdf, $c, $style);
    }
}

# <style> children become the builder's configure map, so that h1 and text
# defaults go through the same path a hand-written builder script uses.
sub _configure {
    my ($class, $root) = @_;
    my %cfg;
    for my $s (grep { $_->{tag} eq 'style' } _elems($root)) {
        for my $tag (sort keys %{ $s->{attrs} }) {
            my $decl = $S->declarations($s->{attrs}{$tag}, $s, $tag);
            my $font = $S->font_args($decl);
            $cfg{$tag} ||= {};
            $cfg{$tag}{font} = { %{ $cfg{$tag}{font} || {} }, %$font };
            for my $k (qw(align indent spacing margin)) {
                $cfg{$tag}{$k} = $decl->{$k} if defined $decl->{$k};
            }
            $cfg{$tag}{padding} = $decl->{pad} if defined $decl->{pad};
        }
    }
    return \%cfg;
}

=head2 build

    my $pdf = PDF::Make::Markup::Build->build($root, file_name => 'out');

Walks a parsed tree onto a L<PDF::Make::Builder> and returns it, unsaved, so
the caller decides where the bytes go.

=cut

sub build {
    my ($class, $root, %opt) = @_;
    _err($root, 'the root element must be <doc>')
        unless $root && ($root->{tag} || '') eq 'doc';

    Carp::croak('PDF::Make::Markup::Build->build needs a file_name')
        unless defined $opt{file_name} && length $opt{file_name};

    my $own = $S->attrs($root);
    my $pdf = PDF::Make::Builder->new(
        file_name => $opt{file_name},
        configure => $class->_configure($root),
    );

    # <doc tagged="1">: accessibility is a property of the document, so
    # it is declared where the document starts. Builder's add_* methods
    # already push P/H1-H6/Figure structure elements; this turns the
    # tree on so they land in a StructTreeRoot. Deeper semantics
    # (Table/TR/TD) are future work and the docs say so plainly.
    $pdf->enable_tagging
        if defined $own->{tagged} && $own->{tagged} && $own->{tagged} ne '0';

    $pdf->add_page($class->_page_args($pdf, $own));
    $class->_children($pdf, $root, $S->inherit(undef, $own));
    return $pdf;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Markup::Build - compile a markup tree onto PDF::Make::Builder

=head1 DESCRIPTION

The only place that knows about both the markup and the builder. Everything
it does is a builder call a hand-written script could have made, which is
what keeps the markup honest: if the builder cannot do a thing, the markup
does not offer it.

=head2 Content models

C<< <doc> >>, C<< <page> >>, C<< <box> >>, C<< <header> >> and
C<< <footer> >> hold blocks. Headings, C<< <p> >>, C<< <text> >> and the
cells hold text and inline styling. C<< <row> >> holds cells,
C<< <table> >> holds C<< <tr> >>, and C<< <tr> >> holds cells. Breaking one
of those is an error with a position rather than a builder failure somewhere
far from the template line that caused it.

=head2 What is not here yet

Inline styling B<inside a cell> is refused rather than flattened:
L<PDF::Make::Builder::Layout::Cell> renders its own text and does not take
the run list L<PDF::Make::Builder::Text> understands. Lifting that is the
next piece of work, and until then the error names the tag and where it is.

=head1 SEE ALSO

L<PDF::Make::Markup::Parse>, L<PDF::Make::Markup::Style>

=cut
