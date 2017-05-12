package Search::OpenSearch::Engine::Lucy;
use Moose;
use Carp;
extends 'Search::OpenSearch::Engine';
use Types::Standard qw( Bool Str );
use Dezi::Lucy::Indexer;
use Dezi::Lucy::Searcher;
use Dezi::Indexer::Doc;
use Lucy::Object::BitVector;
use Lucy::Search::Collector::BitCollector;
use Data::Dump qw( dump );
use Scalar::Util qw( blessed );
use Class::Load;
use Path::Class::Dir;
use Search::Tools;
use Try::Tiny;

our $VERSION = '0.400';

has 'aggregator_class' =>
    ( is => 'rw', isa => Str, default => sub {'Dezi::Aggregator'} );
has 'auto_commit' => ( is => 'rw', isa => Bool, default => sub {1} );

sub type {'Lucy'}

sub BUILD {
    my $self = shift;
    Class::Load::load_class( $self->aggregator_class );
    return $self;
}

sub init_searcher {
    my $self     = shift;
    my $index    = $self->index or confess "index not defined";
    my $searcher = Dezi::Lucy::Searcher->new(
        invindex => [@$index],      # copy so that suggester can use strings
        debug    => $self->debug,
        %{ $self->searcher_config },
    );
    if ( !$self->fields ) {
        $self->fields( $searcher->get_propnames );
    }
    return $searcher;
}

sub init_suggester {
    my $self            = shift;
    my %conf            = %{ $self->suggester_config, };
    my $spellcheck_conf = delete $conf{spellcheck_config} || {};
    $spellcheck_conf->{query_parser}
        = Search::Tools->parser( %{ $self->parser_config } );

    # Text::Aspell is optional, so verify we have it
    # before claiming to have a Suggester.
    my $has_suggester = try {
        require LucyX::Suggester;
        $conf{spellcheck} = Search::Tools->spellcheck(%$spellcheck_conf);
        if ( $ENV{TEST_SPELLCHECK_MISSING} ) {
            die "testing missing spellcheck";
        }
        return 1;
    }
    catch {
        if ( $self->debug and $self->logger ) {
            $self->logger->log("Failed to load LucyX::Suggester: $_");
        }
        return 0;
    };
    return unless $has_suggester;

    my $suggester = LucyX::Suggester->new(
        indexes => $self->index,
        debug   => $self->debug,
        %conf,
    );
    return $suggester;
}

sub build_facets {
    my $self  = shift;
    my $query = shift;
    confess "query required" unless defined $query;
    my $results = shift or confess "results required";
    if ( $self->debug and $self->logger ) {
        $self->logger->log( "build_facets check for self->facets="
                . ( $self->facets || 'undef' ) );
    }
    my $facetobj = $self->facets or return;

    my @facet_names = @{ $facetobj->names };
    my $sample_size = $facetobj->sample_size || 0;
    if ( $self->debug and $self->logger ) {
        $self->logger->log( "building facets for "
                . dump( \@facet_names )
                . " with sample_size=$sample_size" );
    }
    my $searcher      = $self->searcher;
    my $lucy_searcher = $searcher->{lucy};
    my $query_parser  = $searcher->{qp};
    my $bit_vec       = Lucy::Object::BitVector->new(
        capacity => $lucy_searcher->doc_max + 1 );
    my $collector
        = Lucy::Search::Collector::BitCollector->new( bit_vector => $bit_vec,
        );

    $lucy_searcher->collect(
        query     => $query_parser->parse("$query")->as_lucy_query(),
        collector => $collector
    );

    # find the facets
    my %facets;
    my $doc_id = 0;
    my $count  = 0;
    my $loops  = 0;
    while (1) {
        $loops++;
        $doc_id = $bit_vec->next_hit( $doc_id + 1 );
        last if $doc_id == -1;
        last if $sample_size and ++$count > $sample_size;
        my $doc = $lucy_searcher->fetch_doc($doc_id);
        for my $name (@facet_names) {

            # unique-ify
            my %val = map { $_ => $_ }
                split( m/\003/,
                ( defined $doc->{$name} ? $doc->{$name} : '' ) );
            for my $value ( keys %val ) {
                $facets{$name}->{$value}++;
            }
        }
    }

    if ( $self->debug and $self->logger ) {
        $self->logger->log(
            "got " . scalar( keys %facets ) . " facets in $loops loops" );
    }

    # turn the struct inside out a bit, esp for XML
    my %facet_struct;
    for my $f ( keys %facets ) {
        for my $n ( keys %{ $facets{$f} } ) {
            push @{ $facet_struct{$f} },
                { term => $n, count => $facets{$f}->{$n} };
        }
    }
    return \%facet_struct;
}

