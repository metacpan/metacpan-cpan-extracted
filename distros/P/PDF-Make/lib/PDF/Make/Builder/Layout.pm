package PDF::Make::Builder::Layout;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Layout::Row;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Layout',
        'builder:required',
        'rows:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Layout');
}

sub row {
    my ($self, %args) = @_;
    my $rows = rows $self;
    my %row_args = (
        layout => $self,
        margin => $args{margin} // 5,
        gap    => $args{gap} // 0,
    );
    $row_args{height} = $args{height} if defined $args{height};
    push @$rows, PDF::Make::Builder::Layout::Row->new(%row_args);
    return $rows->[-1];
}

sub render {
    my ($self) = @_;
    my $builder = builder $self;
    my $page = $builder->page;

    for my $row (@{rows $self}) {
        $row->render($builder, $page);
    }

    return $builder;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Layout - Grid-based layout for PDF content

=head1 SYNOPSIS

    use PDF::Make::Builder;
    use PDF::Make::Builder::Layout;

    my $b = PDF::Make::Builder->new(file_name => 'layout.pdf');
    $b->add_page(page_size => 'Letter');

    my $layout = PDF::Make::Builder::Layout->new(builder => $b);

    # Two-column row
    my $row = $layout->row(height => 80);
    $row->cell(weight => 1, bg => '#ecf0f1', border => '#bdc3c7')
        ->text('Left column content here.');
    $row->cell(weight => 1, bg => '#f9f9f9', border => '#bdc3c7')
        ->text('Right column content.');

    # Three-column row with unequal widths
    my $row2 = $layout->row;
    $row2->cell(weight => 1)->text('Narrow');
    $row2->cell(weight => 2)->text('Wide column takes 2/4 of the width');
    $row2->cell(weight => 1, align => 'right')->text('Right-aligned');

    # Full-width row
    my $row3 = $layout->row(height => 40);
    $row3->cell(weight => 1, bg => '#2c3e50', align => 'center')
         ->text('Full width banner', colour => '#fff', size => 16);

    $layout->render;
    $b->save;

=head1 DESCRIPTION

C<PDF::Make::Builder::Layout> provides a grid-based layout system for
positioning content in rows and cells. Each row is divided into weighted
cells that fill the available width proportionally.

Cells support text with word-wrapping, background colours, borders, and
alignment (left, center, right).

=head1 METHODS

=head2 new(builder => $builder)

Create a layout bound to a Builder instance.

=head2 row(%args)

    my $row = $layout->row(height => 60, margin => 10);

Add a row. C<height> is optional (auto-calculated from content). C<margin>
(default 5) is the space below the row.

Returns a Row object.

=head2 render()

Render all rows onto the current page.

=head1 ROW METHODS

=head2 cell(%args)

    $row->cell(
        weight => 2,          # relative width (default 1)
        align  => 'center',   # left, center, right
        bg     => '#ecf0f1',  # background colour
        border => '#bdc3c7',  # border colour
        pad    => 5,          # inner padding (default 5)
    );

Add a cell to the row. Returns a Cell object.

=head1 CELL METHODS

=head2 text($string, %args)

    $cell->text('Hello', size => 14, colour => '#333', line_height => 16);

Add text content to the cell. Supports word-wrapping within the cell width.

=head2 image($path, %args)

    $cell->image('photo.jpg', h => 50);

Add an image to the cell (rendering not yet implemented).

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Layout::Row>,
L<PDF::Make::Builder::Layout::Cell>

=cut
