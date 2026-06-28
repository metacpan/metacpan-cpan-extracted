package PDF::Make::Builder::Page;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Page',
        'page_size:Str:default(A4)',
        'background:Str:default(#fff)',
        'columns:Int:default(1)',
        'column:Int:default(1)',
        'column_y:Num:default(0)',
        'is_rotated:Bool:default(0)',
        'header:Any',
        'footer:Any',
        'padding:Num:default(20)',
        'num:Int:required',
        'x:Num:default(0)',
        'y:Num:default(0)',
        'w:Num:required',
        'h:Num:required',
        'canvas:Any:required',
        'xs_page:Any:required',
        'imported:Bool:default(0)',
        'redactions:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Page', 'page_');
}

my %PAGE_SIZES = (
    A4      => [595, 842],
    Letter  => [612, 792],
    Legal   => [612, 1008],
    A3      => [842, 1191],
    A5      => [420, 595],
    B5      => [499, 709],
    Tabloid => [792, 1224],
);

sub page_dimensions {
    my ($class_or_size) = @_;
    my $size = ref $class_or_size ? $class_or_size->page_size : $class_or_size;
    return @{$PAGE_SIZES{$size} // $PAGE_SIZES{A4}};
}

sub top_y {
    my ($self) = @_;
    my $ph = page_h $self;
    my $pad = page_padding $self;
    my $hdr = page_header $self;
    my $top = $ph - $pad;
    $top -= $hdr->h if $hdr;
    return $top;
}

sub bottom_y {
    my ($self) = @_;
    my $pad = page_padding $self;
    my $ftr = page_footer $self;
    my $bot = $pad;
    $bot += $ftr->h if $ftr;
    return $bot;
}

sub remaining_height {
    my ($self) = @_;
    return $self->cursor_y - $self->bottom_y;
}

sub width {
    my ($self) = @_;
    my $pw = page_w $self;
    my $pad = page_padding $self;
    my $cols = page_columns $self;
    my $usable = $pw - 2 * $pad;
    if ($cols > 1) {
        my $col_gap = 20;
        return ($usable - ($cols - 1) * $col_gap) / $cols;
    }
    return $usable;
}

sub content_x {
    my ($self) = @_;
    my $pad = page_padding $self;
    my $col = page_column $self;
    if ((page_columns $self) > 1) {
        my $col_gap = 20;
        my $col_w = $self->width;
        return $pad + ($col - 1) * ($col_w + $col_gap);
    }
    return $pad;
}

sub cursor_y {
    my ($self) = @_;
    my $cy = page_y $self;
    return $cy > 0 ? $cy : $self->top_y;
}

sub advance_y {
    my ($self, $amount) = @_;
    my $current = $self->cursor_y;
    page_y $self, $current - $amount;
}

sub has_next_column {
    my ($self) = @_;
    return (page_column $self) < (page_columns $self);
}

sub next_column {
    my ($self) = @_;
    my $col = page_column $self;
    my $cols = page_columns $self;
    return 0 if $col >= $cols;

    # Save cursor for the column we're leaving (for balanced columns)
    if ($col == 1) {
        page_column_y $self, $self->cursor_y;
    }

    page_column $self, $col + 1;
    # Reset cursor to top of content area for the new column
    page_y $self, $self->top_y;
    return 1;
}

sub reset_columns {
    my ($self) = @_;
    page_column $self, 1;
    page_column_y $self, 0;
    page_y $self, $self->top_y;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Page - Page state and layout for PDF::Make

=head1 SYNOPSIS

    use PDF::Make::Builder;

    my $builder = PDF::Make::Builder->new(
        page_size => 'A4',
        padding   => 20,
        header    => { show_page_num => 'right' },
        footer    => { show_page_num => 'left' },
    );

    my $page = $builder->page;
    my $y    = $page->cursor_y;
    my $w    = $page->width;

=head1 DESCRIPTION

Represents a single page in the PDF document, tracking cursor position, layout
dimensions, column state, and optional header/footer regions.

=head1 NOTE

Accessors use the C<page_> prefix (e.g. C<< $page->page_w >>,
C<< $page->page_h >>) because bare names like C<w> and C<h> conflict with
Perl builtins.

=head1 PROPERTIES

=over 4

=item B<page_size> (Str, default C<'A4'>)

Named page size.  Supported: A3, A4, A5, B5, Letter, Legal, Tabloid.

=item B<background> (Str, default C<'#fff'>)

Background colour as a hex string.

=item B<columns> (Int, default 1)

Number of text columns.

=item B<column> (Int, default 1)

Current active column (1-based).

=item B<padding> (Num, default 20)

Page margin in points.

=item B<num> (Int, required)

1-based page number.

=item B<w> (Num, required)

Page width in points.

=item B<h> (Num, required)

Page height in points.

=item B<canvas> (Any, required)

The low-level canvas object used to emit PDF drawing operators.

=item B<xs_page> (Any, required)

The XS page handle from L<PDF::Make>.

=item B<header> (Any)

Optional L<PDF::Make::Builder::Page::Header> instance.

=item B<footer> (Any)

Optional L<PDF::Make::Builder::Page::Footer> instance.

=back

=head1 METHODS

=over 4

=item B<page_dimensions($size)>

Class method.  Returns C<(width, height)> in points for the given page-size
name (e.g. C<'A4'>).

=item B<top_y()>

Returns the Y coordinate of the top of the content area (below header, inside
padding).

=item B<bottom_y()>

Returns the Y coordinate of the bottom of the content area (above footer,
inside padding).

=item B<remaining_height()>

Returns the vertical space remaining between the cursor and the bottom of the
content area.

=item B<width()>

Returns the usable content width, accounting for padding and columns.

=item B<content_x()>

Returns the X coordinate of the left edge of the current column.

=item B<cursor_y()>

Returns the current vertical cursor position, defaulting to C<top_y> if no
content has been placed yet.

=item B<advance_y($dy)>

Moves the cursor down by C<$dy> points.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Page::Header>,
L<PDF::Make::Builder::Page::Footer>

=cut
