package Search::OpenSearch::Engine;
use Moose;
use Types::Standard
    qw( Str Num Int ArrayRef HashRef InstanceOf Maybe Object Bool );
use Carp;
use Scalar::Util qw( blessed );
use Search::OpenSearch::Types qw( SOSFacets );
use Search::OpenSearch::Facets;
use Search::OpenSearch::Response::XML;
use Search::OpenSearch::Response::JSON;
use Search::OpenSearch::Response::ExtJS;
use Search::OpenSearch::Response::Tiny;
use Search::Tools::XML;
use Search::Tools::UTF8;
use Search::Tools;
use CHI;
use Time::HiRes qw( time );
use Data::Dump qw( dump );
use JSON;

use namespace::autoclean;

has 'index' => ( is => 'rw', isa => ArrayRef, );
has 'facets' => (
    is     => 'rw',
    isa    => Maybe [SOSFacets],
    coerce => 1,
);
has 'fields' => ( is => 'rw', isa => Maybe [ArrayRef], );
has 'link' => ( is => 'rw', isa => Str, builder => 'init_link' );
has 'cache' => (
    is      => 'rw',
    isa     => Maybe [Object],
    builder => 'init_cache',
    lazy    => 1,
);
has 'cache_ttl' => ( is => 'rw', isa => Int,  builder => 'init_cache_ttl' );
has 'cache_ok'  => ( is => 'rw', isa => Bool, builder => 'init_cache_ok' );
has 'do_not_hilite' =>
    ( is => 'rw', isa => HashRef, lazy => 1, default => sub { {} } );
has 'searcher' => (
    is      => 'rw',
    isa     => Maybe [Object],
    lazy    => 1,
    builder => 'init_searcher'
);
has 'indexer' => (
    is      => 'rw',
    isa     => Maybe [Object],
    lazy    => 1,
    builder => 'init_indexer'
);
has 'suggester' => (
    is      => 'rw',
    isa     => Maybe [Object],
    lazy    => 1,
    builder => 'init_suggester',
);
has 'snipper_config' => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'init_snipper_config'
);
has 'hiliter_config' => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'init_hiliter_config'
);
has 'parser_config' => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'init_parser_config'
);
has 'indexer_config' => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'init_indexer_config'
);
has 'searcher_config' => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'init_searcher_config'
);
has 'suggester_config' => (
    is      => 'rw',
    isa     => HashRef,
    builder => 'init_suggester_config'
);
has 'logger' => (
    is      => 'rw',
    isa     => Maybe [Object],
    lazy    => 1,
    builder => 'init_logger'
);
has 'debug' =>
    ( is => 'rw', isa => Bool, default => sub { $ENV{SOS_DEBUG} || 0 } );
has 'error' => ( is => 'rw', isa => Maybe [Str], );
has 'array_field_values' => ( is => 'rw', isa => Bool, default => sub {1} );
has 'response_version' => ( is => 'rw', isa => Str, builder => 'version' );
has 'default_response_format' => (
    is      => 'rw',
    isa     => Maybe [Str],
    builder => 'init_default_response_format',
);
has 'cache_key_seed' =>
    ( is => 'rw', isa => Maybe [Str], builder => 'init_cache_key_seed' );

our $VERSION = '0.409';

sub BUILD {
    my $self = shift;
    return $self;
}

sub version {
    my $self = shift;
    my $class = ref $self ? ref($self) : $self;
    no strict 'refs';
    return ${"${class}::VERSION"};
}

sub init_cache_ttl { 60 * 60 }
sub init_cache_ok  {1}

sub init_cache {
    my $self = shift;
    return unless $self->cache_ok;
    return CHI->new(
        driver           => 'File',
        dir_create_mode  => 0770,
        file_create_mode => 0660,
        root_dir         => "/tmp/opensearch_cache",
    );
}

sub init_snipper_config {
    return { as_sentences => 1, strip_markup => 1 };
}

sub init_hiliter_config {
    return { class => 'h', tag => 'b' };
}

sub init_parser_config {
    return {};
}

sub init_indexer_config {
    return {};
}

