package PDF::Make::Extract::Line;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Extract::Word;

BEGIN {
    Object::Proto::define('PDF::Make::Extract::Line',
        'x0:Num',
        'y0:Num',
        'x1:Num',
        'y1:Num',
        'baseline:Num',
        '_words:ArrayRef:arg(words):default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Extract::Line');
}

sub bbox { (x0($_[0]), y0($_[0]), x1($_[0]), y1($_[0])) }

sub words {
    my ($self) = @_;
    return map { PDF::Make::Extract::Word->new(%$_) } @{_words($self)};
}

sub word_count { scalar @{_words($_[0])} }

sub to_string {
    my ($self) = @_;
    return join ' ', map { $_->text } $self->words;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Extract::Line - A line of text words on a common baseline

=head1 METHODS

=head2 x0, y0, x1, y1

Bounding box coordinates.

=head2 bbox()

Returns C<(x0, y0, x1, y1)> as a list.

=head2 baseline()

The Y coordinate of the text baseline.

=head2 words()

Returns list of L<PDF::Make::Extract::Word> objects.

=head2 word_count()

Returns the number of words.

=head2 to_string()

Returns words joined by spaces.

=head1 SEE ALSO

L<PDF::Make::Extract::Block>, L<PDF::Make::Extract::Word>

=cut