sub has_rest_api {1}

sub get_allowed_http_methods {
    my $self = shift;
    if ( $self->auto_commit ) {
        return qw( GET POST PUT DELETE );
    }
    return qw( GET POST PUT DELETE COMMIT ROLLBACK );
}

sub _massage_rest_req_into_doc {
    my ( $self, $req ) = @_;

    #dump $req;
    my $doc;

    if ( !blessed($req) ) {
        $doc = Dezi::Indexer::Doc->new(
            version => 3,
            %$req
        );
    }
    else {

        #dump $req->headers;

        # $req should act like a HTTP::Request object.
        my %args = (
            version => 3,
            url     => $req->uri->path,        # TODO test
            content => $req->content,
            size    => $req->content_length,
            type    => $req->content_type,

            # type
            # action
            # parser
            # modtime
        );

        #dump \%args;

        $doc = Dezi::Indexer::Doc->new(%args);

    }

    # use set_parser_from_type so that SWISH::3 does the Right Thing
    # instead of looking at the original mime-type.
    my $aggregator
        = $self->aggregator_class->new( set_parser_from_type => 1 );
    $aggregator->swish_filter($doc);

    return $doc;
}

sub init_indexer {
    my $self = shift;
    my $idx = shift || 0;

    if ( $idx =~ m/\D/ ) {
        confess "idx must be an integer for reading into array of index()";
    }
    if ( $idx > scalar @{ $self->index } ) {
        confess sprintf( "idx %d > than index array size %d",
            $idx, scalar @{ $self->index } );
    }

    # unlike a Searcher, which has an array of invindex objects,
    # the Indexer wants only one. We take the first by default,
    # but a subclass could do more subtle logic here.

    my $indexer = Dezi::Lucy::Indexer->new(
        invindex => $self->index->[$idx],
        debug    => $self->debug,
        %{ $self->indexer_config },
    );
    return $indexer;
}

# PUT only if it does not yet exist
# note PUT operates only on first index if there are multiple.
sub PUT {
    my $self = shift;
    my $req  = shift or confess "request required";
    my $doc  = $self->_massage_rest_req_into_doc($req);
    my $uri  = $doc->url;

    # edge case: index might not yet exist.
    my $exists;
    my $index = $self->index or confess "index not defined";
    if (   -d $index->[0]
        && -s Dezi::Lucy::InvIndex->new( $index->[0] . "" )->header_file )
    {
        $exists = $self->GET($uri);
        if ( $exists->{code} == 200 ) {
            return { code => 409, msg => "Document $uri already exists" };
        }
    }

    my $indexer
        = $self->auto_commit
        ? $self->init_indexer()
        : $self->indexer();
    $indexer->process($doc);

    if ( !$self->auto_commit ) {
        my $total = 1;
        return { code => 202, total => 1, };
    }

    my $total = $indexer->finish();
    $exists = $self->GET( $doc->url );
    if ( $exists->{code} != 200 ) {
        return { code => 500, msg => 'Failed to PUT doc' };
    }
    return { code => 201, total => $total, doc => $exists->{doc} };
}

sub _get_indexer {
    my $self = shift;

    # autocommit means we must manage our own indexer
    # since we want to invalidate and re-create

    if ( $self->auto_commit ) {
        return $self->init_indexer(@_);
    }

    # did we have an indexer and it was invalidated? get new one.
    if ( !$self->indexer ) {
        $self->indexer( $self->init_indexer(@_) );
    }
    return $self->indexer;
}

