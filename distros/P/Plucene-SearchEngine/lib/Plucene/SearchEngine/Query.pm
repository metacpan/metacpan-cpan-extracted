package Plucene::SearchEngine::Query;
use 5.006;
use strict;
use warnings;
use Carp;
use UNIVERSAL::require;
use Lucene::QueryParser;
use Plucene::Search::IndexSearcher;
use Plucene::Search::HitCollector;
use Plucene::QueryParser;

our $VERSION = '0.01';

=head1 NAME

Plucene::SearchEngine::Query - A higher level abstraction for Plucene

=head1 SYNOPSIS

  use Plucene::SearchEngine::Query;
  my $query = Plucene::SearchEngine::Query->new(
                  dir => "/var/plucene/foo"
              );
  my @docs = $queryer->search("some stuff");
  for my $id (@docs) {
      $snippeter = $query->snippeter( retrieve_text_for_doc($id) );
      print "<H1>Doc $id </H1>\n";
      print "<BLOCKQUOTE>" . $snippeter->as_html . "</BLOCKQUOTE>";
  }

=head1 DESCRIPTION

Plucene is an extremely powerful library for building search engines, but
each time I build a search engine with it, I always find myself doing the
same things. This module provides an abstraction layer around Plucene - 
not quite as abstracted as L<Plucene::Simple>, but more abstracted than
Plucene itself.

=head1 METHODS

=cut

=head2 new 

    Plucene::SearchEngine::Query->new(
        dir         => "/var/plucene/foo",
        analyzer    => "Plucene::Analysis::SimpleAnalyzer",
        default     => "text",
        expand_docs => sub { shift; @_ },
        snippeter   => "Text::Context";
    )

This prepares for searching the index. The only mandatory argument is
C<dir>, which tells Plucene where the index is to be found. The
C<expand_docs> and C<snippeter> arguments are explained below; 
C<analyzer> specifies which Plucene analysis class to use when tokenising
the search terms, and the C<default> argument denotes the default field
for unqualified query terms.

=cut

sub new {
    my ($class, %args) = @_;
    croak("No directory given!") unless $args{dir};
    croak("$args{dir} isn't a directory") unless -d $args{dir};
    my $self = bless { 
        analyzer    => "Plucene::Analysis::SimpleAnalyzer",
        default     => "text",
        expand_docs => \&expand_docs,
        snippeter   => "Text::Context",
        %args 
    }, $class;
    $self->{analyzer}->require
        or die "Couldn't require analyzer: $self->{analyzer}";
    $self->{snippeter}->require
        or die "Couldn't require snippet class: $self->{snippeter}";
    return $self;
}

sub prepare_search {
    my $self = shift;
    $self->{searcher} ||= Plucene::Search::IndexSearcher->new( $self->{dir} );
    $self->{parser}   ||= Plucene::QueryParser->new({
        analyzer => $self->{analyzer}->new,
        default  => $self->{default}
    });
}

=head2 search

    @docs = $queryer->search("foo bar");

Returns a set of documents matching the search query. The default
way of "expanding" these search results is to sort them by score,
and then return the value of the C<id> field from the Plucene index.

Those more familiar with Plucene can have alternative data structures
returned by providing a different C<expand_docs> parameter to the
constructor. For instance, the default doesn't actually B<return> the
score, so if you want to get at it, you can say:

    expand_docs => sub { my ($self, @docs) = @_; return @docs }

This will return a list of array references; the first element in each
array ref will be the C<Plucene::Document> object, and the second will
be the score.

Or, if you're dealing with C<Class::DBI>-derived classes, you might
like to try:

    expand_docs => sub { my ($self, @docs) = @_;
        sort { $b->date <=> $a->date } # Sort by date descending
        map { My::Class->retrieve($_->[0]->get("id")->string) }
        @docs;
    }

The choice is yours.

=cut

sub search {
    my ($self, $query) = @_;
    $self->{orig_query} = $query;
    $self->prepare_search;
    $self->{query} = $self->{parser}->parse($query);

    my @docs;
    my $searcher = $self->{searcher};
    my $hc       = Plucene::Search::HitCollector->new(
        collect => sub {
            my ($self, $doc, $score) = @_;
            my $res = eval { $searcher->doc($doc) };
            die $@ if $@;
            push @docs, [$res, $score] if $res;
       });
   $self->{searcher}->search_hc($self->{query}, $hc);
   return $self->{expand_docs}->($self, @docs);
}

sub expand_docs {
    my ($self, @docs) = @_;
    map $_->[0]->get("id")->string, sort { $b->[1] <=> $a->[1] } @docs;
}

sub _unlucene {
    my ($self, $ast) = @_;
    return map {
        $_->{query} eq "SUBQUERY" ? $self->_unlucene($_->{subquery}) : 
        $_->{query} ne "PHRASE"   ? $_->{term} : 
        (split /\s+/, $_->{term})    
    } grep { 
        $_->{type} ne "PROHIBITED" and 
        (!exists($_->{field}) or $_->{field} eq $self->{default})
    } @{$ast};
}

=head2 snippeter

    $self->snippeter($doc_text)

Given the searchable text of a document, returns a snippeter class
(C<Text::Context>, C<Text::Context::Porter>, etc.) object primed with
the positive parts of the query.

When you call the rendering method (say, C<as_html>) on this object,
you'll get the text snippet highlighting where the search terms appear
in the document.

=cut

sub snippeter {
    my ($self, $body) = @_;
    croak "It doesn't look like you've actually done a search yet"
        unless $self->{orig_query};
    # We can't actually use the original parser, because it may have
    # tokenized us funny. (Porter stemming, etc.)
    my @terms = $self->_unlucene(parse_query($self->{orig_query}));
    $self->{snippeter}->new($body, @terms);
}

1;

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<Plucene::SearchEngine::Index>, L<Plucene>, L<Plucene::Simple>.

=cut
