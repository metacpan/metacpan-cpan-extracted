package PDF::Make::Markup::Parse;
use strict;
use warnings;

our $VERSION = '0.10';

# No logic lives here. The grammar, the entity table, the UTF-8 validation and
# every line and column are in src/pdfmake_markup.c, reached through
# xs/markup.xs. Encoding is decided there too: a character string is encoded,
# UTF-8 bytes are passed through, and neither can silently become mojibake.
require PDF::Make;

1;

__END__

=encoding UTF-8

=head1 SYNOPSIS

    use PDF::Make::Markup::Parse;

    my $root = PDF::Make::Markup::Parse->parse(<<'MARKUP');
    <doc size="A4" margin="36">
      <h1>Invoice 1042</h1>
      <text>Amount due: <b>1,240.00</b> by 30 September.</text>
    </doc>
    MARKUP

=head1 DESCRIPTION

The markup is a closed tag set, not HTML and not XML. Anything outside the
grammar is an error with a position rather than a best guess, because a
document that renders slightly wrong is worse than one that refuses to
render: the wrong one reaches a customer with a number on it.

=head2 Nodes

An element:

    { kind => 'elem', tag => 'row', attrs => { weight => '2' },
      children => [ ... ], line => 4, col => 3 }

Text:

    { kind => 'text', text => 'Amount due: ', line => 5, col => 12 }

=head2 What the grammar allows

=over 4

=item * The root element must be C<< <doc> >>.

=item * Tags come from the fixed set. C<tags()> returns it, with the C<void>,
C<container> and C<inline> flags the parser itself uses.

=item * Attribute values are always quoted, with C<"> or C<'>. A repeated
attribute is an error rather than a silent winner.

=item * Entities are C<&amp;> C<&lt;> C<&gt;> C<&quot;> C<&apos;> and numeric
character references C<&#NNN;> and C<&#xHH;>. There is no wider entity table:
C<&nbsp;> and friends are a slope that ends in an HTML specification.

=item * C<< <!-- comments --> >> are skipped.

=item * Whitespace between the children of a container element is
indentation and is dropped. Inside a text-bearing element it is content and
survives, so C<< Total <b>due</b> >> keeps its space.

=item * Nesting deeper than 64 levels is an error. Templates arrive from
customers, and unbounded depth is a stack overflow waiting for someone else
to find.

=back

=head1 SEE ALSO

L<PDF::Make::Markup::Build>, L<PDF::Make::Builder>

=cut
