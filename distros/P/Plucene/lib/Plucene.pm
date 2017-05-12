package Plucene;

=head1 NAME

Plucene - A Perl port of the Lucene search engine

=head1 SYNOPSIS

=head2 Create Documents by adding Fields:

	my $doc = Plucene::Document->new;
	$doc->add(Plucene::Document::Field->Text(content => $content));
	$doc->add(Plucene::Document::Field->Text(author => "Your Name"));

=head2 Choose Your Analyser and add documents to an Index Writer

	my $analyzer = Plucene::Analysis::SimpleAnalyzer->new();
	my $writer = Plucene::Index::Writer->new("my_index", $analyzer, 1);

	$writer->add_document($doc);
	undef $writer; # close

=head3 Search by building a Query

	my $parser = Plucene::QueryParser->new({
		analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
		default  => "text" # Default field for non-specified queries
	});
	my $query = $parser->parse('author:"Your Name"');

=head3 Then pass the Query to an IndexSearcher and collect hits

	my $searcher = Plucene::Search::IndexSearcher->new("my_index");

	my @docs;
	my $hc = Plucene::Search::HitCollector->new(collect => sub {
		my ($self, $doc, $score) = @_;
		push @docs, $searcher->doc($doc);
	});

	$searcher->search_hc($query => $hc);

=head1 DESCRIPTION

Plucene is a fully-featured and highly customizable search engine toolkit
based on the Lucene API. (L<http://jakarta.apache.org/lucene>)

It is not, in and of itself, a functional search engine - you are expected
to subclass and tie all the pieces together to suit your own needs.
The synopsis above gives a rough indication of how to use the engine
in simple cases. See L<Plucene::Simple> for one example of tying it
all together.

The tests shipped with Plucene provide a variety of other examples of
how use this.

=head1 EXTENSIONS

Plucene comes shipped with some default Analyzers. However it is
expected that users will want to create Analyzers to meet their own
needs. To avoid namespace corruption, anyone releasing such Analyzers
to CPAN (which is encouraged!) should place them in the namespace
Plucene::Plugin::Analyzer::.

=head1 DOCUMENTATION

Although most of the Perl modules should be well documented,
the Perl API mirrors Lucene's to such an extent that reading
Lucene's documentation will give you a good idea of how to do more
advanced stuff with Plucene. See particularly the ONJava articles
L<http://www.onjava.com/pub/a/onjava/2003/01/15/lucene.html> and
L<http://www.onjava.com/pub/a/onjava/2003/03/05/lucene.html>. These are
brilliant introductions to the concepts surrounding Lucene, how it works,
and how to extend it.

=head1 COMPATIBILITY

For the most part Lucene and Plucene indexes are created in the same
manner. However, due to current implementation details, the indexes will
generally not be compatible. It should theoretically be possible to
convert index files in either direction between Plucene and Lucene, but
no tools are currently provided to do so.

As Plucene is still undergoing development, we cannot guarantee index
format compatibility across releases. If you're using Plucene in
production code, you need to ensure that you can recreate the indexes.

=head1 MISSING FEATURES

The following features have not yet been fully implemented:

=over 4

=item *

Wildcard searches

=item *

Range searches

=back

=head1 MAILING LIST

Bug reports, patches, queries, discussion etc should be addressed to
the mailing list. More information on the list can be found at:

L<http://www.kasei.com/mailman/listinfo/plucene>

=head1 AUTHORS

Initially ported by Simon Cozens and Marc Kerr.

Currently maintained by Tony Bowden and Marty Pauley.

Original Java Lucene by Doug Cutting and others.

=head1 THANKS

The initial development and ongoing maintenance of Plucene has been
funded and supported by Kasei L<http://www.kasei.com/>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut

use strict;
use warnings;

our $VERSION = "1.25";

1;