sub init_searcher_config {
    return {};
}

sub init_suggester_config {
    return {};
}

sub init_link     {''}
sub init_searcher { confess "$_[0] does not implement init_searcher()" }
sub init_indexer  { confess "$_[0] does not implement init_indexer()" }
sub type          { confess "$_[0] does not implement type()" }
sub has_rest_api  {0}

sub get_allowed_http_methods {
    confess "$_[0] does not implement get_allowed_http_methods";
}
sub init_default_response_format {'XML'}
sub init_cache_key_seed          {'search-opensearch-engine'}

sub search {
    my $self  = shift;
    my %args  = @_;
    my $query = $args{'q'};
    confess "query required" unless defined $query;
    my $start_time   = time();
    my $offset       = $args{'o'} || 0;
    my $sort_by      = $args{'s'} || 'score DESC';
    my $page_size    = $args{'p'} || 25;
    my $apply_hilite = $args{'h'};
    $apply_hilite = 1 unless defined $apply_hilite;
    my $count_only = $args{'c'} || 0;
    my $limits     = $args{'L'} || [];
    my $boolop     = $args{'b'} || 'AND';
    my $include_results = $args{'r'};
    $include_results = 1 unless defined $include_results;
    my $include_facets = $args{'f'};
    $include_facets = 1 unless defined $include_facets;
    my $response_fields = $args{'x'} || $self->fields;

    if ( $self->debug and $self->logger ) {
        $self->logger->log( dump( \%args ) );
    }

    my $format
        = $args{'t'}
        || $args{'format'}
        || $self->default_response_format;

    # backwards compat
    if ( $format eq 'xml' or $format eq 'json' ) {
        $format = uc($format);
    }

    my $response_class = $args{response_class}
        || 'Search::OpenSearch::Response::' . $format;

    if ( !ref($limits) ) {
        $limits = [ split( m/,/, $limits ) ];
    }
    my @limits;
    for my $limit (@$limits) {
        my ( $field, $low, $high ) = split( m/\|/, $limit );
        my $range = $self->set_limit(
            field => $field,
            lower => $low,
            upper => $high,
        );
        push @limits, $range;
    }
    my $searcher = $self->searcher or croak "searcher not defined";
    my $results = $searcher->search(
        to_utf8("$query"),
        {   start          => $offset,
            max            => $page_size,
            order          => $sort_by,
            limit          => \@limits,
            default_boolop => $boolop,
        }
    );
    my $search_time = sprintf( "%0.5f", time() - $start_time );
    my $start_build = time();
    my $res_query   = $results->query;
    my $query_tree  = $res_query->tree;
    if ( $self->debug and $self->logger ) {
        $self->logger->log( dump $query_tree );
    }
    my $response = $response_class->new(
        debug        => $self->debug,
        total        => $results->hits,
        json_query   => to_json($query_tree),
        parsed_query => $res_query->stringify,
        query        => to_utf8($query),
        search_time  => $search_time,
        link         => ( $args{'u'} || $args{'link'} || $self->link ),
        version => ( $self->response_version || $self->version ),
        engine    => blessed($self) . ' ' . $self->version(),
        sort_info => $sort_by,
    );
    if ( $self->suggester ) {
        $response->suggestions( $self->suggester->suggest("$query") );
    }
    if ( $self->debug and $self->logger ) {
        $self->logger->log(
            "include_results=$include_results include_facets=$include_facets count_only=$count_only"
        );
        $self->logger->log( "response_fields=" . dump($response_fields) );
    }

    if ( $include_results && !$count_only ) {
        $response->fields($response_fields);
        $response->offset($offset);
        $response->page_size($page_size);
        $response->results(
            $self->build_results(
                fields       => $response_fields,
                results      => $results,
                page_size    => $page_size,
                apply_hilite => $apply_hilite,
                query        => $query,
                args         => \%args,             # original args
            )
        );
    }
    if ( $include_facets && !$count_only ) {
        $response->facets(
            $self->get_facets( to_utf8($query), $results, \%args ) );
    }
    my $build_time = sprintf( "%0.5f", time() - $start_build );
    $response->build_time($build_time);
    return $response;
}

