package PDF::Make::Extract::Result;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Extract::Block;

BEGIN {
    Object::Proto::define('PDF::Make::Extract::Result',
        'data:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Extract::Result');
}

sub blocks {
    my ($self) = @_;
    return map { PDF::Make::Extract::Block->new(%$_) } @{data($self)};
}

sub block_count { scalar @{data($_[0])} }

sub text_positions {
    my ($self) = @_;
    my @items;
    for my $block ($self->blocks) {
        for my $line ($block->lines) {
            for my $word ($line->words) {
                push @items, {
                    text      => $word->text,
                    x         => $word->x0,
                    y         => $word->y0,
                    w         => $word->x1 - $word->x0,
                    h         => $word->y1 - $word->y0,
                    font_size => $word->font_size,
                    baseline  => $line->baseline,
                    (defined $word->mcid ? (mcid => $word->mcid) : ()),
                    (defined $word->tag  ? (tag  => $word->tag)  : ()),
                };
            }
        }
    }
    return @items;
}

sub words {
    my ($self) = @_;
    my @w;
    for my $block ($self->blocks) {
        for my $line ($block->lines) {
            push @w, $line->words;
        }
    }
    return @w;
}

sub to_string {
    my ($self) = @_;
    return join "\n\n", map { $_->to_string } $self->blocks;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Extract::Result - Structured text extraction result

=head1 SYNOPSIS

    my $result = $builder->extract_structured('doc.pdf', page => 0);

    # Walk the hierarchy
    for my $block ($result->blocks) {
        for my $line ($block->lines) {
            for my $word ($line->words) {
                printf "'%s' at (%.0f, %.0f) size=%.0f\n",
                    $word->text, $word->x0, $word->y0, $word->font_size;
            }
        }
    }

    # Flat list of positioned words
    my @items = $result->text_positions;

    # Plain text
    my $text = $result->to_string;

=head1 METHODS

=head2 blocks()

Returns list of L<PDF::Make::Extract::Block> objects.

=head2 block_count()

Returns the number of blocks.

=head2 text_positions()

Returns a flat list of hashrefs with keys: C<text>, C<x>, C<y>, C<w>, C<h>,
C<font_size>, C<baseline>, plus C<mcid>/C<tag> when the source PDF is tagged.

=head2 words()

Convenience — returns a flat list of all L<PDF::Make::Extract::Word> objects.

=head2 to_string()

Returns plain text (blocks separated by blank lines).

=head1 SEE ALSO

L<PDF::Make::Extract::Block>, L<PDF::Make::Builder>

=cut
