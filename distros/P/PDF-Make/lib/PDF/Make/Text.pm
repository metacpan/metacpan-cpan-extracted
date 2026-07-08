package PDF::Make::Text;

# Back-compat shim — extraction was renamed PDF::Make::Text → PDF::Make::Extract
# in pdfmake 0.02.  This stub forwards calls to the new namespace; remove
# after one release once external code has migrated.

use strict;
use warnings;

our $VERSION = '0.06';

use PDF::Make::Extract;
use PDF::Make::Extract::Result;
use PDF::Make::Extract::Block;
use PDF::Make::Extract::Line;
use PDF::Make::Extract::Word;

our @ISA = ('PDF::Make::Extract');

# Class names changed too; alias the result/block/line/word packages.
{
    no strict 'refs';
    @{'PDF::Make::Text::Result::ISA'} = ('PDF::Make::Extract::Result');
    @{'PDF::Make::Text::Block::ISA'}  = ('PDF::Make::Extract::Block');
    @{'PDF::Make::Text::Line::ISA'}   = ('PDF::Make::Extract::Line');
    @{'PDF::Make::Text::Word::ISA'}   = ('PDF::Make::Extract::Word');
}

1;

__END__

=head1 NAME

PDF::Make::Text - Deprecated alias for L<PDF::Make::Extract>

=head1 DESCRIPTION

The text-extraction stack was renamed C<PDF::Make::Text> →
C<PDF::Make::Extract> when it grew to cover annotations, form fields, and
tables.  This module is a thin back-compat shim that inherits everything
from L<PDF::Make::Extract>.  Update your code:

    -use PDF::Make::Text;
    +use PDF::Make::Extract;

The C<Result>, C<Block>, C<Line>, and C<Word> sub-packages are likewise
renamed; the old names are still C<isa> the new ones for now.

=cut
