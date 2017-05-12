package Search::Fulltext;
use strict;
use warnings;
use utf8;

use Carp;

our $VERSION = '1.03';
use Search::Fulltext::SQLite;

sub new {
    my ($class, @args) = @_;
    my %args = ref $args[0] eq 'HASH' ? %{$args[0]} : @args;

    unless ($args{docs}) { croak "'docs' is required for creating new instance of $class" }
    $args{index_file} = ":memory:" unless defined $args{index_file};
    $args{tokenizer}  = "simple"   unless defined $args{tokenizer};
    $args{sqliteh}    = Search::Fulltext::SQLite::->new(
        docs      => $args{docs},
        dbfile    => $args{index_file},
        tokenizer => $args{tokenizer},
    );

    bless {
        %args
    }, $class;
}

sub search {
    my ($self, $query) = @_;
    return [] unless $query;

    my $sqliteh = $self->{sqliteh};
    $sqliteh->search_docids($query);
}

1;
__END__

=encoding utf8

=head1 NAME

Search::Fulltext - Fulltext search module

=head1 SYNOPSIS

    use Search::Fulltext;
    
    my @docs = (
        'I like beer the best',
        'Wine makes people saticefied',  # does not include beer
        'Beer makes people happy',
    );
    
    my $fts = Search::Fulltext->new({
        docs => \@docs,
    });
    my $results = $fts->search('beer');
    is_deeply($results, [0, 2]);         # 1st & 3rd doc include 'beer'
    my $results = $fts->search('beer AND happy');
    is_deeply($results, [2]);            # 3rd doc includes both 'beer' & 'happy'

=head1 DESCRIPTION

L<Search::Fulltext> is a fulltext search module. It can be used in a few steps.

L<Search::Fulltext> has B<pluggable tokenizer> feature, which possibly provides fulltext search for any language.
Currently, B<English> and B<Japanese> fulltext search are officially supported,
although any other languages which have spaces for separating words could be also used.
See L<CUSTOM TOKENIZERS|/CUSTOM_TOKENIZERS> section to learn how to search non-English languages.

B<SQLite>'s B<FTS4> is used as an indexer.
Various queries supported by FTS4 (C<AND>, C<OR>, C<NEAR>, ...) are fully provided.
See L</QUERIES> section for details.

=head1 METHODS

=head2 Search::Fulltext->new

=pod

Creates fulltext index for documents.

=over 4

=item C<@param docs> B<[required]>

Reference to array whose contents are document to be searched.

=item C<@param index_file> B<[optional]>

File path to write fulltext index. By default, on-memory index is used.

=item C<@param tokenizer> B<[optional]>

Tokenizer name to use. C<simple> (default) and C<porter> must be supported.
C<icu> and C<unicode61> could be used if your SQLite libarary used via L<DBD::SQLite> module support them.
See L<http://www.sqlite.org/fts3.html#tokenizer> for more details on FTS4 tokenizers.

Japanese tokenizer C<perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'> is also available after you install
L<Search::Fulltext::Tokenizer::MeCab> module.

See L<CUSTOM TOKENIZERS|/CUSTOM_TOKENIZERS> section for developing other tokenizers.

=back

=cut

=head2 Search::Fulltext->search

Search terms in documents by query language.

=pod

=over 4

=item C<@returns>

Array of indexes of C<docs> passed through C<< Search::Fulltext->new >> in which C<query> is matched.

=item C<@param query>

Query to search from documents.
See L</QUERIES> section for types of queries.

=back

=cut

=head1 QUERIES

The simplest query would be a term.

    my $results = $fts->search('beer');

Other queries below and combination of them can be also used.

    my $results = $fts->search('beer AND happy');
    my $results = $fts->search('saticefied OR happy');
    my $results = $fts->search('people NOT beer');
    my $results = $fts->search('make*');
    my $results = $fts->search('"makes people"');
    my $results = $fts->search('beer NEAR happy');
    my $results = $fts->search('beer NEAR/1 happy');

See L<http://www.sqlite.org/fts3.html#section_3> for an explanation of each type of query.

B<NOTE:> Some custom tokenizers might not support full of these queries above.
Check the document of each tokenizer before using complex queries.

=head1 CUSTOM TOKENIZERS

Custom tokenizers can be implemented by pure perl thanks to L<DBD::SQLite/Perl_tokenizers>.
L<Search::Fulltext::Tokenizer::MeCab> is an example of custom tokenizers.

See L<DBD::SQLite/Perl_tokenizers> and L<Search::Fulltext::Tokenizer::MeCab> module to learn how to develop custom tokenizers.

=head1 SUPPORTS

Bug reports and pull requests are welcome at L<https://github.com/laysakura/Search-Fulltext> !

=head1 VERSION

Version 1.03

=head1 AUTHOR

Sho Nakatani <lay.sakura@gmail.com>, a.k.a. @laysakura
