package PDF::Make::Builder::Form::Field;
use strict;
use warnings;
use Object::Proto;
use PDF::Make ();

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Form::Field',
        'field_name:Str:required',
        'x:Num',
        'y:Num',
        'w:Num:default(200)',
        'h:Num:default(24)',
        'default_value:Str',
        'da:Str',
        'label:Str',
        'label_colour:Str:default(#444)',
        'label_size:Num:default(9)',
        'font_size:Num:default(10)',
        'font_name:Str:default(Helv)',
        'border_colour:Str:default(#aaa)',
        'bg_colour:Str:default(#fff)',
        'readonly:Bool:default(0)',
        'required:Bool:default(0)',
        'inline_label:Bool:default(0)',
        'raw_mode:Bool:default(0)',
        'margin_top:Num:default(4)',
        'margin_bottom:Num:default(8)',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Form::Field');
}

sub _ensure_form {
    my ($doc) = @_;
    my $form = eval { PDF::Make::FormPtr::get($doc) };
    unless ($form) {
        $form = PDF::Make::FormPtr::create($doc);
        PDF::Make::FormPtr::set_need_appearances($form, 1);
    }
    return $form;
}

sub _create_field {
    die "PDF::Make::Builder::Form::Field::_create_field must be overridden";
}

sub add {
    my ($self, $builder) = @_;
    my $page = $builder->page;
    my $canvas = $page->canvas;
    my $doc = $builder->doc;
    my $bfont = $builder->font;

    _ensure_form($doc);

    my $fx = $self->x // $page->content_x;
    my $fw = $self->w;
    my $fh = $self->h;
    my $name = field_name $self;
    my $is_inline = inline_label $self;
    my $lbl = $self->label;

    # ── Raw mode: create/place widget without layout/chrome/cursor changes ──
    if ($self->raw_mode) {
        my $fy = defined($self->y) ? $self->y : ($page->cursor_y - $fh);
        my $field = $self->_create_field($doc, $name, $fx, $fy, $fw, $fh);
        $self->_apply_field_props($field);
        $field->add_to_page($page->xs_page);
        return $self;
    }

    # Top margin
    $page->advance_y(margin_top $self);

    if ($is_inline) {
        # ── Inline layout (checkbox/radio): field then label beside it ──

        my $fy = $page->cursor_y - $fh;

        # Draw label to the right of the field
        if (defined $lbl && length $lbl) {
            my $lsize = label_size $self;
            my ($lr, $lg, $lb) = $bfont->hex_to_rgb(label_colour $self);
            $bfont->ensure_loaded($page->xs_page);
            my $res = $bfont->resource_name;
            $canvas->BT
                ->Tf($res, $lsize)
                ->rg($lr, $lg, $lb)
                ->Td($fx + $fw + 8, $fy + ($fh - $lsize) / 2 + 1)
                ->Tj($lbl)
                ->ET;
        }

        # Create XS field
        my $field = $self->_create_field($doc, $name, $fx, $fy, $fw, $fh);
        $self->_apply_field_props($field);
        $field->add_to_page($page->xs_page);

        # Draw styled border (unless subclass handles its own appearance)
        $self->_draw_field_chrome($canvas, $bfont, $fx, $fy, $fw, $fh)
            unless $self->_draws_own_chrome;

        # Advance past the field
        $page->advance_y($fh + margin_bottom $self);

    } else {
        # ── Stacked layout (text/combo/list): label above, field below ──

        # Draw label first
        if (defined $lbl && length $lbl) {
            my $lsize = label_size $self;
            my ($lr, $lg, $lb) = $bfont->hex_to_rgb(label_colour $self);
            $bfont->ensure_loaded($page->xs_page);
            my $res = $bfont->resource_name;
            my $req_marker = ($self->required) ? ' *' : '';
            my $label_y = $page->cursor_y - $lsize;
            $canvas->BT
                ->Tf($res, $lsize)
                ->rg($lr, $lg, $lb)
                ->Td($fx, $label_y)
                ->Tj($lbl . $req_marker)
                ->ET;
            $page->advance_y($lsize + 3);
        }

        # Field goes at current cursor
        my $fy = $page->cursor_y - $fh;

        # Create XS field
        my $field = $self->_create_field($doc, $name, $fx, $fy, $fw, $fh);
        $self->_apply_field_props($field);
        $field->add_to_page($page->xs_page);

        # Draw styled border (unless subclass handles its own appearance)
        $self->_draw_field_chrome($canvas, $bfont, $fx, $fy, $fw, $fh)
            unless $self->_draws_own_chrome;

        # Advance past the field
        $page->advance_y($fh + margin_bottom $self);
    }

    return $self;
}