sub set_limit {
    my $self  = shift;
    my %args  = @_;
    my @range = ( $args{field}, $args{lower}, $args{upper} );
    return \@range;
}

sub get_facets_cache_key {
    my $self = shift;
    my ( $query, $args ) = @_;
    return sprintf( "%s.%s.%s", $self->cache_key_seed(), ref($self), $query );
}

sub get_facets {
    my $self      = shift;
    my $query     = shift;
    my $results   = shift;
    my $cache_key = $self->get_facets_cache_key( $query, @_ );
    my $cache     = $self->cache or return;

    my $facets;
    if ( $cache->get($cache_key) ) {
        if ( $self->debug and $self->logger ) {
            $self->logger->log("get facets for '$cache_key' from cache");
        }
        $facets = $cache->get($cache_key);
    }
    else {
        if ( $self->debug and $self->logger ) {
            $self->logger->log("build facets for '$cache_key'");
        }
        $facets = $self->build_facets( $query, $results, @_ );
        $cache->set( $cache_key, $facets, $self->cache_ttl );
    }
    return $facets;
}

sub build_facets {
    croak ref(shift) . " must implement build_facets()";
}

sub build_results {
    my $self      = shift;
    my %args      = @_;
    my $fields    = $args{fields} || $self->fields || [];
    my $results   = $args{results} or croak "no results defined";
    my $page_size = $args{page_size} || 25;
    my $q         = $args{query};
    confess "query required" unless defined $q;
    my @results;
    my $count          = 0;
    my %snipper_config = %{ $self->snipper_config };
    my %hiliter_config = %{ $self->hiliter_config };
    my %parser_config  = %{ $self->parser_config };
    my $XMLer          = Search::Tools::XML->new;
    my $query          = Search::Tools->parser(%parser_config)->parse($q);
    my $snipper = Search::Tools->snipper( query => $query, %snipper_config );
    my $hiliter = Search::Tools->hiliter( query => $query, %hiliter_config );

    while ( my $result = $results->next ) {
        push @results,
            $self->process_result(
            result       => $result,
            hiliter      => $hiliter,
            snipper      => $snipper,
            XMLer        => $XMLer,
            fields       => $fields,
            apply_hilite => $args{apply_hilite},
            args         => \%args,
            );
        last if ++$count >= $page_size;
    }
    return \@results;
}

sub process_result {
    my ( $self, %args ) = @_;
    my $result       = $args{result};
    my $hiliter      = $args{hiliter};
    my $XMLer        = $args{XMLer};
    my $snipper      = $args{snipper};
    my $fields       = $args{fields};
    my $apply_hilite = $args{apply_hilite};

    my $title = $XMLer->escape( $result->title || '' );

    # escape the summary *after* we snip it
    my $summary = $result->summary || '';

    # \003 is the record-delimiter in Swish3
    # the default behaviour is just to ignore it
    # and replace with a single space, but a subclass (like JSON)
    # might want to split on it to get an array of values
    $title =~ s/\003/ /g;
    $summary =~ s/\003/ /g;

    my %res = ( score => $result->score, );
    for my $field (@$fields) {
        my $str = $result->get_property($field) || '';

        if ( $self->array_field_values ) {
            if ( !$apply_hilite or $self->no_hiliting($field) ) {
                $res{$field}
                    = [ map { $XMLer->escape($_) } split( m/\003/, $str ) ];
            }
            else {
                $res{$field} = [
                    map {
                        $hiliter->light(
                            $XMLer->escape( $snipper->snip($_) ) )
                        }
                        split( m/\003/, $str )
                ];
            }
        }
        else {
            $str =~ s/\003/ /g;
            if ( !$apply_hilite or $self->no_hiliting($field) ) {
                $res{$field} = $XMLer->escape($str);
            }
            else {
                $res{$field} = $hiliter->light(
                    $XMLer->escape( $snipper->snip($str) ) );
            }
        }
    }

    # set the reserved fields *after* we loop fields,
    # so that the reserved fields are always strings.
    $res{uri}     = $result->uri;
    $res{mtime}   = $result->mtime;
    $res{title}   = ( $apply_hilite ? $hiliter->light($title) : $title );
    $res{summary} = (
          $apply_hilite
        ? $hiliter->light( $XMLer->escape( $snipper->snip($summary) ) )
        : $XMLer->escape($summary)
    );
    return \%res;
}