# POST allows new and updates
# note POST operates only on first index if there are multiple
sub POST {
    my $self    = shift;
    my $req     = shift or confess "request required";
    my $doc     = $self->_massage_rest_req_into_doc($req);
    my $uri     = $doc->url;
    my $indexer = $self->_get_indexer;
    $indexer->process($doc);

    if ( !$self->auto_commit ) {
        my $total = 1;
        return { code => 202, total => 1, };
    }

    my $total  = $indexer->finish();
    my $exists = $self->GET( $doc->url );

    if ( $exists->{code} != 200 ) {
        return { code => 500, msg => 'Failed to POST doc' };
    }
    return { code => 200, total => $total, doc => $exists->{doc} };
}

sub COMMIT {
    my $self = shift;
    if ( $self->auto_commit ) {
        return { code => 400 };
    }
    my $indexer = $self->indexer();

    # is it possible to get here? croak just in case.
    if ( !$indexer ) {
        confess "Can't call COMMIT on an undefined indexer";
    }

    if ( my $total = $indexer->count() ) {
        $indexer->finish();

        # MUST invalidate current indexer
        $self->indexer(undef);

        return { code => 200, total => $total };
    }
    else {
        return { code => 204 };
    }
}

sub ROLLBACK {
    my $self = shift;
    if ( !$self->auto_commit ) {
        my $reverted = $self->indexer->count;
        $self->indexer->abort();
        $self->indexer(undef);
        return { code => 200, total => $reverted };
    }
    else {
        return { code => 400 };
    }
}

sub DELETE {
    my $self     = shift;
    my $uri      = shift or confess "uri required";
    my $existing = $self->GET($uri);
    if ( $existing->{code} != 200 ) {
        return {
            code => 404,
            msg  => "$uri cannot be deleted because it does not exist"
        };
    }

    my $i = 0;
    for my $idx ( @{ $self->index } ) {
        my $indexer = $self->_get_indexer( $i++ );
        $indexer->get_lucy->delete_by_term(
            field => 'swishdocpath',
            term  => $uri,
        );
        next unless $self->auto_commit;
        $indexer->finish();
    }
    if ( !$self->auto_commit ) {
        return { code => 202 };
    }
    return { code => 200, };
}

sub _get_swishdocpath_analyzer {
    my $self = shift;
    return $self->{_uri_analyzer} if exists $self->{_uri_analyzer};
    my $qp    = $self->searcher->{qp};         # TODO expose this as accessor?
    my $field = $qp->get_field('swishdocpath');
    if ( !$field ) {

        # field is not defined as a MetaName, just a PropertyName,
        # so we do not analyze it
        $self->{_uri_analyzer} = 0;    # exists but false
        return 0;
    }
    $self->{_uri_analyzer} = $field->analyzer;
    return $self->{_uri_analyzer};
}

sub _analyze_uri_string {
    my ( $self, $uri ) = @_;
    my $analyzer = $self->_get_swishdocpath_analyzer();

    #warn "uri=$uri";

    if ( !$analyzer ) {
        return $uri;
    }
    else {
        return grep { defined and length } @{ $analyzer->split($uri) };
    }
}

sub GET {
    my $self   = shift;
    my $uri    = shift or confess "uri required";
    my $params = shift;                             # undef ok

    # use internal Lucy searcher directly to avoid needing MetaName defined
    my $q = Lucy::Search::PhraseQuery->new(
        field => 'swishdocpath',
        terms => [ $self->_analyze_uri_string($uri) ]
    );

    #warn "q=" . $q->to_string();

    my $lucy_searcher = $self->searcher->get_lucy();
    my $hits = $lucy_searcher->hits( query => $q );

    #warn "$q total=" . $hits->total_hits();
    my $hitdoc = $hits->next;

    if ( !$hitdoc ) {
        return { code => 404, };
    }

    #dump $hitdoc;

    # get all fields
    my %doc;
    my $fields = $self->fields;
    for my $field (@$fields) {
        my $str = $hitdoc->{$field};
        $doc{$field} = [ split( m/\003/, defined $str ? $str : "" ) ];
    }
    $doc{title}   = $hitdoc->{swishtitle};
    $doc{summary} = $hitdoc->{swishdescription};
    $doc{mtime}   = $hitdoc->{swishlastmodified};

    # highlight query string if present
    if ( $params and $params->{q} ) {
        my %hiliter_config = %{ $self->hiliter_config };
        my %parser_config  = %{ $self->parser_config };
        my $query
            = Search::Tools->parser(%parser_config)->parse( $params->{q} );
        my $hiliter
            = Search::Tools->hiliter( query => $query, %hiliter_config );

        for my $f ( keys %doc ) {
            next if $self->no_hiliting($f);
            if ( ref $doc{$f} ) {
                my @hv;
                for my $v ( @{ $doc{$f} } ) {
                    push @hv, $hiliter->light($v);
                }
                $doc{$f} = \@hv;
            }
            else {
                $doc{$f} = $hiliter->light( $doc{$f} );
            }
        }
    }

    my $ret = {
        code => 200,
        doc  => \%doc,
    };

    #dump $ret;

    return $ret;
}