sub _apply_field_props {
    my ($self, $field) = @_;
    my $da = $self->da;
    $da = sprintf('/%s %g Tf 0 g', $self->font_name, $self->font_size)
        unless defined $da && length $da;
    $field->set_da($da);
    my $dv = default_value $self;
    $field->set_value($dv) if defined $dv;
    $field->readonly if $self->readonly;
    $field->required if $self->required;
}

sub _draws_own_chrome { 0 }

sub _draw_field_chrome {
    my ($self, $canvas, $bfont, $fx, $fy, $fw, $fh) = @_;
    my ($bgr, $bgg, $bgb) = $bfont->hex_to_rgb(bg_colour $self);
    my ($bdr, $bdg, $bdb) = $bfont->hex_to_rgb(border_colour $self);

    $canvas->q;
    # White fill
    $canvas->rg($bgr, $bgg, $bgb)
           ->re($fx, $fy, $fw, $fh)->f;
    # Border stroke
    $canvas->w(0.75)
           ->RG($bdr, $bdg, $bdb)
           ->re($fx + 0.25, $fy + 0.25, $fw - 0.5, $fh - 0.5)->S;
    $canvas->Q;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Form::Field - Base class for form field components

=head1 DESCRIPTION

Base class for all Builder form field types. Provides shared layout logic
(label rendering, cursor management, styled borders) and delegates field
creation to subclasses via C<_create_field>.

Do not use this class directly. Use the specific field type classes:

=over 4

=item L<PDF::Make::Builder::Form::Field::Text>

=item L<PDF::Make::Builder::Form::Field::Checkbox>

=item L<PDF::Make::Builder::Form::Field::Radio>

=item L<PDF::Make::Builder::Form::Field::Combo>

=item L<PDF::Make::Builder::Form::Field::Listbox>

=item L<PDF::Make::Builder::Form::Field::Button>

=back

Or use C<< $builder->add_field(type => '...', name => '...', ...) >> which
dispatches to the correct subclass automatically.

=head1 SHARED PROPERTIES

=over 4

=item C<field_name> (Str, required) - PDF field name (unique within the form)

=item C<x> (Num) - Left edge X coordinate (defaults to page content area)

=item C<y> (Num) - Bottom Y coordinate (used by raw mode)

=item C<w> (Num, default 200) - Field width in points

=item C<h> (Num, default 24) - Field height in points

=item C<label> (Str) - Label text drawn above (or beside) the field

=item C<label_colour> (Str, default '#444') - Label text colour

=item C<label_size> (Num, default 9) - Label font size

=item C<default_value> (Str) - Initial field value

=item C<da> (Str) - Raw PDF default appearance string (overrides font_name/font_size)

=item C<font_size> (Num, default 10) - Font size for field text

=item C<font_name> (Str, default 'Helv') - PDF font resource name

=item C<border_colour> (Str, default '#aaa') - Field border colour

=item C<bg_colour> (Str, default '#fff') - Field background colour

=item C<readonly> (Bool, default 0) - Make field read-only

=item C<required> (Bool, default 0) - Mark field as required (appends * to label)

=item C<inline_label> (Bool, default 0) - Place label beside the field instead of above

=item C<raw_mode> (Bool, default 0) - Skip builder layout/chrome; place widget directly at x/y/w/h

=item C<margin_top> (Num, default 4) - Space above the field in points

=item C<margin_bottom> (Num, default 8) - Space below the field in points

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Form>, L<PDF::Make::Field>

=cut
