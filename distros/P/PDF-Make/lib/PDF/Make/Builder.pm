package PDF::Make::Builder;
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Object::Proto;
use PDF::Make::Document;
use PDF::Make::Canvas;
use PDF::Make::Import;
use PDF::Make::Page qw(:fonts);
use PDF::Make::Builder::Font;
use PDF::Make::Builder::Page;
use PDF::Make::Builder::Page::Header;
use PDF::Make::Builder::Page::Footer;
use PDF::Make::Builder::Text;
use PDF::Make::Builder::Text::H1;
use PDF::Make::Builder::Text::H2;
use PDF::Make::Builder::Text::H3;
use PDF::Make::Builder::Text::H4;
use PDF::Make::Builder::Text::H5;
use PDF::Make::Builder::Text::H6;
use PDF::Make::Builder::Shape::Line;
use PDF::Make::Builder::Shape::Box;
use PDF::Make::Builder::Shape::Circle;
use PDF::Make::Builder::Shape::Ellipse;
use PDF::Make::Builder::Shape::Pie;
use PDF::Make::Builder::TOC;
use PDF::Make::Builder::Image;
use PDF::Make::Builder::Layout;
use PDF::Make::Builder::Form::Field;
use PDF::Make::Builder::Form::Field::Text;
use PDF::Make::Builder::Form::Field::Checkbox;
use PDF::Make::Builder::Form::Field::Radio;
use PDF::Make::Builder::Form::Field::Combo;
use PDF::Make::Builder::Form::Field::Listbox;
use PDF::Make::Builder::Form::Field::Button;
use PDF::Make::Attachment;
use PDF::Make::Color;
use PDF::Make::Extract;
use PDF::Make::Extract::Result;
use PDF::Make::Font;
use PDF::Make::Layer;
use PDF::Make::Parser;
use PDF::Make::Reader;
use PDF::Make::Redaction;
use PDF::Make::Signature;
use PDF::Make::Structure;
use PDF::Make::Watermark;

our $VERSION = '0.02';

BEGIN {
    Object::Proto::define('PDF::Make::Builder',
        'file_name:Str:required',
        'doc:Any',
        'pages:ArrayRef:default([])',
        'page:Any',
        'page_args:HashRef:default({})',
        'page_offset:Int:default(0)',
        'onsave_cbs:ArrayRef:default([])',
        'configure:HashRef:default({})',
        'font:Any',
        'toc:Any',
        '_header_args:HashRef',
        '_footer_args:HashRef',
        '_outlines:HashRef:default({})',
        '_layers:HashRef:default({})',
        '_encrypt_args:HashRef',
        '_sign_args:HashRef',
        '_watermarks:ArrayRef:default([])',
        '_tagging:Any',
        '_struct_tree:Any',
        '_struct_stack:ArrayRef:default([])',
        '_flatten_pending:Bool:default(0)',
        '_apply_redactions_pending:Bool:default(0)',
        '_sanitize_pending:Bool:default(0)',
    );
    Object::Proto::import_accessors('PDF::Make::Builder');
}

sub BUILD {
    my ($self) = @_;
    doc $self, PDF::Make::Document->new;

    # Default font
    my $cfg = configure $self;
    my $font_args = $cfg->{text}{font} // {};
    my %font_init = (
        colour => $font_args->{colour} // '#000',
        size   => $font_args->{size}   // 9,
        family => $font_args->{family} // 'Helvetica',
    );
    $font_init{line_height} = $font_args->{line_height} if defined $font_args->{line_height};
    font $self, PDF::Make::Builder::Font->new(%font_init);

    # Store header/footer config for new pages
    if ($cfg->{page_header}) {
        _header_args $self, $cfg->{page_header};
    }
    if ($cfg->{page_footer}) {
        _footer_args $self, $cfg->{page_footer};
    }
}

# ── Page management ────────────────────────────────────────

sub add_page {
    my ($self, %args) = @_;

    my $page_size = $args{page_size} // 'A4';
    my ($pw, $ph) = PDF::Make::Builder::Page::page_dimensions($page_size);
    my $padding = $args{padding} // 20;
    my $xs_doc = doc $self;
    my $xs_page = $xs_doc->add_page($pw, $ph);
    my $canvas = PDF::Make::Canvas->new;

    my $pages = pages $self;
    my $num = scalar(@$pages) + 1;

    # Build header/footer from stored config
    my $hdr_args = _header_args $self;
    my $ftr_args = _footer_args $self;
    my $header = $hdr_args ? PDF::Make::Builder::Page::Header->new(%$hdr_args) : undef;
    my $footer = $ftr_args ? PDF::Make::Builder::Page::Footer->new(%$ftr_args) : undef;

    my $bp = PDF::Make::Builder::Page->new(
        page_size  => $page_size,
        background => $args{background} // '#fff',
        columns    => $args{columns}    // 1,
        padding    => $padding,
        num        => $num,
        w          => $pw,
        h          => $ph,
        canvas     => $canvas,
        xs_page    => $xs_page,
        header     => $header,
        footer     => $footer,
    );

    # Draw background if not white
    my $bg = $bp->background;
    if ($bg && $bg ne '#fff' && $bg ne '#ffffff') {
        my ($r, $g, $b) = (font $self)->hex_to_rgb($bg);
        $canvas->q->rg($r, $g, $b)->re(0, 0, $pw, $ph)->f->Q;
    }

    push @$pages, $bp;
    pages $self, $pages;
    page $self, $bp;

    return $self;
}

sub open_page {
    my ($self, $num) = @_;
    my $pages = pages $self;
    die "PDF::Make::Builder: page $num does not exist" unless $num >= 1 && $num <= scalar @$pages;
    page $self, $pages->[$num - 1];
    return $self;
}

sub set_columns {
    my ($self, $n) = @_;
    my $p = page $self;
    die "PDF::Make::Builder: no current page" unless $p;
    $p->columns($n);
    return $self;
}

sub page_width {
    my ($self) = @_;
    my $p = page $self;
    return $p ? $p->w : 0;
}

sub page_height {
    my ($self) = @_;
    my $p = page $self;
    return $p ? $p->h : 0;
}

sub current_x {
    my ($self) = @_;
    my $p = page $self;
    return $p ? ($p->x || $p->content_x) : 0;
}

sub current_y {
    my ($self) = @_;
    my $p = page $self;
    return $p ? $p->cursor_y : 0;
}

sub content_left {
    my ($self) = @_;
    my $p = page $self;
    return $p ? $p->content_x : 0;
}

sub content_right {
    my ($self) = @_;
    my $p = page $self;
    return $p ? ($p->content_x + $p->width) : 0;
}

sub content_bottom {
    my ($self) = @_;
    my $p = page $self;
    return $p ? $p->bottom_y : 0;
}

sub content_top {
    my ($self) = @_;
    my $p = page $self;
    return $p ? $p->top_y : 0;
}

sub cursor_move_to {
    my ($self, $x, $y) = @_;
    my $p = page $self;
    die "PDF::Make::Builder: no current page" unless $p;
    $p->x($x) if defined $x;
    $p->y($y) if defined $y;
    return $self;
}

sub cursor_advance_y {
    my ($self, $dy) = @_;
    my $p = page $self;
    die "PDF::Make::Builder: no current page" unless $p;
    $dy //= 0;
    $p->y($p->cursor_y + $dy);
    return $self;
}

# ── Layout ────────────────────────────────────────────────

sub layout {
    my ($self) = @_;
    return PDF::Make::Builder::Layout->new(builder => $self);
}

# ── Header/Footer ─────────────────────────────────────────

sub add_page_header {
    my ($self, %args) = @_;
    _header_args $self, \%args;
    my $p = page $self;
    if ($p) {
        $p->header(PDF::Make::Builder::Page::Header->new(%args));
    }
    return $self;
}

sub add_page_footer {
    my ($self, %args) = @_;
    _footer_args $self, \%args;
    my $p = page $self;
    if ($p) {
        $p->footer(PDF::Make::Builder::Page::Footer->new(%args));
    }
    return $self;
}

sub remove_page_header {
    my ($self) = @_;
    _header_args $self, undef;
    my $p = page $self;
    $p->header(undef) if $p;
    return $self;
}

