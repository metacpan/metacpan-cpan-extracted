package PDF::Make::Extract;

use strict;
use warnings;

our $VERSION = '0.05';

use PDF::Make ();
use PDF::Make::Reader;

sub extract {
    my ($class, $parser, $page_index) = @_;
    $page_index //= 0;

    $parser->parse;
    my $reader = PDF::Make::Reader->new($parser);

    return $class->_extract_from_reader($reader, $page_index);
}

1;

__END__

=head1 NAME

PDF::Make::Extract - Extract text, annotations, forms, and tables from PDF pages

=head1 SYNOPSIS

    use PDF::Make::Parser;
    use PDF::Make::Extract;

    my $parser = PDF::Make::Parser->from_file('document.pdf');
    my $text = PDF::Make::Extract->extract($parser, 0);
    print $text;

=head1 METHODS

=head2 extract($parser, $page_index)

Extract plain text from a page. Returns a UTF-8 string.  For structured
extraction (words with coordinates, annotations, tables) prefer the
higher-level C<extract_structured>, C<extract_annotations>, and
C<detect_tables> methods on L<PDF::Make::Builder>.

=head1 SEE ALSO

L<PDF::Make::Extract::Result>, L<PDF::Make::Builder>

=cut
