package PGXN::API::Searcher;

use 5.10.0;
use utf8;
use File::Spec;
use Lucy::Search::QueryParser;
use Lucy::Search::IndexSearcher;
use Lucy::Highlight::Highlighter;
use Carp;

our $VERSION = v0.10.1;

sub new {
    my ($class, $path) = @_;
    my %parsers;
    for my $iname (qw(docs dists extensions users tags)) {
        my $p = $parsers{$iname} = Lucy::Search::QueryParser->new(
            schema => Lucy::Search::IndexSearcher->new(
                index => File::Spec->catdir($path, '_index', $iname)
            )->get_schema,
        );
        $p->set_heed_colons(1); # XXX Soon to be deprecated.
    }
    bless {
        doc_root => $path,
        parsers  => \%parsers,
    } => $class;
}

sub doc_root { shift->{doc_root} }
sub parsers  { shift->{parsers}  }

my %highlightable = (
    docs       => 'body',
    dists      => 'readme',
    extensions => 'abstract',
    users      => 'details',
    tags       => undef,
);

my %fields = (
    docs       => [qw(title abstract dist version docpath date user user_name)],
    dists      => [qw(dist version abstract date user user_name)],
    extensions => [qw(extension abstract dist version docpath date user user_name)],
    users      => [qw(user name uri)],
    tags       => [qw(tag)],
);

sub search {
    my ($self, %params) = @_;
    my $iname    = $params{in} || 'docs';
    my $query    = $self->{parsers}{$iname}->parse($params{query});
    my $limit    = ($params{limit} ||= 50) < 1024 ? $params{limit} : 50;
    my $searcher = Lucy::Search::IndexSearcher->new(
        index => File::Spec->catdir($self->doc_root, '_index', $iname)
    );

    my $hits = $searcher->hits(
        query      => $query,
        offset     => $params{offset},
        num_wanted => $limit,
    );

    # Arrange for highlighted excerpts to be created.
    my $highlighter;
    if (my $field = $highlightable{$iname}) {
        my $h = Lucy::Highlight::Highlighter->new(
            searcher => $searcher,
            query    => $query,
            field    => $field,
        );
        $highlighter = sub {
            return excerpt => $h->create_excerpt(shift);
        };
    } else {
        $highlighter = sub { };
    }

    my %ret = (
        query  => $params{query},
        offset => $params{offset} || 0,
        limit  => $limit,
        count  => $hits->total_hits,
        hits   => my $res = [],
    );

    # Create result list.
    while ( my $hit = $hits->next ) {
        push @{ $res } => {
            score    => sprintf( "%0.3f", $hit->get_score ),
            $highlighter->($hit),
            map { $_ => $hit->{$_} } @{ $fields{$iname} }
        };
    }

    return \%ret;
}

1;

__END__

=head1 Name

PGXN::API::Searcher - PGXN API full text search interface

=head1 Synopsis

  use PGXN::API::Searcher;
  use JSON;
  my $search = PGXN::API::Searcher->new('/path/to/api/root');
  encode_json $search->search( query => $query, in => 'docs' );

=head1 Description

L<PGXN|http://pgxn.org> is a L<CPAN|http://cpan.org>-inspired network for
distributing extensions for the L<PostgreSQL RDBMS|http://www.postgresql.org>.
All of the infrastructure tools, however, have been designed to be used to
create networks for distributing any kind of release distributions and for
providing a lightweight static file JSON REST API.

This module encapsulates the PGXN API search functionality. The indexes are
created by L<PGXN::API::Indexer>; this module parses search queries, executes
them against the appropriate index, and returns the results as a hash suitable
for serializing to L<JSON|http://json.org/> in response to a request.

To use this module, one must have a path to the API server document root
created by PGXN::API. That is, with access to the same file system. It is
therefore used by PGXN::API itself to process search requests. It will also be
used by WWW::PGXN if its mirror URI is specified as a C<file:> URI.

Chances are, if you want to use the PGXN search API, what you really want to
use is L<WWW::PGXN>. This module simply provides the low-level file system
access to the search databases used by L<PGXN::API> and L<WWW::PGXN> to
provide the search interfaces.

But in case you I<do> want to use this module, here are the gory details.

=head1 Interface

=head2 Constructor

=head3 C<new>

  my $search = PGXN::API::Searcher->new('/path/to/pgxn/api/root');

Constructs a PGXN::API::Searcher object, pointing it to a valid PGXN::API root
directory.

=head2 Accessors

=head3 C<doc_root>

  my $doc_root = $search->doc_root;

Returns the path to the document root passed to C<new()>.

=head3 C<parsers>

  my $doc_parser = $search->parsers->{docs};

Returns a hash reference of search query parsers. The keys are the names of
the indexes, and the values are L<Lucy::Search::QueryParser> objects.

=head2 Instance Method

=head3 C<search>

  my $results = $search->search( in => 'docs', query => $q );

