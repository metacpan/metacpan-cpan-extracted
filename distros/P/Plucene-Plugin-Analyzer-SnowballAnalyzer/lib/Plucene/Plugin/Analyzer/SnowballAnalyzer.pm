package Plucene::Plugin::Analyzer::SnowballAnalyzer;

use base 'Plucene::Analysis::Analyzer';
use 5.006;
use strict;
use warnings;
our $VERSION = '1.1';
use Plucene::Analysis::Standard::StandardTokenizer;
use Plucene::Plugin::Analyzer::SnowballFilter;
use Plucene::Analysis::StopFilter;
use Lingua::StopWords;

our $LANG = 'en';

=head1 NAME 

Plucene::Plugin::Analyzer::SnowballAnalyzer - Stemmed analyzer with Lingua::Stem::Snowball and Lingua::StopWords

=head1 DESCRIPTION

Filters StandardTokenizer with SnowballAnalyzer.

Change $Plucene::Plugin::Analysis::SnowballAnalyzer::LANG to the language of your choice.
(see Lingua::Stem::Snowball documentation for all available languages).

=head1 EXAMPLE

  #!/usr/bin/perl
  
  use strict;
  use Plucene;
  use Plucene::Index::Writer;
  use Plucene::Plugin::Analyzer::SnowballAnalyzer;
  use Plucene::Search::IndexSearcher;
  use Plucene::QueryParser;
  
  $Plucene::Plugin::Analyzer::SnowballAnalyzer::LANG = 'fr';
  
  my $db = "plucene_index";
  
  my $writer = Plucene::Index::Writer->new($db, Plucene::Plugin::Analyzer::SnowballAnalyzer->new(), 1);
  
  $doc = Plucene::Document->new();
  $doc->add(Plucene::Document::Field->Keyword(filename => 'test2.html'));
  $doc->add(Plucene::Document::Field->Text(title => 'Another file title'));
  $doc->add(Plucene::Document::Field->UnStored(content => 'Nothing HERE. la folie...'));
  $writer->add_document($doc);
  
  $doc = Plucene::Document->new();
  $doc->add(Plucene::Document::Field->Keyword(filename => 'test2.html'));
  $doc->add(Plucene::Document::Field->Text(title => 'Fichier en français'));
  $doc->add(Plucene::Document::Field->UnStored(content => 'Vive le français! Je t\'aime tendrement...'));
  $writer->add_document($doc);
  
  $writer->optimize;
  
  my $searcher = Plucene::Search::IndexSearcher->new($db);
  my $parser = Plucene::QueryParser->new({
  	analyzer => Plucene::Plugin::Analyzer::SnowballAnalyzer->new(),
  	default => 'content',
  });
  my $parsed = $parser->parse("la +france +TENDRE title:fichier");
  
  my @docs;
  my $hc = Plucene::Search::HitCollector->new(
  	collect => sub {
  		my ($self, $doc, $score) = @_;
  		my $res = eval { $searcher->doc($doc); };
  		push @docs, $res if res;
  	},
  );
  
  $searcher->search_hc($parsed, $hc);
  my @results = map {{
  	filename => $_->get('filename')->string,
  	title => $_->get('title')->string,
  }} @docs;
  
  print "Results:\n";
  foreach my $result (@results) {
  	print "\t$result->{title} ($result->{filename})\n";
  }

=cut

sub tokenstream {
	my $self = shift;

	my @stopwords = keys %{ Lingua::StopWords::getStopWords($LANG) };
	return Plucene::Analysis::StopFilter->new({
		input => Plucene::Plugin::Analyzer::SnowballFilter->new({
			input => Plucene::Analysis::Standard::StandardTokenizer->new(@_)
		}),
		stoplist => \@stopwords,
	});
}

=head1 AUTHOR

Fabien POTENCIER, C<fabpot@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Plucene himself.