1;

__END__

=head1 NAME

Search::OpenSearch::Engine::Lucy - Lucy server with OpenSearch results

=head1 SYNOPSIS

 use Search::OpenSearch::Engine::Lucy;
 my $engine = Search::OpenSearch::Engine::Lucy->new(
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
        spellcheck_config => {
            lang => 'en_US',
        },
        limit => 10,
    },
    aggregator_class => 'MyAggregator', # defaults to Dezi::Aggregator
    cache           => CHI->new(
        driver           => 'File',
        dir_create_mode  => 0770,
        file_create_mode => 0660,
        root_dir         => "/tmp/opensearch_cache",
    ),
    cache_ttl       => 3600,
    do_not_hilite   => [qw( color )],
    snipper_config  => { as_sentences => 1, strip_markup => 1, }, # see Search::Tools::Snipper
    hiliter_config  => { class => 'h', tag => 'b' }, # see Search::Tools::HiLiter
    parser_config   => {},                           # see Search::Query::Parser
    
 );
 my $response = $engine->search(
    q           => 'quick brown fox',   # query
    s           => 'score desc',        # sort order
    o           => 0,                   # offset
    p           => 25,                  # page size
    h           => 1,                   # highlight query terms in results
    c           => 0,                   # count total only (same as f=0 r=0)
    L           => 'field|low|high',    # limit results to inclusive range
    f           => 1,                   # include facets
    r           => 1,                   # include results
    t           => 'XML',               # or JSON
    u           => 'http://yourdomain.foo/opensearch/',
    b           => 'AND',               # or OR
 );
 print $response;

=head1 METHODS

=head2 type

Returns C<Lucy>.

=head2 aggregator_class

Passed as param to new(). This class is used for filtering
incoming docs via the aggregator's swish_filter() method.

=head2 auto_commit( 0 | 1 )

Set this in new().

If true, a new indexer is spawned via init_indexer() for
each POST, PUT or DELETE.

If false, the same indexer is re-used in POST, PUT or DELETE
calls, until COMMIT or ROLLBACK is called.

Default is true (on).

=head2 BUILD

Overrides base method to load the I<aggregator_class> and other
Engine-specific construction tasks.

=head2 init_searcher

Returns a Dezi::Lucy::Searcher object.

=head2 init_indexer

Returns a Dezi::Lucy::Indexer object (used by the REST API).

=head2 init_suggester

Returns a LucyX::Suggester object. You can configure it as
described in the SYNOPSIS.

=head2 build_facets( I<query>, I<results> )

Returns hash ref of facets from I<results>. See Search::OpenSearch::Engine.

=head2 process_result( I<args> )

Overrides base method to preserve multi-value fields as arrays.

=head2 has_rest_api

Returns true.

=head2 get_allowed_http_methods

Returns array (not an array ref) of supported HTTP method names.
These correspond to the UPPERCASE method names below.

B<NOTE> that COMMIT and ROLLBACK are not official HTTP/1.1 method
names.

=head2 PUT( I<doc> )

Writes I<doc> to the first index defined. I<doc> must already exist.

=head2 POST( I<doc> )

Writes I<doc> to the first index defined. I<doc> may be new or already exist.

=head2 DELETE( I<uri> )

Deletes I<uri> from all indexes.

=head2 GET( I<uri> )

Fetches I<uri> from all indexes.

=head2 COMMIT

If auto_commit is false, use this method to conclude a transaction.

=head2 ROLLBACK

If auto_commit is false, use this method to abort a transaction.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-engine-lucy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Engine-Lucy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Engine::Lucy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Engine-Lucy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Engine-Lucy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Engine-Lucy>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Engine-Lucy/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
