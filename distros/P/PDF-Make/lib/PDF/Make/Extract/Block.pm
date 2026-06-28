package PDF::Make::Extract::Block;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Extract::Line;

BEGIN {
    Object::Proto::define('PDF::Make::Extract::Block',
        'x0:Num',
        'y0:Num',
        'x1:Num',
        'y1:Num',
        '_lines:ArrayRef:arg(lines):default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Extract::Block');
}

sub bbox { (x0($_[0]), y0($_[0]), x1($_[0]), y1($_[0])) }

sub lines {
    my ($self) = @_;
    return map { PDF::Make::Extract::Line->new(%$_) } @{_lines($self)};
}

sub line_count { scalar @{_lines($_[0])} }

sub to_string {
    my ($self) = @_;
    return join "\n", map { $_->to_string } $self->lines;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Extract::Block - A block of text lines

=head1 METHODS

=head2 x0, y0, x1, y1

Bounding box coordinates.

=head2 bbox()

Returns C<(x0, y0, x1, y1)> as a list.

=head2 lines()

Returns list of L<PDF::Make::Extract::Line> objects.

=head2 line_count()

Returns the number of lines.

=head2 to_string()

Returns lines joined by newlines.

=head1 SEE ALSO

L<PDF::Make::Extract::Result>, L<PDF::Make::Extract::Line>

=cut
