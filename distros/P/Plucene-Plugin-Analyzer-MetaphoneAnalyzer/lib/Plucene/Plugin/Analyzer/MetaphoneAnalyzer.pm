package Plucene::Plugin::Analyzer::MetaphoneAnalyzer;

use base 'Plucene::Analysis::Analyzer';
use 5.006;
use strict;
use warnings;
our $VERSION = '1.02';
use Plucene::Analysis::Standard::StandardTokenizer;
use Plucene::Plugin::Analyzer::MetaphoneFilter;

our $LANG = 'en';

=head1 NAME 

Plucene::Plugin::Analyzer::MetaphoneAnalyzer - Metaphone analyzer

=head1 DESCRIPTION

Filters StandardTokenizer with MetaphoneFilter

=head1 EXAMPLE

  #!/usr/bin/perl
  
  use strict;
  use Plucene;
  use Plucene::Index::Writer;
  use Plucene::Plugin::Analyzer::MetaphoneAnalyzer;
  use Plucene::Search::IndexSearcher;
  use Plucene::QueryParser;
  
  my $db = "plucene_index";
  
  my $writer = Plucene::Index::Writer->new($db, Plucene::Plugin::Analyzer::MetaphoneAnalyzer->new(), 1);
  
  $doc = Plucene::Document->new();
  $doc->add(Plucene::Document::Field->Keyword(filename => 'test2.html'));
  $doc->add(Plucene::Document::Field->Text(title => 'Another file title'));
  $doc->add(Plucene::Document::Field->UnStored(content => 'Nothing HERE.'));
  $writer->add_document($doc);
  
  $writer->optimize;
  
  my $searcher = Plucene::Search::IndexSearcher->new($db);
  my $parser = Plucene::QueryParser->new({
  	analyzer => Plucene::Plugin::Analyzer::MetaphoneAnalyzer->new(),
  	default => 'content',
  });
  my $parsed = $parser->parse("nothink");
  
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

		return Plucene::Plugin::Analyzer::MetaphoneFilter->new({
			input => Plucene::Analysis::Standard::StandardTokenizer->new(@_)
		});
}

=head1 AUTHOR

Alan Schwartz C<alansz@uic.edu>

=head1 LICENSE

You may distribute this code under the same terms as Plucene himself.