sub no_hiliting {
    my ( $self, $field ) = @_;
    return $self->{do_not_hilite}->{$field};
}

1;

__END__

=head1 NAME

Search::OpenSearch::Engine - abstract base class

=head1 SYNOPSIS

 use Search::OpenSearch::Engine;
 my $engine = Search::OpenSearch::Engine->new(
    index       => [qw( path/to/index1 path/to/index2 )],
    facets      => {
        names       => [qw( color size flavor )],
        sample_size => 10_000,
    },
    fields      => [qw( color size flavor )],   # result attributes in response
    indexer_config  => {
        somekey => somevalue,
    },
    searcher_config => {
        anotherkey => anothervalue,
    },
    suggester_config => {
        akey => avalue,
    },
    cache_ok        => 1,
    cache           => CHI->new(
        driver           => 'File',
        dir_create_mode  => 0770,
        file_create_mode => 0660,
        root_dir         => "/tmp/opensearch_cache",
    ),
    cache_ttl       => 3600,
    do_not_hilite   => { color => 1 },
    snipper_config  => { as_sentences => 1 },        # see Search::Tools::Snipper
    hiliter_config  => { class => 'h', tag => 'b' }, # see Search::Tools::HiLiter
    parser_config   => {},                           # see Search::Query::Parser
    
 );
 my $response = $engine->search(
    q   => 'quick brown fox',   # query
    s   => 'score desc',        # sort order
    o   => 0,                   # offset
    p   => 25,                  # page size
    h   => 1,                   # highlight query terms in results
    c   => 0,                   # count total only (same as f=0 r=0)
    L   => 'field|low|high',    # limit results to inclusive range
    f   => 1,                   # include facets
    r   => 1,                   # include results
    t   => 'XML',               # or JSON
    u   => 'http://yourdomain.foo/opensearch/',
    b   => 'AND',               # or OR
    x   => [qw( foo bar )],     # return only a subset of fields
 );
 print $response;

=head1 DESCRIPTION

Search::OpenSearch::Engine is an abstract base class. It defines
some sane method behavior based on the L<Dezi::Searcher> API.

=head1 METHODS

This class is a subclass of L<Moose>. Only new or overridden
methods are documented here.

=head2 version

Returns the $VERSION for the Engine.

=head2 BUILD

Sets up the new object.

=head2 init_indexer

Subclasses must implement this method if they wish to support
REST methods (PUT POST DELETE).

=head2 init_link

Initialize the link() attribute. This is a builder method.

=head2 init_searcher

Subclasses must implement this method. If the Searcher object
acts like a L<SWISH::Prog::Searcher> or L<Dezi::Searcher>, then search() will Just Work.
Otherwise, your Engine subclass should likely override search() as well.

=head2 init_suggester

Subclasses may implement this method. It should return an 
object that acts like L<LucyX::Suggester>: it should
have a method called suggest() which expects a query string
and returns an array ref of strings which will
be included in the Response under the B<suggestions> key.

=head2 search( I<args> )

See the SYNOPSIS.

Returns a Search::OpenSearch::Response object based on the format
specified in I<args>.

=head2 set_limit( I<args> )

Called internally by search(). The I<args> will be three key/value pairs,
with keys "field," "low", and "high".

=head2 facets

Get/set a Search::OpenSearch::Facets object.

=head2 index

Get/set the location of the inverted indexes to be searched. The value
is intented to be used in init_searcher().

=head2 searcher

The value returned by init_searcher().

=head2 suggester

The value returned by init_suggester().

=head2 fields

Get/set the arrayref of field names to be fetched for each search result.

=head2 type

Should return a unique identifier for your Engine subclass.
Default is to croak().

=head2 link

The base URI for Responses. Passed to Response->link.