sub remove_page_footer {
    my ($self) = @_;
    _footer_args $self, undef;
    my $p = page $self;
    $p->footer(undef) if $p;
    return $self;
}

sub remove_page_header_and_footer {
    my ($self) = @_;
    $self->remove_page_header;
    $self->remove_page_footer;
    return $self;
}

# ── Font ───────────────────────────────────────────────────

sub load_font {
    my ($self, %args) = @_;
    font $self, PDF::Make::Builder::Font->new(%args);
    return $self;
}

# ── Text content ───────────────────────────────────────────

sub _apply_configure {
    my ($self, $type, $args) = @_;
    my $cfg = configure $self;
    my $defaults = $cfg->{$type} // {};
    if ($defaults->{font}) {
        $args->{font} = { %{$defaults->{font}}, %{$args->{font} // {}} };
    }
    return $args;
}

sub _tag_begin {
    my ($self, $tag_type) = @_;
    return unless _tagging $self;
    my $tree = _struct_tree $self;
    return unless $tree;
    my $stack = _struct_stack $self;
    my $parent = @$stack ? $stack->[-1] : $tree->root;
    my $elem = $parent->add_child($tag_type);
    push @$stack, $elem;
    _struct_stack $self, $stack;
}

sub _tag_end {
    my ($self) = @_;
    return unless _tagging $self;
    my $stack = _struct_stack $self;
    pop @$stack if @$stack;
    _struct_stack $self, $stack;
}

sub add_text {
    my ($self, %args) = @_;
    $self->_apply_configure('text', \%args);
    $self->_tag_begin('P');
    my $t = PDF::Make::Builder::Text->new(%args);
    $t->add($self);
    $self->_tag_end;
    return $self;
}

sub add_h1 {
    my ($self, %args) = @_;
    $self->_apply_configure('h1', \%args);
    $self->_tag_begin('H1');
    my $t = PDF::Make::Builder::Text::H1->new(%args);
    $t->add($self);
    $self->_tag_end;
    return $self;
}

sub add_h2 {
    my ($self, %args) = @_;
    $self->_apply_configure('h2', \%args);
    $self->_tag_begin('H2');
    my $t = PDF::Make::Builder::Text::H2->new(%args);
    $t->add($self);
    $self->_tag_end;
    return $self;
}

sub add_h3 {
    my ($self, %args) = @_;
    $self->_apply_configure('h3', \%args);
    $self->_tag_begin('H3');
    my $t = PDF::Make::Builder::Text::H3->new(%args);
    $t->add($self);
    $self->_tag_end;
    return $self;
}

sub add_h4 {
    my ($self, %args) = @_;
    $self->_apply_configure('h4', \%args);
    $self->_tag_begin('H4');
    my $t = PDF::Make::Builder::Text::H4->new(%args);
    $t->add($self);
    $self->_tag_end;
    return $self;
}

sub add_h5 {
    my ($self, %args) = @_;
    $self->_apply_configure('h5', \%args);
    $self->_tag_begin('H5');
    my $t = PDF::Make::Builder::Text::H5->new(%args);
    $t->add($self);
    $self->_tag_end;
    return $self;
}

sub add_h6 {
    my ($self, %args) = @_;
    $self->_apply_configure('h6', \%args);
    $self->_tag_begin('H6');
    my $t = PDF::Make::Builder::Text::H6->new(%args);
    $t->add($self);
    $self->_tag_end;
    return $self;
}

sub add_lines {
    my ($self, @lines) = @_;
    for my $line (@lines) {
        if (ref $line eq 'HASH') {
            $self->add_text(%$line);
        } else {
            $self->add_text(text => $line);
        }
    }
    return $self;
}

# ── Shapes ─────────────────────────────────────────────────

sub add_line {
    my ($self, %args) = @_;
    my $s = PDF::Make::Builder::Shape::Line->new(%args);
    $s->add($self);
    return $self;
}

sub add_box {
    my ($self, %args) = @_;
    my $s = PDF::Make::Builder::Shape::Box->new(%args);
    $s->add($self);
    return $self;
}

sub add_circle {
    my ($self, %args) = @_;
    my $s = PDF::Make::Builder::Shape::Circle->new(%args);
    $s->add($self);
    return $self;
}

sub add_ellipse {
    my ($self, %args) = @_;
    my $s = PDF::Make::Builder::Shape::Ellipse->new(%args);
    $s->add($self);
    return $self;
}

sub add_pie {
    my ($self, %args) = @_;
    my $s = PDF::Make::Builder::Shape::Pie->new(%args);
    $s->add($self);
    return $self;
}

# ── Images ─────────────────────────────────────────────────

sub add_image {
    my ($self, %args) = @_;
    $self->_tag_begin('Figure');
    my $img = PDF::Make::Builder::Image->new(%args);
    $img->add($self);
    $self->_tag_end;
    return $self;
}

# ── Metadata ───────────────────────────────────────────────

sub title {
    my ($self, $val) = @_;
    (doc $self)->title($val);
    return $self;
}

sub author {
    my ($self, $val) = @_;
    (doc $self)->author($val);
    return $self;
}

sub subject {
    my ($self, $val) = @_;
    (doc $self)->subject($val);
    return $self;
}

sub keywords {
    my ($self, $val) = @_;
    (doc $self)->keywords($val);
    return $self;
}

sub creator {
    my ($self, $val) = @_;
    (doc $self)->creator($val);
    return $self;
}

sub producer {
    my ($self, $val) = @_;
    (doc $self)->producer($val);
    return $self;
}

# ── Outlines/Bookmarks ────────────────────────────────────

sub add_outline {
    my ($self, $title, %args) = @_;
    my $page_index = $args{page} // 0;
    my $dest_type  = $args{dest} // 'Fit';
    my $parent_key = $args{parent};
    my $left       = $args{left} // 0;
    my $top        = $args{top}  // 0;
    my $zoom       = $args{zoom} // 0;

    my $outlines = _outlines $self;
    my $item;

    if ($parent_key && $outlines->{$parent_key}) {
        $item = $outlines->{$parent_key}->add_child(
            $title, $page_index, $dest_type, $left, $top, $zoom
        );
    } else {
        $item = (doc $self)->add_outline(
            $title, $page_index, $dest_type, $left, $top, $zoom
        );
    }

    $outlines->{$title} = $item;
    _outlines $self, $outlines;
    return $self;
}

# ── Links/Actions ─────────────────────────────────────────

sub add_link {
    my ($self, %args) = @_;
    my $xs_doc = doc $self;

    my $target_builder_page;
    if (defined $args{on_page}) {
        my $idx = $args{on_page};
        my $all = pages $self;
        die "PDF::Make::Builder: on_page $idx does not exist" unless $all && $idx >= 0 && $idx < @$all;
        $target_builder_page = $all->[$idx];
    } else {
        $target_builder_page = page $self;
        die "PDF::Make::Builder: add_link requires a current page" unless $target_builder_page;
    }

    my $rect;
    if ($args{rect}) {
        $rect = $args{rect};
    } elsif (defined $args{x} || defined $args{y} || defined $args{w} || defined $args{h}) {
        die "PDF::Make::Builder: add_link builder coords require x,y,w,h"
            unless defined $args{x} && defined $args{y} && defined $args{w} && defined $args{h};

        my ($x, $y, $w, $h) = @args{qw/x y w h/};
        my $x0 = $x;
        my $x1 = $x + $w;
        my $y0 = $y;
        my $y1 = $y + $h;
        $rect = [$x0, $y0, $x1, $y1];
    } else {
        die "PDF::Make::Builder: add_link requires rect => [x0,y0,x1,y1] or builder coords x,y,w,h";
    }

    my $hl = $args{highlight} // 'Invert';
    my $annot_num;

    if ($args{url}) {
        $annot_num = $xs_doc->add_link_uri(@$rect, $args{url});
    } elsif (defined $args{page}) {
        $annot_num = $xs_doc->add_link_goto(@$rect, $args{page});
    } elsif ($args{action}) {
        # Named action: NextPage, PrevPage, FirstPage, LastPage, Print
        $annot_num = $xs_doc->add_link_named_action(@$rect, $args{action}, $hl);
    } elsif ($args{file}) {
        # External PDF link (GoToR)
        my $action = $xs_doc->action_gotor($args{file}, $args{file_page} // 0, $args{new_window} // 0);
        $annot_num = $xs_doc->add_link_with_action(@$rect, $action, $hl);
    } else {
        die "PDF::Make::Builder: add_link requires url, page, action, or file";
    }

    if ($annot_num) {
        my $page_obj;
        if (defined $args{on_page}) {
            my $target_page = $args{on_page};
            $page_obj = $xs_doc->get_page($target_page);
            die "PDF::Make::Builder: on_page $target_page does not exist" unless $page_obj;
        } else {
            $page_obj = $target_builder_page->xs_page;
        }
        $page_obj->add_annot($annot_num);
    }
    return $self;
}

# ── Annotations ──────────────────────────────────────────

sub add_note {
    my ($self, %args) = @_;

    # Visual note mode: draw a coloured callout box with lines of text
    if (exists $args{lines} || (exists $args{text} && ref $args{text} eq 'ARRAY')) {
        my $lines      = $args{lines} // $args{text};
        my $x          = $args{x}          // 72;
        my $w          = $args{w}          // 300;
        my $h          = $args{h}          // 70;
        my $bg         = $args{bg_colour}  // $args{fill_colour} // '#fffbeb';
        my $padding    = $args{padding}    // 12;
        my $line_gap   = $args{line_gap}   // 14;
        my $colour     = $args{colour}     // '#92400e';
        my $size       = $args{size}       // 10;

        my $cur = page $self;
        die "PDF::Make::Builder: add_note requires a current page" unless $cur;

        my $y;
        if (defined $args{y}) {
            $y = $args{y};
        } else {
            $y = $cur->cursor_y - $h;
            $cur->advance_y($h + 6);
        }

        $self->add_box(fill_colour => $bg, x => $x, y => $y, w => $w, h => $h);

        my $ty = $y + $h - $padding - $size;
        for my $line (@$lines) {
            my ($text, $fsize, $fcol, $italic) =
                ref $line eq 'HASH'
                    ? (@{$line}{qw(text size colour italic)})
                    : ($line, undef, undef, 0);
            $fsize //= $size;
            $fcol  //= $colour;
            $self->add_text(
                text => $text,
                x    => $x + $padding,
                y    => $ty,
                w    => $w - $padding * 2,
                font => { size => $fsize, colour => $fcol, ($italic ? (italic => 1) : ()) },
            );
            $ty -= $line_gap;
        }
        return $self;
    }

    # Annotation note mode (PDF sticky note)
    my $xs_doc = doc $self;
    my $rect = $args{rect} // die "PDF::Make::Builder: add_note requires rect or lines";
    my $text = $args{text} // '';
    my $icon = $args{icon} // 'Note';
    my $open = $args{open} // 0;

    # Resolve target page (defaults to current)
    my $target = $args{page};
    my $xs_page;
    if (defined $target) {
        my $ps = pages $self;
        die "PDF::Make::Builder: add_note: page index out of range"
            unless $target >= 0 && $target < scalar @$ps;
        $xs_page = $ps->[$target]->xs_page;
    } else {
        my $cur = page $self or die "PDF::Make::Builder: add_note requires a current page";
        $xs_page = $cur->xs_page;
    }

    my $annot_num = $xs_doc->add_text_annot(@$rect, $text, $icon, $open);
    $xs_page->add_annot($annot_num) if $annot_num;
    return $self;
}

sub add_stamp {
    my ($self, %args) = @_;

    # Visual stamp mode: draw a coloured box with centred bold label
    if (exists $args{text}) {
        my $text       = $args{text};
        my $x          = $args{x} // 72;
        my $w          = $args{w} // 200;
        my $h          = $args{h} // 50;
        my $bg         = $args{bg_colour}   // $args{fill_colour} // '#e5e7eb';
        my $colour     = $args{colour}      // '#111827';
        my $size       = $args{size}        // 20;
        my $border     = $args{border}      // 0;
        my $border_col = $args{border_colour} // $colour;

        my $cur = page $self;
        die "PDF::Make::Builder: add_stamp requires a current page" unless $cur;

        my $y;
        if (defined $args{y}) {
            $y = $args{y};
        } else {
            $y = $cur->cursor_y - $h;
            $cur->advance_y($h + 6);
        }

        $self->add_box(
            fill_colour   => $bg,
            x             => $x,
            y             => $y,
            w             => $w,
            h             => $h,
            ($border ? (border_colour => $border_col, border_width => $border) : ()),
        );
        $self->add_text(
            text  => $text,
            x     => $x,
            y     => $y + ($h / 2) + ($size * 0.66),
            w     => $w,
            align => 'center',
            font  => { size => $size, colour => $colour, bold => 1 },
        );
        return $self;
    }

    # Annotation stamp mode
    my $xs_doc = doc $self;
    my $rect = $args{rect} // die "PDF::Make::Builder: add_stamp requires rect or text";
    my $type = $args{type} // 'Draft';
    $xs_doc->add_stamp(@$rect, $type);
    return $self;
}

# ── Bates Numbering ──────────────────────────────────────

sub add_bates {
    my ($self, %args) = @_;
    my $stamp = PDF::Make::Stamp->bates(%args);
    my $xs_doc = doc $self;
    no warnings 'uninitialized';
    $xs_doc->apply_stamp($stamp);
    return $self;
}

# ── Custom Metadata ──────────────────────────────────────

sub set_meta {
    my ($self, $key, $value) = @_;
    (doc $self)->set_meta($key, $value);
    return $self;
}

sub get_meta {
    my ($self, $key) = @_;
    return (doc $self)->get_meta($key);
}

# ── Page Info ────────────────────────────────────────────

sub page_count {
    my ($self) = @_;
    return scalar @{pages $self};
}

# ── Output ───────────────────────────────────────────────

sub to_bytes {
    my ($self) = @_;

    # Finalize all pages (same as save but return bytes)
    my $all_pages = pages $self;
    my $offset = page_offset $self;
    my $rewrite = _apply_redactions_pending $self;
    for my $bp (@$all_pages) {
        next if $bp->imported;
        my $hdr = $bp->header;
        my $ftr = $bp->footer;
        my $pnum = $bp->num + $offset;
        $hdr->render($self, $bp, $pnum) if $hdr;
        $ftr->render($self, $bp, $pnum) if $ftr;
        my $bytes = ($rewrite && @{$bp->redactions})
            ? $self->_rewrite_redacted_canvas_bytes($bp)
            : $bp->canvas->to_bytes;
        $bp->xs_page->set_content($bytes);
    }

    if (_sanitize_pending $self) {
        PDF::Make::Redaction->sanitize(doc $self);
    }

    # Finalize form
    {
        my $xs_doc = doc $self;
        my $form = eval { PDF::Make::FormPtr::get($xs_doc) };
        if ($form) {
            PDF::Make::FormPtr::finalize($form);
        }
    }

    return (doc $self)->to_bytes;
}

# ── Attachments ───────────────────────────────────────────

sub attach {
    my ($self, %args) = @_;
    my $xs_doc = doc $self;
    PDF::Make::Attachment->attach($xs_doc, %args);
    return $self;
}

# ── Watermarks ────────────────────────────────────────────

sub add_watermark {
    my ($self, %args) = @_;
    my $text = delete $args{text} // die "PDF::Make::Builder: add_watermark requires text";
    my $wm = PDF::Make::Watermark->text($text, %args);
    my $wms = _watermarks $self;
    push @$wms, $wm;
    _watermarks $self, $wms;
    return $self;
}

# ── Encryption ────────────────────────────────────────────

sub encrypt {
    my ($self, %args) = @_;
    _encrypt_args $self, \%args;
    return $self;
}

# ── Layers/OCG ────────────────────────────────────────────

sub add_layer {
    my ($self, $name, %args) = @_;
    my $xs_doc = doc $self;
    my $layer = PDF::Make::Layer->create($xs_doc, $name);
    $layer->visible($args{visible}) if defined $args{visible};
    my $num = $layer->write_to_doc($xs_doc);
    my $cur = page $self;
    if ($cur) {
        $cur->xs_page->add_ocg($layer->res_name, $num);
    }
    my $layers = _layers $self;
    $layers->{$name} = $layer;
    _layers $self, $layers;
    return $self;
}

sub begin_layer {
    my ($self, $name) = @_;
    my $layers = _layers $self;
    my $layer = $layers->{$name} // die "PDF::Make::Builder: unknown layer '$name'";
    my $cur = page $self;
    die "PDF::Make::Builder: no current page" unless $cur;
    $cur->canvas->begin_layer($layer->res_name);
    return $self;
}

sub end_layer {
    my ($self) = @_;
    my $cur = page $self;
    die "PDF::Make::Builder: no current page" unless $cur;
    $cur->canvas->end_layer;
    return $self;
}

# ── Redaction ─────────────────────────────────────────────

sub mark_redaction {
    my ($self, %args) = @_;
    my $page_index = delete $args{page} // 0;
    my $ps = pages $self;
    die "PDF::Make::Builder: page index out of range"
        unless $page_index >= 0 && $page_index < scalar @$ps;

    my $bp = $ps->[$page_index];

    # Register the /Redact annotation for downstream tools.
    PDF::Make::Redaction->mark($bp->xs_page, %args);

    my $rect = $args{rect} or return $self;
    my ($x0, $y0, $x1, $y1) = @$rect;
    my ($w, $h) = ($x1 - $x0, $y1 - $y0);
    return $self if $w <= 0 || $h <= 0;

    my $colour = $args{overlay_colour} // $args{overlay_color} // '#000';
    my $text   = $args{overlay_text};
    my $size   = $args{overlay_font_size} // 10;

    # Remember the redaction so save-time can rewrite the content stream
    # to actually remove text that falls inside the rect, then repaint
    # the overlay on top of the filtered stream.
    my $list = $bp->redactions;
    push @$list, {
        rect         => [$x0, $y0, $x1, $y1],
        overlay_text => $text,
        overlay_size => $size,
        overlay_fill => $colour,
    };
    $bp->redactions($list);

    # Eagerly paint the opaque cover so that even a user who never calls
    # apply_redactions sees the sensitive area visually hidden.
    my $font   = $self->font;
    my ($r, $g, $b) = $font->hex_to_rgb($colour);
    my $canvas = $bp->canvas;

    $canvas->q->rg($r, $g, $b)->re($x0, $y0, $w, $h)->f->Q;

    if (defined $text && length $text) {
        my $res = $font->ensure_loaded($bp->xs_page, 'normal');
        my ($tr, $tg, $tb) = $font->hex_to_rgb('#fff');
        my $tw = $font->measure_text($text) * ($size / ($font->size || 9));
        my $tx = $x0 + ($w - $tw) / 2;
        $tx = $x0 + 4 if $tw > $w - 4;
        my $ty = $y0 + ($h - $size) / 2 + 1;
        $canvas->q
               ->BT
               ->rg($tr, $tg, $tb)
               ->Tf($res, $size)
               ->Tm(1, 0, 0, 1, $tx, $ty)
               ->Tj($text)
               ->ET
               ->Q;
    }

    return $self;
}

sub apply_redactions {
    my ($self) = @_;
    _apply_redactions_pending $self, 1;
    return $self;
}

sub sanitize {
    my ($self) = @_;
    _sanitize_pending $self, 1;
    return $self;
}

# Internal: filter the canvas bytes for one page through the redaction
# rewriter and re-paint overlay text.  Called from save() / to_bytes()
# when $builder->_apply_redactions_pending is set.
sub _rewrite_redacted_canvas_bytes {
    my ($self, $bp) = @_;
    my $reds = $bp->redactions;
    return $bp->canvas->to_bytes unless $reds && @$reds;

    my $raw_bytes = $bp->canvas->to_bytes;
    my @rects = map { $_->{rect} } @$reds;
    my $filtered = PDF::Make::Redaction->rewrite_stream($raw_bytes, \@rects);

    # Re-paint overlay text for each redaction on a fresh small canvas
    # so those BT..ET blocks come AFTER the filtered stream and are not
    # themselves dropped by the filter.
    my $overlay_canvas = PDF::Make::Canvas->new;
    my $font = $self->font;
    for my $r (@$reds) {
        my ($x0, $y0, $x1, $y1) = @{$r->{rect}};
        my ($w, $h) = ($x1 - $x0, $y1 - $y0);
        next if $w <= 0 || $h <= 0;

        # Black rect (re-paint since the filter kept the original, but
        # redundant paints are harmless and guard against any edge case
        # where the original rect op was adjacent to a dropped block).
        my ($br, $bg, $bb) = $font->hex_to_rgb($r->{overlay_fill} // '#000');
        $overlay_canvas->q->rg($br, $bg, $bb)->re($x0, $y0, $w, $h)->f->Q;

        my $text = $r->{overlay_text};
        next unless defined $text && length $text;

        my $size = $r->{overlay_size} || 10;
        my $res  = $font->ensure_loaded($bp->xs_page, 'normal');
        my ($tr, $tg, $tb) = $font->hex_to_rgb('#fff');
        my $tw = $font->measure_text($text) * ($size / ($font->size || 9));
        my $tx = $x0 + ($w - $tw) / 2;
        $tx = $x0 + 4 if $tw > $w - 4;
        my $ty = $y0 + ($h - $size) / 2 + 1;
        $overlay_canvas->q
                       ->BT
                       ->rg($tr, $tg, $tb)
                       ->Tf($res, $size)
                       ->Tm(1, 0, 0, 1, $tx, $ty)
                       ->Tj($text)
                       ->ET
                       ->Q;
    }

    return $filtered . $overlay_canvas->to_bytes;
}

# ── Color Management ──────────────────────────────────────

sub set_color_space {
    my ($self, $type, %args) = @_;
    my $cs;
    if ($type eq 'sRGB') {
        $cs = PDF::Make::Color->srgb;
    } elsif ($type eq 'separation') {
        $cs = PDF::Make::Color->separation(
            $args{name}, $args{c} // 0, $args{m} // 0, $args{y} // 0, $args{k} // 0
        );
    } else {
        die "PDF::Make::Builder: unknown color space '$type'";
    }
    my $xs_doc = doc $self;
    $cs->write_to_doc($xs_doc);
    return $self;
}

# ── Tagged PDF / Accessibility ────────────────────────────

sub enable_tagging {
    my ($self) = @_;
    my $xs_doc = doc $self;
    my $tree = PDF::Make::Structure->create_tree($xs_doc);
    _struct_tree $self, $tree;
    _tagging $self, 1;
    return $self;
}

# ── Forms ─────────────────────────────────────────────────

my %_field_class = (
    text     => 'PDF::Make::Builder::Form::Field::Text',
    checkbox => 'PDF::Make::Builder::Form::Field::Checkbox',
    radio    => 'PDF::Make::Builder::Form::Field::Radio',
    combo    => 'PDF::Make::Builder::Form::Field::Combo',
    dropdown => 'PDF::Make::Builder::Form::Field::Combo',
    listbox  => 'PDF::Make::Builder::Form::Field::Listbox',
    list     => 'PDF::Make::Builder::Form::Field::Listbox',
    button   => 'PDF::Make::Builder::Form::Field::Button',
);

sub add_field {
    my ($self, %args) = @_;

    my $type = delete $args{type} // die "PDF::Make::Builder: add_field requires type";
    my $name = delete $args{name} // die "PDF::Make::Builder: add_field requires name";

    my $class = $_field_class{$type}
        // die "PDF::Make::Builder: unknown field type '$type'";

    # Default to structured mode. Enter raw mode for explicit coordinates
    # or when requested directly.
    my $raw_mode = delete $args{raw_mode};
    if (!defined $raw_mode) {
        $raw_mode = (exists $args{rect} || exists $args{x} || exists $args{y}) ? 1 : 0;
    }

    if (!$raw_mode) {
        if (exists $args{default} && !exists $args{default_value}) {
            $args{default_value} = delete $args{default};
        }
        my $field = $class->new(field_name => $name, %args);
        $field->add($self);
        return $self;
    }

    # Raw mode (direct widget placement)
    my $default = delete $args{default};
    $default = delete $args{default_value} unless defined $default;

    my $cur = page $self;
    die "PDF::Make::Builder: no current page" unless $cur;

    my ($x, $y, $w, $h);
    if ($args{rect}) {
        ($x, $y, $w, $h) = @{delete $args{rect}};
    } else {
        # Cursor-relative placement like add_text
        $x = delete $args{x} // $cur->content_x;
        $w = delete $args{w} // $cur->width;
        $h = delete $args{h} // 22;
        if (defined $args{y}) {
            $y = delete $args{y};
        } else {
            $y = $cur->cursor_y - $h;
        }
        # Advance cursor past the field
        $cur->advance_y($h + 4);
    }
    die "PDF::Make::Builder: field requires coordinates"
        unless defined $x && defined $y && defined $w && defined $h;

    my %fargs = (
        field_name    => $name,
        x             => $x,
        y             => $y,
        w             => $w,
        h             => $h,
        raw_mode      => 1,
    );

    $fargs{default_value} = $default if defined $default;

    $fargs{readonly} = $args{readonly} ? 1 : 0 if exists $args{readonly};
    $fargs{required} = $args{required} ? 1 : 0 if exists $args{required};
    $fargs{da} = $args{da} if exists $args{da};

    # Field-specific passthrough
    $fargs{options} = $args{options} if exists $args{options};
    $fargs{caption} = $args{caption} if exists $args{caption};
    $fargs{on_value} = $args{on_value} if exists $args{on_value};

    my $field = $class->new(%fargs);
    $field->add($self);

    return $self;
}

sub flatten_form {
    my ($self) = @_;
    _flatten_pending $self, 1;
    return $self;
}

# ── Digital Signatures ────────────────────────────────────

sub sign {
    my ($self, %args) = @_;
    _sign_args $self, \%args;
    return $self;
}

# ── TOC ────────────────────────────────────────────────────

sub add_toc {
    my ($self, %args) = @_;
    my $cfg = configure $self;
    my $toc_cfg = $cfg->{toc} // {};
    my $cur = page $self;
    my $default_toc_page = $cur ? ($cur->num - 1) : 0;
    %args = (%$toc_cfg, %args);
    $args{page_index} = $default_toc_page unless exists $args{page_index};
    toc $self, PDF::Make::Builder::TOC->new(%args);
    return $self;
}

# ── Save ───────────────────────────────────────────────────

sub save {
    my ($self) = @_;

    # Render TOC if present
    my $cur = page $self;
    if ($cur) {
        my $t = toc $self;
        if ($t && @{$t->entries}) {
            $t->render($self);
        }
    }

    # Render headers/footers onto each page's canvas, then finalize
    my $all_pages = pages $self;
    my $offset = page_offset $self;
    my $rewrite = _apply_redactions_pending $self;
    for my $bp (@$all_pages) {
        if ($bp->imported) {
            # Imported pages keep their original content, but any overlay
            # drawing issued against the Builder's canvas (e.g. a box
            # around extracted text) needs to be appended so it renders
            # on top of the source graphics.
            my $overlay = $bp->canvas->to_bytes;
            if (defined $overlay && length $overlay) {
                $bp->xs_page->append_content($overlay);
            }
            next;
        }
        my $hdr = $bp->header;
        my $ftr = $bp->footer;
        my $pnum = $bp->num + $offset;

        if ($hdr) {
            $hdr->render($self, $bp, $pnum);
        }
        if ($ftr) {
            $ftr->render($self, $bp, $pnum);
        }

        # Finalize page content; filter through the redaction rewriter
        # when the user has called apply_redactions.
        my $bytes = ($rewrite && @{$bp->redactions})
            ? $self->_rewrite_redacted_canvas_bytes($bp)
            : $bp->canvas->to_bytes;
        $bp->xs_page->set_content($bytes);
    }

    if (_sanitize_pending $self) {
        PDF::Make::Redaction->sanitize(doc $self);
    }

    # Apply deferred watermarks after all page content is set
    {
        my $wms = _watermarks $self;
        if ($wms && @$wms) {
            my $xs_doc = doc $self;
            for my $wm (@$wms) {
                $xs_doc->add_watermark($wm);
            }
        }
    }

    # Flatten form fields if requested (after set_content so canvas is committed)
    if (_flatten_pending $self) {
        my $xs_doc = doc $self;
        my $form = eval { PDF::Make::FormPtr::get($xs_doc) };
        $form->flatten if $form;
    }

    # Finalize form if any fields were added
    {
        my $xs_doc = doc $self;
        my $form = eval { PDF::Make::FormPtr::get($xs_doc) };
        if ($form) {
            PDF::Make::FormPtr::finalize($form);
        }
    }

    # Apply encryption if configured.  The actual /Encrypt dict is built,
    # and per-object encryption applied, inside pdfmake_doc_write.
    my $enc = _encrypt_args $self;
    if ($enc) {
        my $algo  = $enc->{algorithm}      // 'AES-256';
        my $user  = $enc->{user_password}  // $enc->{password} // '';
        my $owner = $enc->{owner_password} // $user;
        my $perms = $enc->{permissions}    // 0xFFFFFFFC;
        my $xs_doc = doc $self;
        $xs_doc->set_encryption($algo, $user, $owner, $perms);
    }

    # Apply digital signature if configured.  pdfmake_doc_sign returns
    # the signed PDF bytes (original doc + /Sig dict + PKCS#7 /Contents),
    # so when signing is active we write the returned bytes, not the
    # unsigned doc->to_bytes() output.
    my $sig = _sign_args $self;
    my $signed_bytes;
    if ($sig && $sig->{pkcs12} && -f $sig->{pkcs12}) {
        my $identity = PDF::Make::Signature->load_identity(
            file     => $sig->{pkcs12},
            password => $sig->{password} // '',
        );
        die "PDF::Make::Builder: sign: identity has no usable signing key"
            unless $identity && $identity->can_sign;

        my $xs_doc = doc $self;
        $signed_bytes = PDF::Make::Signature::_sign_document($xs_doc,
            identity      => $identity,
            reason        => $sig->{reason},
            location      => $sig->{location},
            contact       => $sig->{contact},
            name          => $sig->{name},
            hash          => $sig->{hash},
            timestamp_url => $sig->{timestamp_url},
            tsa_timeout   => $sig->{tsa_timeout},
            visible       => $sig->{visible},
            page          => $sig->{page},
            rect          => $sig->{rect},
            appearance    => $sig->{appearance},
        );
    }

    # Write to file
    my $xs_doc = doc $self;
    my $fname = file_name $self;
    $fname .= '.pdf' unless $fname =~ /\.pdf$/i;
    my $dir = dirname($fname);
    if (defined $dir && length $dir && $dir ne '.') {
        make_path($dir) unless -d $dir;
    }
    if (defined $signed_bytes) {
        open my $fh, '>:raw', $fname or die "PDF::Make::Builder: cannot write '$fname': $!";
        print $fh $signed_bytes;
        close $fh;
    } else {
        $xs_doc->to_file($fname);
    }

    return $self;
}

# ── Onsave callback management ─────────────────────────────

sub onsave {
    my ($self, $key, $method, %args) = @_;
    my $cbs = onsave_cbs $self;
    push @$cbs, [$key, $method, %args];
    onsave_cbs $self, $cbs;
    return $self;
}

# ── Text extraction (phase 13) ────────────────────────────

sub extract_text {
    my ($self, $file, $page_index) = @_;
    $page_index //= 0;
    my $parser = PDF::Make::Parser->from_file($file);
    return PDF::Make::Extract->extract($parser, $page_index);
}

sub extract_structured {
    my ($self, $file, %args) = @_;
    my $page_index = $args{page} // 0;
    my $include_invisible = exists $args{invisible}
                          ? ($args{invisible} ? 1 : 0)
                          : 1;
    my $parser = PDF::Make::Parser->from_file($file, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);
    if ($reader->is_encrypted && !$reader->is_authenticated) {
        my $pw = $args{password} // '';
        my $rc = $reader->set_password($pw);
        die "PDF::Make::Builder: extract_structured: authentication failed for '$file'"
            if $rc < 0;
    }
    my $raw = PDF::Make::Extract->_extract_structured(
        $reader, $page_index, $include_invisible);
    return PDF::Make::Extract::Result->new(data => $raw);
}

sub extract_annotations {
    my ($self, $file, %args) = @_;
    my $parser = PDF::Make::Parser->from_file($file, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);
    if ($reader->is_encrypted && !$reader->is_authenticated) {
        my $pw = $args{password} // '';
        my $rc = $reader->set_password($pw);
        die "PDF::Make::Builder: extract_annotations: authentication failed for '$file'"
            if $rc < 0;
    }
    my $list = PDF::Make::Extract->_extract_annotations($reader);
    return wantarray ? @$list : $list;
}

sub detect_tables {
    my ($self, $file, %args) = @_;
    my $page_index = $args{page} // 0;
    my $parser = PDF::Make::Parser->from_file($file, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);
    if ($reader->is_encrypted && !$reader->is_authenticated) {
        my $pw = $args{password} // '';
        my $rc = $reader->set_password($pw);
        die "PDF::Make::Builder: detect_tables: authentication failed for '$file'"
            if $rc < 0;
    }
    my $list = PDF::Make::Extract->_detect_tables($reader, $page_index);
    return wantarray ? @$list : $list;
}

# ── Open existing PDF ────────────────────────────────────

sub open_existing {
    my ($class, $file, %args) = @_;

    my $password = delete $args{password};
    my $out_file = delete $args{file_name} // $file;

    die "PDF::Make::Builder: open_existing: file '$file' not found" unless -f $file;

    my $self = $class->new(file_name => $out_file, %args);

    # Round-trip the source document: content + resources + dimensions.
    $self->append_pdf($file, password => $password);

    return $self;
}

# ── Append pages from another PDF ─────────────────────────

sub append_pdf {
    my ($self, $file, %args) = @_;

    die "PDF::Make::Builder: append_pdf: file '$file' not found" unless -f $file;

    my $parser = PDF::Make::Parser->from_file($file, repair => 1);
    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);

    if ($reader->is_encrypted && !$reader->is_authenticated) {
        my $pw = $args{password} // '';
        my $rc = $reader->set_password($pw);
        die "PDF::Make::Builder: append_pdf: authentication failed for '$file'"
            if $rc < 0;
    }

    my $xs_doc = doc $self;
    my $importer = PDF::Make::Import->new($reader, $xs_doc);

    my $count = $reader->page_count;
    my @indices = $args{pages} ? @{$args{pages}} : (0 .. $count - 1);

    for my $idx (@indices) {
        die "PDF::Make::Builder: append_pdf: page index $idx out of range (file has $count pages)"
            unless $idx >= 0 && $idx < $count;

        my $before = $xs_doc->page_count;
        my $ok = $importer->import_page($idx);
        unless ($ok) {
            warn "PDF::Make::Builder: append_pdf: failed to import page $idx from '$file'";
            next;
        }
        my $after = $xs_doc->page_count;

        for my $pi ($before .. $after - 1) {
            my $xs_page = $xs_doc->get_page($pi);
            my $pages   = pages $self;
            my $num     = scalar(@$pages) + 1;
            my $bp = PDF::Make::Builder::Page->new(
                page_size  => 'custom',
                background => '#fff',
                columns    => 1,
                padding    => 20,
                num        => $num,
                w          => $xs_page->width,
                h          => $xs_page->height,
                canvas     => PDF::Make::Canvas->new,
                xs_page    => $xs_page,
                imported   => 1,
            );
            push @$pages, $bp;
            pages $self, $pages;
            page $self, $bp;
        }
    }

    return $self;
}

sub merge {
    my ($class, $out_file, @inputs) = @_;
    die "PDF::Make::Builder::merge: no input files" unless @inputs;

    my $b = $class->new(file_name => $out_file);
    for my $f (@inputs) {
        $b->append_pdf($f);
    }
    $b->save;
    return $b;
}

# ── Page editing (phase 15) ───────────────────────────────

sub remove_page {
    my ($self, $index) = @_;
    my $ps = pages $self;
    die "PDF::Make::Builder: page index out of range" unless $index >= 0 && $index < scalar @$ps;
    splice @$ps, $index, 1;
    # Re-number remaining pages
    for my $i (0 .. $#$ps) {
        $ps->[$i]->num($i + 1);
    }
    pages $self, $ps;
    # Switch to last page if current was removed
    if (scalar @$ps) {
        page $self, $ps->[-1];
    } else {
        page $self, undef;
    }
    return $self;
}

sub move_page {
    my ($self, $from, $to) = @_;
    my $ps = pages $self;
    die "PDF::Make::Builder: from index out of range" unless $from >= 0 && $from < scalar @$ps;
    die "PDF::Make::Builder: to index out of range" unless $to >= 0 && $to < scalar @$ps;
    my $pg = splice @$ps, $from, 1;
    splice @$ps, $to, 0, $pg;
    for my $i (0 .. $#$ps) {
        $ps->[$i]->num($i + 1);
    }
    pages $self, $ps;
    return $self;
}

sub duplicate_page {
    my ($self, $index) = @_;
    my $ps = pages $self;
    die "PDF::Make::Builder: page index out of range" unless $index >= 0 && $index < scalar @$ps;

    my $src = $ps->[$index];

    # Finalize source page content
    $src->xs_page->set_content($src->canvas->to_bytes);

    # Create a new page with same dimensions
    my $xs_doc = doc $self;
    my $xs_page = $xs_doc->add_page($src->w, $src->h);
    my $canvas = PDF::Make::Canvas->new;

    my $bp = PDF::Make::Builder::Page->new(
        page_size  => $src->page_size,
        background => $src->background,
        columns    => $src->columns,
        padding    => $src->padding,
        num        => scalar(@$ps) + 1,
        w          => $src->w,
        h          => $src->h,
        canvas     => $canvas,
        xs_page    => $xs_page,
        header     => $src->header,
        footer     => $src->footer,
    );

    push @$ps, $bp;
    pages $self, $ps;
    page $self, $bp;

    return $self;
}

sub rotate_page {
    my ($self, $index, $degrees) = @_;
    my $ps = pages $self;
    die "PDF::Make::Builder: page index out of range" unless $index >= 0 && $index < scalar @$ps;
    die "PDF::Make::Builder: rotation must be 0, 90, 180, or 270"
        unless grep { $degrees == $_ } (0, 90, 180, 270);

    # Swap width/height for 90/270 rotation
    my $pg = $ps->[$index];
    if ($degrees == 90 || $degrees == 270) {
        my ($w, $h) = ($pg->w, $pg->h);
        $pg->w($h);
        $pg->h($w);
    }

    return $self;
}

# ── Load TrueType font (phase 12) ────────────────────────

sub load_ttf {
    my ($self, $path, %args) = @_;
    my $font_obj = PDF::Make::Font->from_file($path);
    my $doc = doc $self;
    my $obj_num = $font_obj->write_to_doc($doc);

    my $name = $args{name} // 'TT' . $obj_num;
    my $cur = page $self;
    if ($cur) {
        $cur->xs_page->add_font($name, $font_obj->base_font);
    }

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder - High level chainable PDF document builder

=head1 SYNOPSIS

    use PDF::Make::Builder;

    # Simple document
    PDF::Make::Builder->new(file_name => 'report.pdf')
        ->add_page(page_size => 'A4')
        ->title('Quarterly Report')
        ->author('Jane Smith')
        ->add_h1(text => 'Introduction')
        ->add_text(text => 'Revenue increased 15% year-over-year.')
        ->add_image(image => 'chart.jpg', w => 400)
        ->save;

    # With configuration defaults
    my $b = PDF::Make::Builder->new(
        file_name => 'styled.pdf',
        configure => {
            text => { font => { family => 'Times', size => 11 } },
            h1   => { font => { family => 'Helvetica', size => 24 } },
        },
    );
    $b->add_page(page_size => 'Letter', padding => 36)
      ->add_h1(text => 'Title')
      ->add_text(text => 'Body text inherits Times 11pt.')
      ->save;

=head1 DESCRIPTION

C<PDF::Make::Builder> is the recommended high level API for creating PDF
documents. It wraps the low level L<PDF::Make::Document> and
L<PDF::Make::Canvas> with a chainable, bottom-left coordinate system that
handles page layout, word-wrap, font management, and content placement
automatically.

Every method returns C<$self>, enabling fluent method chaining.

=head1 CONSTRUCTOR

=head2 new(%args)

    my $b = PDF::Make::Builder->new(
        file_name => 'output.pdf',          # required
        configure => { ... },               # optional defaults
        page_offset => 0,                   # page number offset
    );

=over 4

=item C<file_name> (Str, required) - Output filename. C<.pdf> is appended if missing.

=item C<configure> (HashRef) - Default font/style overrides keyed by element
type (C<text>, C<h1>-C<h6>, C<toc>). Each accepts a C<font> sub-hash with
C<family>, C<size>, C<colour>, C<line_height>.

=item C<page_offset> (Int, default 0) - Added to page numbers in headers/footers.

=back

=head1 METHODS

=head2 Page Management

=head3 add_page(%args)

    $b->add_page(
        page_size  => 'A4',       # A4, Letter, Legal, A3, A5, B5, Tabloid
        padding    => 20,         # margin in points
        columns    => 1,          # number of text columns
        background => '#fff',     # hex background color
    );

Add a new page and make it the current page. Finalises the previous page's
content stream automatically.

=head3 open_page($num)

    $b->open_page(2);    # switch to page 2 (1-based)

Switch the current page to an existing page by number.

=head3 remove_page($index)

    $b->remove_page(0);  # remove first page (0-based)

Remove a page by 0-based index. Remaining pages are renumbered.

=head3 move_page($from, $to)

    $b->move_page(2, 0);  # move page 3 to position 1

Move a page from one position to another (0-based indices).

=head3 duplicate_page($index)

    $b->duplicate_page(0);  # duplicate first page

Create a copy of a page (layout only, not content).

=head3 rotate_page($index, $degrees)

    $b->rotate_page(0, 90);  # rotate first page 90 degrees

Rotate a page. Valid values: 0, 90, 180, 270.

=head3 set_columns($n)

    $b->set_columns(2);

Set the number of text columns on the current page.

=head2 Metadata

All metadata methods set values on the underlying PDF Info dictionary.

=head3 title($text)

    $b->title('My Document');

=head3 author($text)

    $b->author('Jane Smith');

=head3 subject($text)

    $b->subject('Annual Report');

=head3 keywords($text)

    $b->keywords('pdf, report, 2026');

=head3 creator($text)

    $b->creator('MyApp v2.0');

=head3 producer($text)

    $b->producer('PDF::Make');

=head2 Text Content

=head3 add_text(%args)

    $b->add_text(
        text    => 'Hello world',
        font    => { family => 'Helvetica', size => 12, colour => '#333' },
        align   => 'left',       # left, center, right
        indent  => 0,            # first-line indent in points
        padding => 5,            # vertical padding
    );

Add a paragraph of word-wrapped text at the current cursor position. Overflows
to new pages automatically.

=head3 add_h1(%args) .. add_h6(%args)

    $b->add_h1(text => 'Chapter Title');
    $b->add_h2(text => 'Section');

Add headings with preset font sizes. H1 is largest (24pt bold), H6 is
smallest (10pt bold). Accepts the same arguments as C<add_text>.

=head3 add_lines(@lines)

    $b->add_lines(
        'First line of text.',
        'Second line of text.',
        { text => 'Styled line', font => { size => 14, colour => '#c00' } },
    );

Convenience wrapper that calls C<add_text> for each element in C<@lines>.
Each element may be a plain string (used as C<text =E<gt> $str>) or a HashRef
of named arguments passed directly to C<add_text>.

=head2 Shapes

=head3 add_line(%args)

    $b->add_line(
        x           => 72,        # start X
        ex          => 523,       # end X
        fill_colour => '#000',
        type        => 'solid',   # solid, dashed, dotted
    );

=head3 add_box(%args)

    $b->add_box(x => 72, w => 200, h => 100, fill_colour => '#eee');

=head3 add_circle(%args)

    $b->add_circle(cx => 200, cy => 400, r => 50, fill_colour => '#0066cc');

=head3 add_ellipse(%args)

    $b->add_ellipse(cx => 200, cy => 400, rx => 80, ry => 40);

=head3 add_pie(%args)

    $b->add_pie(
        cx => 200, cy => 400, r => 50,
        start_angle => 0, end_angle => 90,
        fill_colour => '#cc0000',
    );

=head2 Images

=head3 add_image(%args)

    $b->add_image(
        image => 'photo.jpg',   # path to JPEG or PNG
        w     => 300,           # width (height auto-calculated)
        align => 'center',      # left, center
    );

=head2 Fonts

=head3 load_font(%args)

    $b->load_font(family => 'Courier', size => 10, colour => '#333');

Set the default font for subsequent text operations.

=head3 load_ttf($path, %args)

    $b->load_ttf('fonts/MyFont.ttf', name => 'MF1');

Load a TrueType font file and register it in the document.

=head2 Table of Contents

=head3 add_toc(%args)

    $b->add_toc(title => 'Contents');

Initialise a table of contents. TOC entries are collected from headings and
rendered during C<save()>.

=head2 Headers and Footers

=head3 add_page_header(%args)

    $b->add_page_header(
        cb     => sub { my ($builder, $page, $num) = @_; ... },
        height => 30,
    );

Add a repeating header to all pages (current and future).

=head3 add_page_footer(%args)

    $b->add_page_footer(
        cb     => sub { my ($builder, $page, $num) = @_; ... },
        height => 30,
    );

Add a repeating footer to all pages.

=head3 remove_page_header()

Remove the page header from subsequent pages.

=head3 remove_page_footer()

Remove the page footer from subsequent pages.

=head3 remove_page_header_and_footer()

Remove both header and footer from subsequent pages.

=head2 Outlines (Bookmarks)

=head3 add_outline($title, %args)

    $b->add_outline('Chapter 1', page => 0);
    $b->add_outline('Section 1.1', page => 0, parent => 'Chapter 1');
    $b->add_outline('Chapter 2', page => 1, dest => 'FitH', top => 700);

Add a PDF outline (bookmark) entry.

=over 4

=item C<page> (Int, default 0) - 0-based page index

=item C<parent> (Str) - Title of the parent outline for nesting

=item C<dest> (Str, default 'Fit') - Destination type: Fit, FitH, FitV, XYZ

=item C<left>, C<top>, C<zoom> (Num) - Destination parameters

=back

=head2 Links and Actions

=head3 add_link(%args)

    # External URL
    $b->add_link(url => 'https://example.com', rect => [72, 700, 200, 720]);

    # Builder coordinates (bottom-left origin)
    $b->add_link(url => 'https://example.com', x => 72, y => 140, w => 220, h => 28);

    # Internal page link
    $b->add_link(page => 3, rect => [72, 670, 200, 690]);

    # Named action (NextPage, PrevPage, FirstPage, LastPage, Print)
    $b->add_link(action => 'NextPage', rect => [72, 640, 200, 660]);

    # Link to external PDF
    $b->add_link(file => 'other.pdf', file_page => 0, rect => [72, 610, 200, 630]);

Add a clickable link annotation. Requires C<rect> as C<[x0, y0, x1, y1]> in
PDF coordinates. Provide one of: C<url> (external), C<page> (internal GoTo),
C<action> (named action), or C<file> (external PDF).

For builder-layer coordinates (bottom-left origin), provide C<x>, C<y>, C<w>, and
C<h> instead of C<rect>. These are converted to PDF annotation coordinates
automatically.

=head2 Attachments

=head3 attach(%args)

    $b->attach(
        name        => 'data.csv',          # required
        data        => $csv_string,         # provide data or path
        path        => '/path/to/file',     # alternative to data
        mime        => 'text/csv',          # auto-detected if omitted
        description => 'Raw export data',
    );

Embed a file attachment in the PDF.

=head2 Watermarks

=head3 add_watermark(%args)

    $b->add_watermark(
        text     => 'DRAFT',       # required
        opacity  => 0.3,
        rotation => 45,
        color    => [0.8, 0.2, 0.2],
        size     => 72,
    );

Add a text watermark to all pages. See L<PDF::Make::Watermark> for all
options.

=head2 Layers (Optional Content Groups)

=head3 add_layer($name, %args)

    $b->add_layer('Dimensions', visible => 1);

Create a named layer on the current page.

=head3 begin_layer($name)

    $b->begin_layer('Dimensions');

Start drawing on the named layer.

=head3 end_layer()

    $b->end_layer;

Stop drawing on the current layer.

=head2 Redaction

=head3 mark_redaction(%args)

    $b->mark_redaction(
        page          => 0,                     # 0-based page index
        rect          => [100, 700, 300, 720],
        overlay_color => [0, 0, 0],
        overlay_text  => 'REDACTED',
    );

Mark a rectangular area for redaction.

=head3 apply_redactions()

Apply all redaction marks across all pages.

=head3 sanitize()

Remove all metadata (title, author, etc.) from the document.

=head2 Color Spaces

=head3 set_color_space($type, %args)

    $b->set_color_space('sRGB');
    $b->set_color_space('separation',
        name => 'PANTONE 185 C', c => 0, m => 0.81, y => 0.69, k => 0);

Register a color space in the document.

=head2 Tagged PDF (Accessibility)

=head3 enable_tagging()

    $b->enable_tagging;

Enable tagged PDF output with a structure tree for accessibility.

=head2 Form Fields

=head3 add_field(%args)

Structured mode (cursor-based component rendering):

    $b->add_field(
        type          => 'text',
        name          => 'email',
        label         => 'Email Address',
        w             => 300,
        default_value => 'user@example.com',
    );

    $b->add_field(
        type  => 'checkbox',
        name  => 'agree',
        label => 'I agree to the terms',
        w     => 16, h => 16,
    );

Raw mode (explicit coordinates):

    $b->add_field(
        type     => 'text',
        name     => 'email',
        raw_mode => 1,
        rect     => [72, 700, 300, 720],
        default  => 'user@example.com',
    );

    Single form API with two modes:

    =over 4

    =item * Structured mode via C<type>/C<name> (cursor-based layout,
    labels, styled borders). Supported types: C<text>, C<checkbox>, C<radio>,
    C<combo>/C<dropdown>, C<listbox>/C<list>, C<button>.

    =item * Raw mode via C<raw_mode =E<gt> 1> or explicit coordinates
    (C<rect>, C<x>, C<y>) for direct widget placement.

    =back

    See L<PDF::Make::Builder::Form::Field> for structured-mode properties.

=head3 flatten_form()

Burn form field appearances into page content (makes fields non-editable).

=head2 Encryption

=head3 encrypt(%args)

    $b->encrypt(password => 'secret', algorithm => 'AES-256');
    $b->encrypt(
        user_password  => 'read',
        owner_password => 'admin',
        permissions    => 0x04,
        algorithm      => 'AES-128',      # RC4-40, RC4-128, AES-128, AES-256
    );

Configure PDF encryption. Applied during C<save()>.

=head2 Digital Signatures

=head3 sign(%args)

    $b->sign(pkcs12 => 'cert.p12', password => 'secret', reason => 'Approval');

Configure a digital signature. Applied during C<save()>.

=head2 Annotations

=head3 add_note(%args)

Visual note (drawn callout box with lines of text):

    $b->add_note(
        lines      => [
            'Note: Review section 3.2 before final sign-off.',
            { text => '-- QA Team, 2026-04-21', size => 9, italic => 1 },
        ],
        bg_colour  => '#fffbeb',
        colour     => '#92400e',
        x => 72, w => 300, h => 70,
    );

Annotation note (PDF viewer sticky note):

    $b->add_note(
        rect => [72, 700, 92, 720],
        text => 'Review this section',
        icon => 'Comment',       # Note, Comment, Key, Help, Paragraph, Insert
        open => 1,               # show expanded
    );

When C<lines> (or C<text> as an ArrayRef) is supplied the method draws a
coloured rectangle with the lines rendered inside it. Omit C<y> to use
cursor-relative placement.

Visual note options:

=over 4

=item C<lines> (ArrayRef, required) - Lines to render. Each element is a plain
string or a HashRef with C<text>, C<size>, C<colour>, C<italic> keys.

=item C<x> (Num, default 72) - Left edge

=item C<y> (Num) - Bottom edge; omit to use cursor position

=item C<w> (Num, default 300) - Width

=item C<h> (Num, default 70) - Height

=item C<bg_colour> / C<fill_colour> (Str, default '#fffbeb') - Background fill

=item C<colour> (Str, default '#92400e') - Default text colour

=item C<size> (Num, default 10) - Default font size

=item C<padding> (Num, default 12) - Inner padding in points

=item C<line_gap> (Num, default 14) - Vertical gap between lines in points

=back

=head3 add_stamp(%args)

Visual stamp (drawn box with centred bold label):

    $b->add_stamp(
        text         => 'APPROVED',
        bg_colour    => '#dcfce7',
        colour       => '#16a34a',
        size         => 24,
        x            => 72,
        w            => 200,
        h            => 50,
    );

Annotation stamp (PDF viewer rubber-stamp annotation):

    $b->add_stamp(
        rect => [400, 700, 550, 750],
        type => 'Approved',      # Draft, Approved, Confidential, Final, etc.
    );

When C<text> is supplied the method draws a coloured rectangle with centred
bold text on the current page. Provide C<y> to place it at an absolute
coordinate, or omit C<y> to use cursor-relative placement (the cursor
advances past the stamp automatically).

Visual stamp options:

=over 4

=item C<text> (Str, required) - The label to display

=item C<x> (Num, default 72) - Left edge

=item C<y> (Num) - Bottom edge; omit to use cursor position

=item C<w> (Num, default 200) - Width

=item C<h> (Num, default 50) - Height

=item C<bg_colour> / C<fill_colour> (Str, default '#e5e7eb') - Background fill

=item C<colour> (Str, default '#111827') - Text and border colour

=item C<size> (Num, default 20) - Font size

=item C<border> (Num, default 0) - Border width; 0 means no border

=item C<border_colour> (Str) - Border colour; defaults to C<colour>

=back

Annotation stamp types: Draft, Approved, Experimental, NotApproved,
AsIs, Expired, NotForPublicRelease, Confidential, Final, Sold, Departmental,
ForLegalReview.

=head2 Bates Numbering

=head3 add_bates(%args)

    $b->add_bates(
        prefix => 'ACME',
        start  => 1,
        digits => 6,
        suffix => '-2026',
        position => 'bottom_right',
    );

Apply Bates numbering to all pages. See L<PDF::Make::Watermark> for full
options.

=head2 Custom Metadata

=head3 set_meta($key, $value)

    $b->set_meta('Department', 'Engineering');

Set a custom metadata key in the PDF Info dictionary.

=head3 get_meta($key)

    my $val = $b->get_meta('Department');

Get a custom metadata value.

=head2 Page Info

=head3 page_count()

    my $n = $b->page_count;

Returns the number of pages in the document.

=head2 Text Extraction

=head3 extract_text($file, $page_index)

    my $text = $b->extract_text('existing.pdf', 0);

Extract text from page C<$page_index> (default 0) of an existing PDF file.

=head2 Opening Existing PDFs

=head3 open_existing($file, %args)

    my $b = PDF::Make::Builder->open_existing('input.pdf',
        file_name => 'output.pdf',
    );
    $b->add_page->add_text(text => 'New page appended');
    $b->save;

Class method. Parses an existing PDF and creates a Builder with pages
matching the original dimensions. New content can then be added and saved.

=head2 Output

=head3 to_bytes()

    my $pdf_data = $b->to_bytes;

Finalise and return the PDF as a byte string (instead of writing to file).
Useful for serving PDFs over HTTP or embedding in other formats.

=head2 Lifecycle

=head3 save()

    $b->save;

Finalise all pages, apply encryption/signatures, render headers/footers
and TOC, then write the PDF to C<file_name>.

=head3 onsave($key, $method, %args)

Register a callback to run during save.

=head1 PAGE SIZES

Supported named sizes for C<add_page(page_size =E<gt> ...)>:

    A3        842 x 1191 pt
    A4        595 x 842  pt
    A5        420 x 595  pt
    B5        499 x 709  pt
    Letter    612 x 792  pt
    Legal     612 x 1008 pt
    Tabloid   792 x 1224 pt

=head1 SEE ALSO

L<PDF::Make> for the distribution overview.

L<PDF::Make::Document>, L<PDF::Make::Canvas> for the low-level API.

L<PDF::Make::Builder::Text>, L<PDF::Make::Builder::Font>,
L<PDF::Make::Builder::Page>, L<PDF::Make::Builder::Image>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