Queries the specified index and returns a hash reference with the results. The
parameters supported in the hash reference second argument are:

=over

=item query

The search query. See L<Lucy::Search::QueryParser> for the supported
syntax of the query. Required.

=item in

The name of the search index in which to run the query. The default is "docs".
The possible values are covered below.

=item offset

How many hits to skip before showing results. Defaults to 0.

=item limit

Maximum number of hits to return. Defaults to 50 and may not be greater than
1024.

=back

The results will be returned as a hash with the following keys:

=over

=item query

The query string. Same value as the C<query> parameter.

=item limit

Maximum number of records returned. Same as the C<limit> parameter unless it
exceeds 1024, in which case it will be the default value, 50.

=item offset

The number of hits skipped.

=item count

The total count of hits, without regard to C<limit> or C<offset>. Use for
laying out pagination links.

=item hits

An array of hash references. These constitute the search results. The keys in
the hashes depend on which index was searched. See below for that information.

=back

The structure of the C<hits> hash reference depends on which index is
specified via the C<index> parameter. The possible values are:

=over

=item docs

Full text indexing of PGXN documentation. The C<hits> hashes will have the
following keys:

=over

=item title

The document title.

=item abstract

The document abstract.

=item excerpt

An excerpt from the document with the search keywords highlighted in C<
<<strong>> > tags.

=item dist

The name of the distribution in which the document is found.

=item version

The version of the distribution in which the document is found.

=item docpath

The path to the document within the distribution.

=item date

The distribution date.

=item user

The nickname of the user who created the distribution.

=item user_name

The full name of the user who created the distribution.

=back

=item dists

Full text search of PGXN distributions. The C<hits> hashes will have the
following keys:

=over

=item name

The name of the distribution.

=item version

The distribution version.

=item excerpt

An excerpt from the distribution with the search keywords highlighted in
C<< <strong> >> tags.

=item abstract

The distribution abstract.

=item date

The distribution date.

=item user

The nickname of the user who created the distribution.

=item user_name

The full name of the user who created the distribution.

=back

=item extensions

Full text search of PGXN extensions. The C<hits> hashes will have the following
keys:

=over

=item name

The name of the extension.

=item excerpt

An excerpt from the extension with the search keywords highlighted in
C<< <strong> >> tags.

=item abstract

The extension abstract.

=item dist

The name of the distribution in which the extension is found.

=item version

The version of the distribution in which the extension is found.

=item docpath

The path to the extension's documentation within the distribution. This is the
same format as used for the "docpath" key in docs results, and as used by the
"htmldoc" URI template.

=item date

The distribution date.

=item user

The nickname of the user who created the distribution.

=item user_name

The full name of the user who created the distribution.

=back

=item users

Full text search of PGXN users. The C<hits> hashes will have the following
keys:

=over

=item user

The user's nickname.

=item name

The user's full name.

=item uri

The user's URI

=item excerpt

An excerpt from the user with the search keywords highlighted in
 C< <<strong>> > tags.

=back

=item tags

Full text search of PGXN tags. The C<hits> hashes will have the following keys:

=over

=item name

The tag name.

=back

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/pgxn-api-searcher/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/pgxn-api-searcher/issues/> or by sending mail to
L<bug-PGXN-API-Searcher@rt.cpan.org|mailto:bug-PGXN-API-Searcher@rt.cpan.org>.

=head1 See Also

=over

=item L<PGXN::Manager>

The heart of any PGXN network, PGXN::Manager manages distribution uploads and
mirror maintenance. You'll want to look at it if you plan to build your own
network.

=item L<WWW::PGXN>

A Perl interface over a PGXN mirror or API. Able to read the mirror or API via
HTTP or from the local file system. Use L<PGXN::API::Searcher> when the
specified API URI maps to the local file system.

=item L<PGXN::Site>

A layer over the PGXN API providing a nicely-formatted Web site for folks to
perform full text searches, read documentation, or browse information about
users, distributions, tags, and extensions.

=item L<PGXN::API>

Creates the full text indexes used by PGXN::API::Searcher>. Also uses
PGXN::API::Searcher to manage C</search> HTTP requests.

=back

=head1 Author

David E. Wheeler <david.wheeler@pgexperts.com>

=head1 Copyright and License

Copyright (c) 2011 David E. Wheeler.

This module is free software; you can redistribute it and/or modify it under
the L<PostgreSQL License|http://www.opensource.org/licenses/postgresql>.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

In no event shall David E. Wheeler be liable to any party for direct,
indirect, special, incidental, or consequential damages, including lost
profits, arising out of the use of this software and its documentation, even
if David E. Wheeler has been advised of the possibility of such damage.

David E. Wheeler specifically disclaims any warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose. The software provided hereunder is on an "as is" basis,
and David E. Wheeler has no obligations to provide maintenance, support,
updates, enhancements, or modifications.

=cut