=head2 get_facets_cache_key( I<query>, I<search_args> )

Returns a string used to key the facets cache. Override this
method in a subclass to implement more nuanced string
construction.

=head2 get_facets( I<query>, I<results> )

Checks the cache for facets related to I<query> and, if found,
returns them. If not found, calls build_facets(), which must
be implemented by each Engine subclass.

=head2 build_facets( I<query>, I<results> )

Default will croak. Engine subclasses must implement this method
to provide Facet support.

=head2 build_results( I<results> )

I<results> should be an iterator like L<Dezi::Results>.

Returns an array ref of hash refs, each corresponding to a single
search result.

=head2 process_result( I<hash_of_args> )

Called by build_results for each result object. I<hash_of_args> is
a list of key/value pairs that includes:

=over

=item result

The values returned from results->next.

=item hiliter

A Search::Tools::HiLiter object.

=item snipper

A Search::Tools::Snipper object.

=item XMLer

A Search::Tools::XML object.

=item fields

Array ref of fields defined in the new() constructor.

=back

Returns a hash ref, where each key is a field name.

=head2 cache_ok

If set to C<0>, no internal cache object will be created for you.
You can still set one in the B<cache> param, but the
automatic creation is turned off.

=head2 cache

Get/set the internal CHI object. Defaults to the File driver.
Typically passed as param in new().

=head2 init_cache_key_seed

The string used in get_facets_cache_key() to construct
the key for caching facets. You can set in new() with 'cache_key_seed'
or override in a base class.

=head2 cache_ttl

Get/set the cache key time-to-live. Default is 1 hour.
Typically passed as param in new().

=head2 do_not_hilite

Get/set the hash ref of field names that should not be hilited
in a Response.
Typically passed as param in new().

=head2 snipper_config

Get/set the hash ref of Search::Tools::Snipper->new params.
Typically passed as param in new().

=head2 hiliter_config

Get/set the hash ref of Search::Tools::HiLiter->new params.
Typically passed as param in new().

=head2 parser_config

Get/set the hash ref of Search::Tools::QueryParser->new params.
Typically passed as param in new().

=head2 indexer_config

Get/set the hash ref available to subclasses that implement
a REST API. Typically passed as param in new().

=head2 searcher_config

Get/set the hash ref available to subclasses in init_searcher().
Typically passed as param in new().

=head2 suggester_config

Get/set the hash ref available to subclasses that implement
init_suggester(). Typically passed as param in new().

=head2 no_hiliting( I<field_name> )

By default, looks up I<field_name> in the do_no_hilite() hash, but
you can override this method to implement whatever logic you want.

=head2 logger( I<logger_object> )

Get/set an optional logging object, which must implement a method
called B<log> and expect a single string.

=head2 has_rest_api( 0|1 )

Override this method in a subclass in order to indicate support
for more than just searching an index. Examples include
support for DELETE, PUT, POST and GET HTTP methods on particular
documents in the index.

Default is false.

=head2 get_allowed_http_methods

Override this method in a subclass in order to indicate the
supported HTTP methods. Assumes has_rest_api() is true.

=head2 debug([boolean])

Get/set the debug flag for messaging on stderr.

=head2 init_default_response_format

Returns default response format. Defaults to 'XML'.

=head2 error

Get/set the error value for the Engine. 

=head2 array_field_values([boolean])

Return all non-default field values as array refs rather than strings.
This supports the multi-value \003 separator used by L<SWISH::3>.

=head2 response_version

The version string to include in Response. Defaults to version().

=head2 init_cache_ttl

Builder method for B<cache_ttl>.

=head2 init_cache_ok

Builder method for B<cache_ok>.

=head2 init_cache

Builder method for B<cache>.

=head2 init_hiliter_config

Builder method for B<hiliter_config>.

=head2 init_indexer_config

Builder method for B<indexer_config>.

=head2 init_parser_config

Builder method for B<parser_config>.

=head2 init_searcher_config

Builder method for B<searcher_config>.

=head2 init_snipper_config

Builder method for B<snipper_config>.

=head2 init_suggester_config

Builder method for B<suggester_config>.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

