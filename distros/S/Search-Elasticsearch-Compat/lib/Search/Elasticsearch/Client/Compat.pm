package Search::Elasticsearch::Client::Compat;
$Search::Elasticsearch::Client::Compat::VERSION = '0.10';
use Moo;
with 'Search::Elasticsearch::Role::Client';

use strict;
use warnings;
use Any::URI::Escape qw(uri_escape);
use JSON;
use Search::Elasticsearch::Util qw(throw parse_params);
use Carp;

has 'JSON'     => ( is => 'lazy' );
has '_base_qs' => ( is => 'ro', default => sub { {} } );
has '_default' => ( is => 'ro', default => sub { {} } );
has 'builder'  => ( is => 'lazy' );
has 'builder_class' =>
    ( is => 'ro', default => 'ElasticSearch::SearchBuilder' );

use constant {
    ONE_REQ     => 1,
    ONE_OPT     => 2,
    ONE_ALL     => 3,
    MULTI_ALL   => 4,
    MULTI_BLANK => 5,
    MULTI_REQ   => 6,
};

use constant {
    CMD_NONE          => [],
    CMD_INDEX_TYPE_ID => [ index => ONE_REQ, type => ONE_REQ, id => ONE_REQ ],
    CMD_INDEX_TYPE_id => [ index => ONE_REQ, type => ONE_REQ, id => ONE_OPT ],
    CMD_INDEX_type_ID => [ index => ONE_REQ, type => ONE_ALL, id => ONE_REQ ],
    CMD_Index           => [ index => ONE_OPT ],
    CMD_index           => [ index => MULTI_BLANK ],
    CMD_indices         => [ index => MULTI_ALL ],
    CMD_INDICES         => [ index => MULTI_REQ ],
    CMD_INDEX           => [ index => ONE_REQ ],
    CMD_INDEX_TYPE      => [ index => ONE_REQ, type => ONE_REQ ],
    CMD_INDEX_type      => [ index => ONE_REQ, type => MULTI_BLANK ],
    CMD_index_TYPE      => [ index => MULTI_ALL, type => ONE_REQ ],
    CMD_index_types     => [ index => MULTI_ALL, type => MULTI_REQ ],
    CMD_INDICES_TYPE    => [ index => MULTI_REQ, type => ONE_REQ ],
    CMD_index_type      => [ index => MULTI_ALL, type => MULTI_BLANK ],
    CMD_index_then_type => [ index => ONE_OPT, type => ONE_OPT ],
    CMD_RIVER           => [ river => ONE_REQ ],
    CMD_nodes           => [ node  => MULTI_BLANK ],
    CMD_NAME            => [ name  => ONE_REQ ],
    CMD_INDEX_PERC      => [ index => ONE_REQ, percolator => ONE_REQ ],

    CONSISTENCY => [ 'enum', [ 'one', 'quorum', 'all' ] ],
    REPLICATION => [ 'enum', [ 'async', 'sync' ] ],
    SEARCH_TYPE => [
        'enum',
        [   'dfs_query_then_fetch', 'dfs_query_and_fetch',
            'query_then_fetch',     'query_and_fetch',
            'count',                'scan'
        ]
    ],
    IGNORE_INDICES => [ 'enum', [ 'missing', 'none' ] ],

};

our %QS_Format = (
    boolean  => '1 | 0',
    duration => "'5m' | '10s'",
    optional => "'scalar value'",
    flatten  => "'scalar' or ['scalar_1', 'scalar_n']",
    'int'    => "integer",
    string   => sub {
        my $k = shift;
        return $k eq 'preference'
            ? '_local | _primary | _primary_first | $string'
            : $k eq 'percolate' || $k eq 'q' ? '$query_string'
            : $k eq 'scroll_id' ? '$scroll_id'
            : $k eq 'df'        ? '$default_field'
            :                     '$string';
    },
    float   => 'float',
    enum    => sub { join " | ", @{ $_[1][1] } },
    coderef => 'sub {..} | "IGNORE"',
);

our %QS_Formatter = (
    boolean => sub {
        my $key = shift;
        my $val = $_[0] ? $_[1] : $_[2];
        return unless defined $val;
        return ref $val ? $val : [ $key, $val ? 'true' : 'false' ];
    },
    duration => sub {
        my ( $k, $t ) = @_;
        return unless defined $t;
        return [ $k, $t ] if $t =~ /^\d+([smh]|ms)$/i;
        die "$k '$t' is not in the form $QS_Format{duration}\n";
    },
    flatten => sub {
        my $key = shift;
        my $array = shift or return;
        return [ $key, ref $array ? join( ',', @$array ) : $array ];
    },
    'int' => sub {
        my $key = shift;
        my $int = shift;
        return unless defined $int;
        eval { $int += 0; 1 } or die "'$key' is not an integer";
        return [ $key, $int ];
    },
    'float' => sub {
        my $key   = shift;
        my $float = shift;
        return unless defined $float;
        $key = shift if @_;
        eval { $float += 0; 1 } or die "'$key' is not a float";
        return [ $key, $float ];
    },
    'string' => sub {
        my $key    = shift;
        my $string = shift;
        return unless defined $string;
        return [ $key, $string ];
    },
    'coderef' => sub {
        my $key     = shift;
        my $coderef = shift;
        return unless defined $coderef;
        unless ( ref $coderef ) {
            die "'$key' is not a code ref or the string 'IGNORE'"
                unless $coderef eq 'IGNORE';
            $coderef = sub { };
        }
        return [ $key, $coderef ];
    },
    'enum' => sub {
        my $key = shift;
        my $val = shift;
        return unless defined $val;
        my $vals = $_[0];
        for (@$vals) {
            return [ $key, $val ] if $val eq $_;
        }
        die "Unrecognised value '$val'. Allowed values: "
            . join( ', ', @$vals );
    },

);

#===================================
sub _build_JSON {
#===================================
    JSON->new->utf8(1);
}

#===================================
sub _build_builder {
#===================================
    my $self  = shift;
    my $class = $self->builder_class
        or throw( 'Param', "No builder_class specified" );
    eval "require $class; 1"
        or throw( 'Internal',
        "Couldn't load class $class: " . ( $@ || 'Unknown error' ) );
    return $self->{_builder} = $class->new(@_);
}

#===================================
sub request {
#===================================
    my ( $self, $params ) = parse_params(@_);

    my $result;
    eval { $result = $self->transport->perform_request($params); 1 };
    if ( my $error = $@ ) {
        $error->{-vars} = delete $error->{vars};
        die $error;
    }

    $result
        = $params->{post_process}
        ? $params->{post_process}->($result)
        : $result;
    return $params->{as_json} ? $self->JSON->encode($result) : $result;

}

#===================================
sub use_index {
#===================================
    my $self = shift;
    if (@_) {
        $self->{_default}{index} = shift;
    }
    return $self->{_default}{index};
}

#===================================
sub use_type {
#===================================
    my $self = shift;
    if (@_) {
        $self->{_default}{type} = shift;
    }
    return $self->{_default}{type};
}

#===================================
sub reindex {
#===================================
    my ( $self, $params ) = parse_params(@_);

    my $source = $params->{source}
        or throw( 'Param', 'Missing source param' );

    my $transform  = $params->{transform} || sub { shift() };
    my $verbose    = !$params->{quiet};
    my $dest_index = $params->{dest_index};
    my $bulk_size  = $params->{bulk_size} || 1000;
    my $method     = $params->{_method_name} || 'next';

    local $| = $verbose;
    printf( "Reindexing %d docs\n", $source->total )
        if $verbose;

    my @docs;
    while (1) {
        my $doc = $source->$method();
        if ( !$doc or @docs == $bulk_size ) {
            my $results = $self->bulk_index(
                docs => \@docs,
                map { $_ => $params->{$_} } qw(on_conflict on_error),
            );
            if ( my $err = $results->{errors} ) {
                my @errors = splice @$err, 0, 5;
                push @errors, sprintf "...and %d more", scalar @$err
                    if @$err;
                throw( 'Request', "Errors occurred while reindexing:",
                    \@errors );
            }
            @docs = ();
            print "." if $verbose;
        }
        last unless $doc;

        $doc = $transform->($doc) or next;
        $doc->{version_type} = 'external'
            if defined $doc->{_version};
        if ( my $fields = delete $doc->{fields} ) {
            $doc->{parent} = $fields->{_parent}
                if defined $fields->{_parent};
        }
        $doc->{_index} = $dest_index
            if $dest_index;
        push @docs, $doc;
    }

    print "\nDone\n" if $verbose;
}

#===================================
sub query_parser {
#===================================
    require Search::Elasticsearch::Compat::QueryParser;
    shift;    # drop class/$self
    Search::Elasticsearch::Compat::QueryParser->new(@_);
}

##################################
## DOCUMENT MANAGEMENT
##################################

#===================================
sub get {
#===================================
    shift()->_do_action(
        'get',
        {   cmd => CMD_INDEX_type_ID,
            qs  => {
                fields         => ['flatten'],
                ignore_missing => [ 'boolean', 1 ],
                preference     => ['string'],
                refresh        => [ 'boolean', 1 ],
                routing        => ['string'],
                parent         => ['string'],
            },
        },
        @_
    );
}

#===================================
sub exists : method {
#===================================
    shift()->_do_action(
        'exists',
        {   method => 'HEAD',
            cmd    => CMD_INDEX_TYPE_ID,
            qs     => {
                preference => ['string'],
                refresh    => [ 'boolean', 1 ],
                routing    => ['string'],
                parent     => ['string'],
            },
            fixup => sub { $_[1]->{qs}{ignore_missing} = 1 },
            post_process => sub { $_[0] ? { ok => 1 } : undef },
        },
        @_
    );
}

#===================================
sub mget {
#===================================
    my ( $self, $params ) = parse_params(@_);

    $params->{$_} ||= $self->{_default}{$_} for qw(index type);

    if ( $params->{index} ) {
        if ( my $ids = delete $params->{ids} ) {
            throw( 'Param', 'mget',
                'Cannot specify both ids and docs in mget()' )
                if $params->{docs};
            $params->{docs} = [ map { +{ _id => $_ } } @$ids ];
        }
    }
    else {
        throw( 'Param',
            'Cannot specify a type for mget() without specifying index' )
            if $params->{type};
        throw( 'Param', 'Use of the ids param with mget() requires an index' )
            if $params->{ids};
    }

    my $filter;
    $self->_do_action(
        'mget',
        {   cmd     => [ index => ONE_OPT, type => ONE_OPT ],
            postfix => '_mget',
            data => { docs => 'docs' },
            qs   => {
                fields         => ['flatten'],
                filter_missing => [ 'boolean', 1 ],
            },
            fixup => sub {
                $_[1]->{skip} = [] unless @{ $_[1]{body}{docs} };
                $filter = delete $_[1]->{qs}{filter_missing};
            },
            post_process => sub {
                my $result = shift;
                my $docs   = $result->{docs};
                return $filter ? [ grep { $_->{exists} } @$docs ] : $docs;
                }
        },
        $params
    );
}

my %Index_Defn = (
    cmd => CMD_INDEX_TYPE_id,
    qs  => {
        consistency => CONSISTENCY,
        create      => [ 'boolean', [ op_type => 'create' ] ],
        parent      => ['string'],
        percolate   => ['string'],
        refresh     => [ 'boolean', 1 ],
        replication => REPLICATION,
        routing     => ['string'],
        timeout     => ['duration'],
        timestamp   => ['string'],
        ttl         => ['int'],
        version     => ['int'],
        version_type => [ 'enum', [ 'internal', 'external' ] ],
    },
    data  => { data => 'data' },
    fixup => sub {
        $_[1]{body} = $_[1]{body}{data};
    }
);

#===================================
sub index {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $self->_index( 'index', \%Index_Defn, $params );
}

#===================================
sub set {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $self->_index( 'set', \%Index_Defn, $params );
}

#===================================
sub create {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $self->_index( 'create', \%Index_Defn, { %$params, create => 1 } );
}

#===================================
sub _index {
#===================================
    my $self = shift;
    $_[1]->{method} = $_[2]->{id} ? 'PUT' : 'POST';
    $self->_do_action(@_);
}

#===================================
sub update {
#===================================
    shift()->_do_action(
        'update',
        {   method  => 'POST',
            cmd     => CMD_INDEX_TYPE_ID,
            postfix => '_update',
            data    => {
                script => ['script'],
                params => ['params'],
                doc    => ['doc'],
                upsert => ['upsert'],
            },
            qs => {
                consistency       => CONSISTENCY,
                fields            => ['flatten'],
                ignore_missing    => [ 'boolean', 1 ],
                parent            => ['string'],
                percolate         => ['string'],
                retry_on_conflict => ['int'],
                routing           => ['string'],
                timeout           => ['duration'],
                replication       => REPLICATION,
            }
        },
        @_
    );
}

#===================================
sub delete {
#===================================
    shift()->_do_action(
        'delete',
        {   method => 'DELETE',
            cmd    => CMD_INDEX_TYPE_ID,
            qs     => {
                consistency    => CONSISTENCY,
                ignore_missing => [ 'boolean', 1 ],
                refresh        => [ 'boolean', 1 ],
                parent         => ['string'],
                routing        => ['string'],
                version        => ['int'],
                replication    => REPLICATION,
            }
        },
        @_
    );
}

#===================================
sub analyze {
#===================================
    shift()->_do_action(
        'analyze',
        {   method  => 'GET',
            cmd     => CMD_Index,
            postfix => '_analyze',
            qs      => {
                text         => ['string'],
                analyzer     => ['string'],
                tokenizer    => ['string'],
                filters      => ['flatten'],
                field        => ['string'],
                format       => [ 'enum', [ 'detailed', 'text' ] ],
                prefer_local => [ 'boolean', undef, 0 ],
            }
        },
        @_
    );
}

##################################
## BULK INTERFACE
##################################

#===================================
sub bulk {
#===================================
    my $self = shift;
    $self->_bulk( 'bulk', $self->_bulk_params( 'actions', @_ ) );
}

#===================================
sub _bulk {
#===================================
    my ( $self, $method, $params ) = @_;
    my %callbacks;
    my $actions = $params->{actions} || [];

    $self->_do_action(
        $method,
        {   cmd     => CMD_index_then_type,
            method  => 'POST',
            postfix => '_bulk',
            qs      => {
                consistency => CONSISTENCY,
                replication => REPLICATION,
                refresh     => [ 'boolean', 1 ],
                timeout     => ['duration'],
                on_conflict => ['coderef'],
                on_error    => ['coderef'],
            },
            data  => { actions => 'actions' },
            fixup => sub {
                die "Cannot specify type without index"
                    if $params->{type} && !$params->{index};
                $_[1]->{body} = $self->_bulk_request($actions);
                $_[1]->{skip} = { actions => [], results => [] }
                    unless $_[1]->{body};
                $callbacks{$_} = delete $_[1]->{qs}{$_}
                    for qw(on_error on_conflict);
            },
            post_process => sub {
                $self->_bulk_response( \%callbacks, $actions, @_ );
            },
        },
        $params
    );
}

#===================================
sub bulk_index  { shift->_bulk_action( 'index',  @_ ) }
sub bulk_create { shift->_bulk_action( 'create', @_ ) }
sub bulk_delete { shift->_bulk_action( 'delete', @_ ) }
#===================================

#===================================
sub _bulk_action {
#===================================
    my $self   = shift;
    my $action = shift;
    my $params = $self->_bulk_params( 'docs', @_ );
    $params->{actions}
        = [ map { +{ $action => $_ } } @{ delete $params->{docs} } ];
    return $self->_bulk( "bulk_$action", $params );
}

#===================================
sub _bulk_params {
#===================================
    my $self = shift;
    my $key  = shift;

    return { $key => [], @_ } unless ref $_[0];
    return
        ref $_[0] eq 'ARRAY' ? { $key => $_[0] } : { $key => [], %{ $_[0] } }
        unless @_ > 1;

    carp "The method signature for bulk methods has changed. "
        . "Please check the docs.";

    if ( ref $_[0] eq 'ARRAY' ) {
        my $first = shift;
        my $params = ref $_[0] ? shift : {@_};
        $params->{$key} = $first;
        return $params;
    }
    return { $key => \@_ };
}

my %Bulk_Actions = (
    'delete' => {
        index        => ONE_OPT,
        type         => ONE_OPT,
        id           => ONE_REQ,
        parent       => ONE_OPT,
        routing      => ONE_OPT,
        version      => ONE_OPT,
        version_type => ONE_OPT,
    },
    'index' => {
        index        => ONE_OPT,
        type         => ONE_OPT,
        id           => ONE_OPT,
        data         => ONE_REQ,
        routing      => ONE_OPT,
        parent       => ONE_OPT,
        percolate    => ONE_OPT,
        timestamp    => ONE_OPT,
        ttl          => ONE_OPT,
        version      => ONE_OPT,
        version_type => ONE_OPT,
    },
);
$Bulk_Actions{create} = $Bulk_Actions{index};

#===================================
sub _bulk_request {
#===================================
    my $self    = shift;
    my $actions = shift;

    my $json      = $self->JSON;
    my $indenting = $json->get_indent;
    $json->indent(0);

    my $json_docs = '';
    my $error;
    eval {
        for my $data (@$actions) {
            die "'actions' must be an ARRAY ref of HASH refs"
                unless ref $data eq 'HASH';

            my ( $action, $params ) = %$data;
            $action ||= '';
            my $defn = $Bulk_Actions{$action}
                || die "Unknown action '$action'";

            my %metadata;
            $params = {%$params};
            delete @{$params}{qw(_score sort)};
            $params->{data} ||= delete $params->{_source}
                if $params->{_source};

            for my $key ( keys %$defn ) {
                my $val = delete $params->{$key};
                $val = delete $params->{"_$key"} unless defined $val;
                unless ( defined $val ) {
                    next if $defn->{$key} == ONE_OPT;
                    die "Missing required param '$key' for action '$action'";
                }
                $metadata{"_$key"} = $val;
            }
            die "Unknown params for bulk action '$action': "
                . join( ', ', keys %$params )
                if keys %$params;

            my $data = delete $metadata{_data};
            my $request = $json->encode( { $action => \%metadata } ) . "\n";
            if ($data) {
                $data = $json->encode($data) if ref $data eq 'HASH';
                $request .= $data . "\n";
            }
            $json_docs .= $request;
        }
        1;
    } or $error = $@ || 'Unknown error';

    $json->indent($indenting);
    die $error if $error;

    return $json_docs;
}

#===================================
sub _bulk_response {
#===================================
    my $self      = shift;
    my $callbacks = shift;
    my $actions   = shift;
    my $results   = shift;

    my $items = ref($results) eq 'HASH' && $results->{items}
        || throw( 'Request', 'Malformed response to bulk query', $results );

    my ( @errors, %matches );
    my ( $on_conflict, $on_error ) = @{$callbacks}{qw(on_conflict on_error)};

    for ( my $i = 0; $i < @$actions; $i++ ) {
        my ( $action, $item ) = ( %{ $items->[$i] } );
        if ( my $match = $item->{matches} ) {
            push @{ $matches{$_} }, $item for @$match;
        }

        my $error = $items->[$i]{$action}{error} or next;
        if (    $on_conflict
            and $error =~ /
                      VersionConflictEngineException
                    | DocumentAlreadyExistsException
                  /x
            )
        {
            $on_conflict->( $action, $actions->[$i]{$action}, $error, $i );
        }
        elsif ($on_error) {
            $on_error->( $action, $actions->[$i]{$action}, $error, $i );
        }
        else {
            push @errors, { action => $actions->[$i], error => $error };
        }
    }

    return {
        actions => $actions,
        results => $items,
        matches => \%matches,
        took    => $results->{took},
        ( @errors ? ( errors => \@errors ) : () )
    };
}

##################################
## DSL FIXUP
##################################

#===================================
sub _to_dsl {
#===================================
    my $self = shift;
    my $ops  = shift;
    my $builder;
    foreach my $clause (@_) {
        while ( my ( $old, $new ) = each %$ops ) {
            my $src = delete $clause->{$old} or next;
            die "Cannot specify $old and $new parameters.\n"
                if $clause->{$new};
            $builder ||= $self->builder;
            my $method = $new eq 'query' ? 'query' : 'filter';
            my $sub_clause = $builder->$method($src) or next;
            $clause->{$new} = $sub_clause->{$method};
        }
    }
}

#===================================
sub _data_fixup {
#===================================
    my $self = shift;
    my $data = shift;
    $self->_to_dsl( { queryb => 'query', filterb => 'filter' }, $data );

    my $facets = $data->{facets} or return;
    die "(facets) must be a HASH ref" unless ref $facets eq 'HASH';
    $facets = $data->{facets} = {%$facets};
    for ( values %$facets ) {
        die "All (facets) must be HASH refs" unless ref $_ eq 'HASH';
        $_ = my $facet = {%$_};
        $self->_to_dsl(
            {   queryb        => 'query',
                filterb       => 'filter',
                facet_filterb => 'facet_filter'
            },
            $facet
        );
    }
}

#===================================
sub _query_fixup {
#===================================
    my $self = shift;
    my $args = shift;
    $self->_to_dsl( { queryb => 'query' }, $args->{body} );
    if ( my $query = delete $args->{body}{query} ) {
        my ( $k, $v ) = %$query;
        $args->{body}{$k} = $v;
    }
}

#===================================
sub _warmer_fixup {
#===================================
    my ( $self, $args ) = @_;
    my $warmers = $args->{body}{warmers} or return;
    $warmers = $args->{body}{warmers} = {%$warmers};
    for ( values %$warmers ) {
        $_ = {%$_};
        my $source = $_->{source} or next;
        $_->{source} = $source = {%$source};
        $self->_data_fixup($source);
    }
}

##################################
## QUERIES
##################################

my %Search_Data = (
    explain       => ['explain'],
    facets        => ['facets'],
    fields        => ['fields'],
    filter        => ['filter'],
    filterb       => ['filterb'],
    from          => ['from'],
    highlight     => ['highlight'],
    indices_boost => ['indices_boost'],
    min_score     => ['min_score'],
    script_fields => ['script_fields'],
    size          => ['size'],
    'sort'        => ['sort'],
    track_scores  => ['track_scores'],
);

my %Search_Defn = (
    cmd     => CMD_index_type,
    postfix => '_search',
    data    => {
        %Search_Data,
        query          => ['query'],
        queryb         => ['queryb'],
        partial_fields => ['partial_fields']
    },
    qs => {
        search_type    => SEARCH_TYPE,
        ignore_indices => IGNORE_INDICES,
        preference     => ['string'],
        routing        => ['flatten'],
        timeout        => ['duration'],
        scroll         => ['duration'],
        stats          => ['flatten'],
        version        => [ 'boolean', 1 ]
    },
    fixup => sub { $_[0]->_data_fixup( $_[1]->{body} ) },
);

my %SearchQS_Defn = (
    cmd     => CMD_index_type,
    postfix => '_search',
    qs      => {
        q                => ['string'],
        df               => ['string'],
        analyze_wildcard => [ 'boolean', 1 ],
        analyzer         => ['string'],
        default_operator => [ 'enum', [ 'OR', 'AND' ] ],
        explain                  => [ 'boolean', 1 ],
        fields                   => ['flatten'],
        from                     => ['int'],
        ignore_indices           => IGNORE_INDICES,
        lenient                  => [ 'boolean', 1 ],
        lowercase_expanded_terms => [ 'boolean', 1 ],
        min_score                => ['float'],
        preference               => ['string'],
        quote_analyzer           => ['string'],
        quote_field_suffix       => ['string'],
        routing                  => ['flatten'],
        scroll                   => ['duration'],
        search_type              => SEARCH_TYPE,
        size                     => ['int'],
        'sort'                   => ['flatten'],
        stats                    => ['flatten'],
        timeout                  => ['duration'],
        version                  => [ 'boolean', 1 ],
    },
);

my %Query_Defn = (
    data => {
        query  => ['query'],
        queryb => ['queryb'],
    },
    deprecated => {
        bool               => ['bool'],
        boosting           => ['boosting'],
        constant_score     => ['constant_score'],
        custom_score       => ['custom_score'],
        dis_max            => ['dis_max'],
        field              => ['field'],
        field_masking_span => ['field_masking_span'],
        filtered           => ['filtered'],
        flt                => [ 'flt', 'fuzzy_like_this' ],
        flt_field          => [ 'flt_field', 'fuzzy_like_this_field' ],
        fuzzy              => ['fuzzy'],
        has_child          => ['has_child'],
        ids                => ['ids'],
        match_all          => ['match_all'],
        mlt                => [ 'mlt', 'more_like_this' ],
        mlt_field          => [ 'mlt_field', 'more_like_this_field' ],
        prefix             => ['prefix'],
        query_string       => ['query_string'],
        range              => ['range'],
        span_first         => ['span_first'],
        span_near          => ['span_near'],
        span_not           => ['span_not'],
        span_or            => ['span_or'],
        span_term          => ['span_term'],
        term               => ['term'],
        terms              => [ 'terms', 'in' ],
        text               => ['text'],
        text_phrase        => ['text_phrase'],
        text_phrase_prefix => ['text_phrase_prefix'],
        top_children       => ['top_children'],
        wildcard           => ['wildcard'],
    }
);

#===================================
sub search   { shift()->_do_action( 'search',   \%Search_Defn,   @_ ) }
sub searchqs { shift()->_do_action( 'searchqs', \%SearchQS_Defn, @_ ) }
#===================================

#===================================
sub msearch {
#===================================
    my ( $self, $params ) = parse_params(@_);
    my $queries = $params->{queries} || [];

    my $order;
    if ( ref $queries eq 'HASH' ) {
        $order = {};
        my $i = 0;
        my @queries;
        for ( sort keys %$queries ) {
            $order->{$_} = $i++;
            push @queries, $queries->{$_};
        }
        $queries = \@queries;
    }

    $self->_do_action(
        'msearch',
        {   cmd     => CMD_index_type,
            method  => 'GET',
            postfix => '_msearch',
            qs      => { search_type => SEARCH_TYPE },
            data    => { queries => 'queries' },
            fixup   => sub {
                my ( $self, $args ) = @_;
                $args->{body} = $self->_msearch_queries($queries);
                $args->{skip} = $order ? {} : [] unless $args->{body};
            },
            post_process => sub {
                my $responses = shift->{responses};
                return $responses unless $order;
                return {
                    map { $_ => $responses->[ $order->{$_} ] }
                        keys %$order
                };
            },
        },
        $params
    );
}

my %MSearch = (
    ( map { $_ => 'h' } 'index', 'type', keys %{ $Search_Defn{qs} } ),
    (   map { $_ => 'b' } 'timeout', 'stats',
        'version', keys %{ $Search_Defn{data} }
    )
);
delete $MSearch{scroll};

#===================================
sub _msearch_queries {
#===================================
    my $self    = shift;
    my $queries = shift;

    my $json      = $self->JSON;
    my $indenting = $json->get_indent;
    $json->indent(0);

    my $json_docs = '';
    my $error;
    eval {
        for my $query (@$queries) {
            die "'queries' must contain HASH refs\n"
                unless ref $query eq 'HASH';

            my %request = ( h => {}, b => {} );
            for ( keys %$query ) {
                my $dest = $MSearch{$_}
                    or die "Unknown param for msearch: $_\n";
                $request{$dest}{$_} = $query->{$_};
            }

            # flatten arrays
            for (qw(index type stats routing)) {
                $request{h}{$_} = join ",", @{ $request{h}{$_} }
                    if ref $request{h}{$_} eq 'ARRAY';
            }
            $self->_data_fixup( $request{b} );
            $json_docs .= $json->encode( $request{h} ) . "\n"
                . $json->encode( $request{b} ) . "\n";
        }
        1;
    } or $error = $@ || 'Unknown error';

    $json->indent($indenting);
    die $error if $error;

    return $json_docs;
}

#===================================
sub validate_query {
#===================================
    shift->_do_action(
        'validate_query',
        {   cmd     => CMD_index_type,
            postfix => '_validate/query',
            data    => {
                query  => ['query'],
                queryb => ['queryb'],
            },
            qs => {
                q              => ['string'],
                explain        => [ 'boolean', 1 ],
                ignore_indices => IGNORE_INDICES,
            },
            fixup => sub {
                my $args = $_[1];
                if ( defined $args->{qs}{q} ) {
                    die "Cannot specify q and query/queryb parameters.\n"
                        if %{ $args->{body} };
                    delete $args->{body};
                }
                else {
                    eval { _query_fixup(@_); 1 } or do {
                        die $@ if $@ =~ /Cannot specify queryb and query/;
                    };
                }
            },
        },
        @_
    );
}

#===================================
sub explain {
#===================================
    shift->_do_action(
        'explain',
        {   cmd     => CMD_INDEX_TYPE_ID,
            postfix => '_explain',
            data    => {
                query  => ['query'],
                queryb => ['queryb'],
            },
            qs => {
                preference               => ['string'],
                routing                  => ['string'],
                q                        => ['string'],
                df                       => ['string'],
                analyzer                 => ['string'],
                analyze_wildcard         => [ 'boolean', 1 ],
                default_operator         => [ 'enum', [ 'OR', 'AND' ] ],
                fields                   => ['flatten'],
                lowercase_expanded_terms => [ 'boolean', undef, 0 ],
                lenient => [ 'boolean', 1 ],
            },
            fixup => sub {
                my $args = $_[1];
                if ( defined $args->{qs}{q} ) {
                    die "Cannot specify q and query/queryb parameters.\n"
                        if %{ $args->{body} };
                    delete $args->{body};
                }
                else {
                    $_[0]->_data_fixup( $args->{body} );
                }
            },
        },
        @_
    );
}

#===================================
sub scroll {
#===================================
    shift()->_do_action(
        'scroll',
        {   cmd    => [],
            prefix => '_search/scroll',
            qs     => {
                scroll_id => ['string'],
                scroll    => ['duration'],
            }
        },
        @_
    );
}

#===================================
sub scrolled_search {
#===================================
    my $self = shift;
    require Search::Elasticsearch::Compat::ScrolledSearch;
    return Search::Elasticsearch::Compat::ScrolledSearch->new( $self, @_ );
}

#===================================
sub delete_by_query {
#===================================
    shift()->_do_action(
        'delete_by_query',
        {   %Search_Defn,
            method  => 'DELETE',
            postfix => '_query',
            qs      => {
                consistency => CONSISTENCY,
                replication => REPLICATION,
                routing     => ['flatten'],
            },
            %Query_Defn,
            fixup => sub {
                _query_fixup(@_);
                die "Missing required param 'query' or 'queryb'\n"
                    unless %{ $_[1]->{body} };
            },
        },
        @_
    );
}

#===================================
sub count {
#===================================
    shift()->_do_action(
        'count',
        {   %Search_Defn,
            postfix => '_count',
            %Query_Defn,
            qs => {
                routing        => ['flatten'],
                ignore_indices => IGNORE_INDICES,
            },
            fixup => sub {
                _query_fixup(@_);
                delete $_[1]{body} unless %{ $_[1]{body} };
            },
        },
        @_
    );
}

#===================================
sub mlt {
#===================================
    shift()->_do_action(
        'mlt',
        {   cmd    => CMD_INDEX_TYPE_ID,
            method => 'GET',
            qs     => {
                mlt_fields         => ['flatten'],
                pct_terms_to_match => [ 'float', 'percent_terms_to_match' ],
                min_term_freq      => ['int'],
                max_query_terms    => ['int'],
                stop_words         => ['flatten'],
                min_doc_freq       => ['int'],
                max_doc_freq       => ['int'],
                min_word_len       => ['int'],
                max_word_len       => ['int'],
                boost_terms        => ['float'],
                routing            => ['flatten'],
                search_indices     => ['flatten'],
                search_from        => ['int'],
                search_size        => ['int'],
                search_type        => SEARCH_TYPE,
                search_types       => ['flatten'],
                search_scroll      => ['string'],
            },
            postfix => '_mlt',
            data    => {
                explain       => ['explain'],
                facets        => ['facets'],
                fields        => ['fields'],
                filter        => ['filter'],
                filterb       => ['filterb'],
                highlight     => ['highlight'],
                indices_boost => ['indices_boost'],
                min_score     => ['min_score'],
                script_fields => ['script_fields'],
                'sort'        => ['sort'],
                track_scores  => ['track_scores'],
            },
            fixup => sub {
                shift()->_to_dsl( { filterb => 'filter' }, $_[0]->{body} );
            },
        },
        @_
    );
}

##################################
## PERCOLATOR
##################################
#===================================
sub create_percolator {
#===================================
    shift()->_do_action(
        'create_percolator',
        {   cmd    => CMD_INDEX_PERC,
            prefix => '_percolator',
            method => 'PUT',
            data   => {
                query  => ['query'],
                queryb => ['queryb'],
                data   => ['data']
            },
            fixup => sub {
                my $self = shift;
                my $args = shift;
                $self->_to_dsl( { queryb => 'query' }, $args->{body} );
                die('create_percolator() requires either the query or queryb param'
                ) unless $args->{body}{query};
                die 'The "data" param cannot include a "query" key'
                    if $args->{body}{data}{query};
                $args->{body} = {
                    query => $args->{body}{query},
                    %{ $args->{body}{data} }
                };
            },
        },
        @_
    );
}

#===================================
sub delete_percolator {
#===================================
    shift()->_do_action(
        'delete_percolator',
        {   cmd    => CMD_INDEX_PERC,
            prefix => '_percolator',
            method => 'DELETE',
            qs     => { ignore_missing => [ 'boolean', 1 ], }
        },
        @_
    );
}

#===================================
sub get_percolator {
#===================================
    shift()->_do_action(
        'get_percolator',
        {   cmd          => CMD_INDEX_PERC,
            prefix       => '_percolator',
            method       => 'GET',
            qs           => { ignore_missing => [ 'boolean', 1 ], },
            post_process => sub {
                my $result = shift;
                return $result
                    unless ref $result eq 'HASH';
                return {
                    index      => $result->{_type},
                    percolator => $result->{_id},
                    query      => delete $result->{_source}{query},
                    data       => $result->{_source},
                };
            },
        },
        @_
    );
}

#===================================
sub percolate {
#===================================
    shift()->_do_action(
        'percolate',
        {   cmd     => CMD_INDEX_TYPE,
            postfix => '_percolate',
            method  => 'GET',
            qs      => { prefer_local => [ 'boolean', undef, 0 ] },
            data    => { doc => 'doc', query => ['query'] },
        },
        @_
    );
}

##################################
## INDEX ADMIN
##################################

#===================================
sub index_status {
#===================================
    shift()->_do_action(
        'index_status',
        {   cmd     => CMD_index,
            postfix => '_status',
            qs      => {
                recovery       => [ 'boolean', 1 ],
                snapshot       => [ 'boolean', 1 ],
                ignore_indices => IGNORE_INDICES,
            },
        },
        @_
    );
}

#===================================
sub index_stats {
#===================================
    shift()->_do_action(
        'index_stats',
        {   cmd     => CMD_index,
            postfix => '_stats',
            qs      => {
                docs     => [ 'boolean', 1, 0 ],
                store    => [ 'boolean', 1, 0 ],
                indexing => [ 'boolean', 1, 0 ],
                get      => [ 'boolean', 1, 0 ],
                search   => [ 'boolean', 1, 0 ],
                clear    => [ 'boolean', 1 ],
                all      => [ 'boolean', 1 ],
                merge    => [ 'boolean', 1 ],
                flush    => [ 'boolean', 1 ],
                refresh  => [ 'boolean', 1 ],
                types    => ['flatten'],
                groups   => ['flatten'],
                level => [ 'enum', [qw(shards)] ],
                ignore_indices => IGNORE_INDICES,
            },
        },
        @_
    );
}

#===================================
sub index_segments {
#===================================
    shift()->_do_action(
        'index_segments',
        {   cmd     => CMD_index,
            postfix => '_segments',
            qs      => { ignore_indices => IGNORE_INDICES, }
        },
        @_
    );
}

#===================================
sub create_index {
#===================================
    shift()->_do_action(
        'create_index',
        {   method  => 'PUT',
            cmd     => CMD_INDEX,
            postfix => '',
            data    => {
                settings => ['settings'],
                mappings => ['mappings'],
                warmers  => ['warmers'],
            },
            fixup => \&_warmer_fixup
        },
        @_
    );
}

#===================================
sub delete_index {
#===================================
    shift()->_do_action(
        'delete_index',
        {   method  => 'DELETE',
            cmd     => CMD_INDICES,
            qs      => { ignore_missing => [ 'boolean', 1 ], },
            postfix => ''
        },
        @_
    );
}

#===================================
sub index_exists {
#===================================
    shift()->_do_action(
        'index_exists',
        {   method       => 'HEAD',
            cmd          => CMD_index,
            fixup        => sub { $_[1]->{qs}{ignore_missing} = 1 },
            post_process => sub { $_[0] ? { ok => 1 } : undef },
        },
        @_
    );
}

#===================================
sub open_index {
#===================================
    shift()->_do_action(
        'open_index',
        {   method  => 'POST',
            cmd     => CMD_INDEX,
            postfix => '_open'
        },
        @_
    );
}

#===================================
sub close_index {
#===================================
    shift()->_do_action(
        'close_index',
        {   method  => 'POST',
            cmd     => CMD_INDEX,
            postfix => '_close'
        },
        @_
    );
}

#===================================
sub aliases {
#===================================
    my ( $self, $params ) = parse_params(@_);
    my $actions = $params->{actions};
    if ( defined $actions && ref $actions ne 'ARRAY' ) {
        $params->{actions} = [$actions];
    }

    $self->_do_action(
        'aliases',
        {   prefix => '_aliases',
            method => 'POST',
            cmd    => [],
            data   => { actions => 'actions' },
            fixup  => sub {
                my $self    = shift;
                my $args    = shift;
                my @actions = @{ $args->{body}{actions} };
                for (@actions) {
                    my ( $key, $value ) = %$_;
                    $value = {%$value};
                    $self->_to_dsl( { filterb => 'filter' }, $value );
                    $_ = { $key => $value };
                }
                $args->{body}{actions} = \@actions;
            },
        },
        $params
    );
}

#===================================
sub get_aliases {
#===================================
    shift->_do_action(
        'aliases',
        {   postfix => '_aliases',
            cmd     => CMD_index,
            qs      => { ignore_missing => [ 'boolean', 1 ] },
        },
        @_
    );
}

#===================================
sub create_warmer {
#===================================
    shift()->_do_action(
        'create_warmer',
        {   method  => 'PUT',
            cmd     => CMD_index_type,
            postfix => '_warmer/',
            data    => {
                warmer        => 'warmer',
                facets        => ['facets'],
                filter        => ['filter'],
                filterb       => ['filterb'],
                script_fields => ['script_fields'],
                'sort'        => ['sort'],
                query         => ['query'],
                queryb        => ['queryb'],
            },
            fixup => sub {
                my ( $self, $args ) = @_;
                $args->{path} .= delete $args->{body}{warmer};
                $self->_data_fixup( $args->{body} );
            },
        },
        @_
    );
}

#===================================
sub warmer {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{warmer} = '*'
        unless defined $params->{warmer} and length $params->{warmer};

    $self->_do_action(
        'warmer',
        {   method  => 'GET',
            cmd     => CMD_indices,
            postfix => '_warmer/',
            data    => { warmer => ['warmer'] },
            qs      => { ignore_missing => [ 'boolean', 1 ] },
            fixup   => sub {
                my ( $self, $args ) = @_;
                $args->{path} .= delete $args->{body}{warmer};
            },
        },
        $params
    );
}

#===================================
sub delete_warmer {
#===================================
    shift()->_do_action(
        'delete_warmer',
        {   method  => 'DELETE',
            cmd     => CMD_INDICES,
            postfix => '_warmer/',
            data    => { warmer => 'warmer' },
            qs      => { ignore_missing => [ 'boolean', 1 ] },
            fixup   => sub {
                my ( $self, $args ) = @_;
                $args->{path} .= delete $args->{body}{warmer};
            },
        },
        @_
    );
}

#===================================
sub create_index_template {
#===================================
    shift()->_do_action(
        'create_index_template',
        {   method => 'PUT',
            cmd    => CMD_NAME,
            prefix => '_template',
            data   => {
                template => 'template',
                settings => ['settings'],
                mappings => ['mappings'],
                warmers  => ['warmers'],
                order    => ['order'],
            },
            fixup => \&_warmer_fixup
        },
        @_
    );
}

#===================================
sub delete_index_template {
#===================================
    shift()->_do_action(
        'delete_index_template',
        {   method => 'DELETE',
            cmd    => CMD_NAME,
            prefix => '_template',
            qs     => { ignore_missing => [ 'boolean', 1 ] },
        },
        @_
    );
}

#===================================
sub index_template {
#===================================
    shift()->_do_action(
        'index_template',
        {   method => 'GET',
            cmd    => CMD_NAME,
            prefix => '_template',
        },
        @_
    );
}

#===================================
sub flush_index {
#===================================
    shift()->_do_action(
        'flush_index',
        {   method  => 'POST',
            cmd     => CMD_index,
            postfix => '_flush',
            qs      => {
                refresh        => [ 'boolean', 1 ],
                full           => [ 'boolean', 1 ],
                ignore_indices => IGNORE_INDICES,
            },
        },
        @_
    );
}

#===================================
sub refresh_index {
#===================================
    shift()->_do_action(
        'refresh_index',
        {   method  => 'POST',
            cmd     => CMD_index,
            postfix => '_refresh',
            qs      => { ignore_indices => IGNORE_INDICES, }
        },
        @_
    );
}

#===================================
sub optimize_index {
#===================================
    shift()->_do_action(
        'optimize_index',
        {   method  => 'POST',
            cmd     => CMD_index,
            postfix => '_optimize',
            qs      => {
                only_deletes =>
                    [ 'boolean', [ only_expunge_deletes => 'true' ] ],
                max_num_segments => ['int'],
                refresh          => [ 'boolean', undef, 0 ],
                flush            => [ 'boolean', undef, 0 ],
                wait_for_merge   => [ 'boolean', undef, 0 ],
                ignore_indices   => IGNORE_INDICES,
            },
        },
        @_
    );
}

#===================================
sub snapshot_index {
#===================================
    shift()->_do_action(
        'snapshot_index',
        {   method  => 'POST',
            cmd     => CMD_index,
            postfix => '_gateway/snapshot',
            qs      => { ignore_indices => IGNORE_INDICES, }
        },
        @_
    );
}

#===================================
sub gateway_snapshot {
#===================================
    shift()->_do_action(
        'gateway_snapshot',
        {   method  => 'POST',
            cmd     => CMD_index,
            postfix => '_gateway/snapshot'
        },
        @_
    );
}

#===================================
sub put_mapping {
#===================================
    my ( $self, $params ) = parse_params(@_);
    my %defn = (
        data       => { mapping => 'mapping' },
        deprecated => {
            dynamic           => ['dynamic'],
            dynamic_templates => ['dynamic_templates'],
            properties        => ['properties'],
            _all              => ['_all'],
            _analyzer         => ['_analyzer'],
            _boost            => ['_boost'],
            _id               => ['_id'],
            _index            => ['_index'],
            _meta             => ['_meta'],
            _parent           => ['_parent'],
            _routing          => ['_routing'],
            _source           => ['_source'],
        },
    );

    $defn{deprecated}{mapping} = undef
        if !$params->{mapping} && grep { exists $params->{$_} }
        keys %{ $defn{deprecated} };

    my $type = $params->{type} || $self->{_default}{type};
    $self->_do_action(
        'put_mapping',
        {   method  => 'PUT',
            cmd     => CMD_index_TYPE,
            postfix => '_mapping',
            qs      => { ignore_conflicts => [ 'boolean', 1 ] },
            %defn,
            fixup => sub {
                my $args = $_[1];
                my $mapping = $args->{body}{mapping} || $args->{body};
                $args->{body} = { $type => $mapping };
            },
        },
        $params
    );
}

#===================================
sub delete_mapping {
#===================================
    my ( $self, $params ) = parse_params(@_);

    $self->_do_action(
        'delete_mapping',
        {   method => 'DELETE',
            cmd    => CMD_INDICES_TYPE,
            qs     => { ignore_missing => [ 'boolean', 1 ], }
        },
        $params
    );
}

#===================================
sub mapping {
#===================================
    my ( $self, $params ) = parse_params(@_);

    $self->_do_action(
        'mapping',
        {   method  => 'GET',
            cmd     => CMD_index_type,
            postfix => '_mapping',
            qs      => { ignore_missing => [ 'boolean', 1 ], }
        },
        $params
    );
}

#===================================
sub type_exists {
#===================================
    shift()->_do_action(
        'type_exists',
        {   method       => 'HEAD',
            cmd          => CMD_index_types,
            qs           => { ignore_indices => IGNORE_INDICES, },
            fixup        => sub { $_[1]->{qs}{ignore_missing} = 1 },
            post_process => sub { $_[0] ? { ok => 1 } : undef },
        },
        @_
    );
}

#===================================
sub clear_cache {
#===================================
    shift()->_do_action(
        'clear_cache',
        {   method  => 'POST',
            cmd     => CMD_index,
            postfix => '_cache/clear',
            qs      => {
                id             => [ 'boolean', 1 ],
                filter         => [ 'boolean', 1 ],
                field_data     => [ 'boolean', 1 ],
                bloom          => [ 'boolean', 1 ],
                fields         => ['flatten'],
                ignore_indices => IGNORE_INDICES,
            }
        },
        @_
    );
}

#===================================
sub index_settings {
#===================================
    my ( $self, $params ) = parse_params(@_);

    $self->_do_action(
        'index_settings',
        {   method  => 'GET',
            cmd     => CMD_index,
            postfix => '_settings'
        },
        $params
    );
}

#===================================
sub update_index_settings {
#===================================
    my ( $self, $params ) = parse_params(@_);

    $self->_do_action(
        'update_index_settings',
        {   method  => 'PUT',
            cmd     => CMD_index,
            postfix => '_settings',
            data    => { index => 'settings' }
        },
        $params
    );
}

##################################
## RIVER MANAGEMENT
##################################

#===================================
sub create_river {
#===================================
    my ( $self, $params ) = parse_params(@_);
    my $type = $params->{type}
        or throw( 'Param', 'No river type specified', $params );
    my $data = { type => 'type', index => ['index'], $type => [$type] };
    $self->_do_action(
        'create_river',
        {   method  => 'PUT',
            prefix  => '_river',
            cmd     => CMD_RIVER,
            postfix => '_meta',
            data    => $data
        },
        $params
    );
}

#===================================
sub get_river {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $self->_do_action(
        'get_river',
        {   method  => 'GET',
            prefix  => '_river',
            cmd     => CMD_RIVER,
            postfix => '_meta',
            qs      => { ignore_missing => [ 'boolean', 1 ] }
        },
        $params
    );
}

#===================================
sub delete_river {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $self->_do_action(
        'delete_river',
        {   method => 'DELETE',
            prefix => '_river',
            cmd    => CMD_RIVER,
        },
        $params
    );
}

#===================================
sub river_status {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $self->_do_action(
        'river_status',
        {   method  => 'GET',
            prefix  => '_river',
            cmd     => CMD_RIVER,
            postfix => '_status',
            qs      => { ignore_missing => [ 'boolean', 1 ] }
        },
        $params
    );
}

##################################
## CLUSTER MANAGEMENT
##################################

#===================================
sub cluster_state {
#===================================
    shift()->_do_action(
        'cluster_state',
        {   prefix => '_cluster/state',
            qs     => {
                filter_blocks        => [ 'boolean', 1 ],
                filter_nodes         => [ 'boolean', 1 ],
                filter_metadata      => [ 'boolean', 1 ],
                filter_routing_table => [ 'boolean', 1 ],
                filter_indices       => ['flatten'],
                }

        },
        @_
    );
}

#===================================
sub current_server_version {
#===================================
    shift()->_do_action(
        'current_server_version',
        {   cmd          => CMD_NONE,
            prefix       => '',
            post_process => sub {
                return shift->{version};
            },
        }
    );
}

#===================================
sub nodes {
#===================================
    shift()->_do_action(
        'nodes',
        {   prefix => '_cluster/nodes',
            cmd    => CMD_nodes,
            qs     => {
                settings    => [ 'boolean', 1 ],
                http        => [ 'boolean', 1 ],
                jvm         => [ 'boolean', 1 ],
                network     => [ 'boolean', 1 ],
                os          => [ 'boolean', 1 ],
                process     => [ 'boolean', 1 ],
                thread_pool => [ 'boolean', 1 ],
                transport   => [ 'boolean', 1 ],
            },
        },
        @_
    );
}

#===================================
sub nodes_stats {
#===================================
    shift()->_do_action(
        'nodes',
        {   prefix  => '_cluster/nodes',
            postfix => 'stats',
            cmd     => CMD_nodes,
            qs      => {
                indices     => [ 'boolean', 1, 0 ],
                clear       => [ 'boolean', 1 ],
                all         => [ 'boolean', 1 ],
                fs          => [ 'boolean', 1 ],
                http        => [ 'boolean', 1 ],
                jvm         => [ 'boolean', 1 ],
                network     => [ 'boolean', 1 ],
                os          => [ 'boolean', 1 ],
                process     => [ 'boolean', 1 ],
                thread_pool => [ 'boolean', 1 ],
                transport   => [ 'boolean', 1 ],
            },
        },
        @_
    );
}

#===================================
sub shutdown {
#===================================
    shift()->_do_action(
        'shutdown',
        {   method  => 'POST',
            prefix  => '_cluster/nodes',
            cmd     => CMD_nodes,
            postfix => '_shutdown',
            qs      => { delay => ['duration'] }
        },
        @_
    );
}

#===================================
sub restart {
#===================================
    shift()->_do_action(
        'shutdown',
        {   method  => 'POST',
            prefix  => '_cluster/nodes',
            cmd     => CMD_nodes,
            postfix => '_restart',
            qs      => { delay => ['duration'] }
        },
        @_
    );
}

#===================================
sub cluster_health {
#===================================
    shift()->_do_action(
        'cluster_health',
        {   prefix => '_cluster/health',
            cmd    => CMD_index,
            qs     => {
                level           => [ 'enum', [qw(cluster indices shards)] ],
                wait_for_status => [ 'enum', [qw(green yellow red)] ],
                wait_for_relocating_shards => ['int'],
                wait_for_nodes             => ['string'],
                timeout                    => ['duration']
            }
        },
        @_
    );
}

#===================================
sub cluster_settings {
#===================================
    my ( $self, $params ) = parse_params(@_);

    $self->_do_action(
        'cluster_settings',
        {   method  => 'GET',
            cmd     => CMD_NONE,
            postfix => '_cluster/settings'
        },
        $params
    );
}

#===================================
sub update_cluster_settings {
#===================================
    my ( $self, $params ) = parse_params(@_);

    $self->_do_action(
        'update_cluster_settings',
        {   method  => 'PUT',
            cmd     => CMD_NONE,
            postfix => '_cluster/settings',
            data    => {
                persistent => ['persistent'],
                transient  => ['transient']
            }
        },
        $params
    );
}

#===================================
sub cluster_reroute {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{commands} = [ $params->{commands} ]
        if $params->{commands} and ref( $params->{commands} ) ne 'ARRAY';

    $self->_do_action(
        'cluster_reroute',
        {   prefix => '_cluster/reroute',
            cmd    => [],
            method => 'POST',
            data   => { commands => ['commands'] },
            qs     => { dry_run => [ 'boolean', 1 ], },
        },
        $params
    );
}

##################################
## FLAGS
##################################

#===================================
sub camel_case {
#===================================
    my $self = shift;
    if (@_) {
        if ( shift() ) {
            $self->{_base_qs}{case} = 'camelCase';
        }
        else {
            delete $self->{_base_qs}{case};
        }
    }
    return $self->{_base_qs}{case} ? 1 : 0;
}

#===================================
sub error_trace {
#===================================
    my $self = shift;
    if (@_) {
        if ( shift() ) {
            $self->{_base_qs}{error_trace} = 'true';
        }
        else {
            delete $self->{_base_qs}{error_trace};
        }
    }
    return $self->{_base_qs}{error_trace} ? 1 : 0;
}

##################################
## INTERNAL
##################################

#===================================
sub parse_request { shift->_doc_action(@_) }
#===================================

#===================================
sub _do_action {
#===================================
    my $self            = shift;
    my $action          = shift || '';
    my $defn            = shift || {};
    my $original_params = ref $_[0] eq 'HASH' ? { %{ shift() } } : {@_};

    my $error;

    my $params = {%$original_params};
    my %args = ( method => $defn->{method} || 'GET' );
    $args{as_json} = delete $params->{as_json};

    eval {
        $args{path}
            = $self->_build_cmd( $params, @{$defn}{qw(prefix cmd postfix)} );
        $args{qs} = $self->_build_qs( $params, $defn->{qs} );
        $args{body}
            = $self->_build_data( $params, @{$defn}{ 'data', 'deprecated' } );
        $args{ignore} = 404 if delete $args{qs}{ignore_missing};
        if ( my $fixup = $defn->{fixup} ) {
            $fixup->( $self, \%args );
        }
        die "Unknown parameters: " . join( ', ', keys %$params ) . "\n"
            if keys %$params;
        1;
    } or $error = $@ || 'Unknown error';

    $args{post_process} = $defn->{post_process};
    if ($error) {
        die $error if ref $error;
        throw(
            'Param',
            $error . $self->_usage( $action, $defn ),
            { params => $original_params }
        );
    }
    if ( my $skip = $args{skip} ) {
        return $self->_skip_request( $args{as_json}, $skip );
    }
    $args{serialize} ||= 'std';
    $args{mime_type} = 'application/json';
    $self->request( \%args );
}

#===================================
sub _skip_request {
#===================================
    my $self    = shift;
    my $as_json = shift;
    my $result  = shift;
    return $result unless $as_json;
    return $self->JSON->encode($result);
}

#===================================
sub _usage {
#===================================
    my $self   = shift;
    my $action = shift;
    my $defn   = shift;

    my $usage = "Usage for '$action()':\n";
    my @cmd = @{ $defn->{cmd} || [] };
    while ( my $key = shift @cmd ) {
        my $type = shift @cmd;
        my $arg_format
            = $type == ONE_REQ ? "\$$key"
            : $type == ONE_OPT ? "\$$key"
            :                    "\$$key | [\$${key}_1,\$${key}_n]";

        my $required
            = ( $type == ONE_REQ or $type == MULTI_REQ )
            ? 'required'
            : 'optional';
        $usage .= sprintf( "  - %-26s =>  %-45s # %s\n",
            $key, $arg_format, $required );
    }

    if ( my $data = $defn->{body} ) {
        my @keys = sort { $a->[0] cmp $b->[0] }
            map { ref $_ ? [ $_->[0], 'optional' ] : [ $_, 'required' ] }
            values %$data;

        for (@keys) {
            $usage .= sprintf(
                "  - %-26s =>  %-45s # %s\n",
                $_->[0], '{' . $_->[0] . '}',
                $_->[1]
            );
        }
    }

    if ( my $qs = $defn->{qs} ) {
        for ( sort keys %$qs ) {
            my $arg_format = $QS_Format{ $qs->{$_}[0] };
            my @extra;
            $arg_format = $arg_format->( $_, $qs->{$_} )
                if ref $arg_format;
            if ( length($arg_format) > 45 ) {
                ( $arg_format, @extra ) = split / [|] /, $arg_format;
            }
            $usage .= sprintf( "  - %-26s =>  %-45s # optional\n", $_,
                $arg_format );
            $usage .= ( ' ' x 34 ) . " | $_\n" for @extra;
        }
    }

    return $usage;
}

#===================================
sub _build_qs {
#===================================
    my $self   = shift;
    my $params = shift;
    my $defn   = shift || {};
    my %qs     = %{ $self->{_base_qs} };
    foreach my $key ( keys %$defn ) {
        my ( $format_name, @args ) = @{ $defn->{$key} || [] };
        $format_name ||= '';

        next unless exists $params->{$key};

        my $formatter = $QS_Formatter{$format_name}
            or die "Unknown QS formatter '$format_name'";

        my $val = $formatter->( $key, delete $params->{$key}, @args )
            or next;
        $qs{ $val->[0] } = $val->[1];
    }
    return \%qs;
}

#===================================
sub _build_data {
#===================================
    my $self   = shift;
    my $params = shift;
    my $defn   = shift or return;

    if ( my $deprecated = shift ) {
        $defn = { %$defn, %$deprecated };
    }

    my %data;
KEY: while ( my ( $key, $source ) = each %$defn ) {
        next unless defined $source;
        if ( ref $source eq 'ARRAY' ) {
            foreach (@$source) {
                my $val = delete $params->{$_};
                next unless defined $val;
                $data{$key} = $val;
                next KEY;
            }
        }
        else {
            $data{$key} = delete $params->{$source}
                or die "Missing required param '$source'\n";
        }
    }
    return \%data;
}

#===================================
sub _build_cmd {
#===================================
    my $self   = shift;
    my $params = shift;
    my ( $prefix, $defn, $postfix ) = @_;

    my @defn = ( @{ $defn || [] } );
    my @cmd;
    while (@defn) {
        my $key  = shift @defn;
        my $type = shift @defn;

        my $val
            = exists $params->{$key}
            ? delete $params->{$key}
            : $self->{_default}{$key};

        $val = '' unless defined $val;

        if ( ref $val eq 'ARRAY' ) {
            die "'$key' must be a single value\n"
                if $type <= ONE_ALL;
            $val = join ',', @$val;
        }
        unless ( length $val ) {
            next if $type == ONE_OPT || $type == MULTI_BLANK;
            die "Param '$key' is required\n"
                if $type == ONE_REQ || $type == MULTI_REQ;
            $val = '_all';
        }
        push @cmd, uri_escape($val);
    }

    return join '/', '', grep {defined} ( $prefix, @cmd, $postfix );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::Compat - The client compatibility layer for migrating from ElasticSearch.pm

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use ElasticSearch::Compat;
    my $es = ElasticSearch::Compat->new(
        servers      => 'search.foo.com:9200',  # default '127.0.0.1:9200'
        transport    => 'http'                  # default 'http'
                        | 'httptiny',
        trace_calls  => 'log_file',
        no_refresh   => 0 | 1,
    );

    $es->index(
        index => 'twitter',
        type  => 'tweet',
        id    => 1,
        data  => {
            user        => 'kimchy',
            post_date   => '2009-11-15T14:12:12',
            message     => 'trying out Elastic Search'
        }
    );

    $data = $es->get(
        index => 'twitter',
        type  => 'tweet',
        id    => 1
    );

    # native elasticsearch query language
    $results = $es->search(
        index => 'twitter',
        type  => 'tweet',
        query => {
            text => { user => 'kimchy' }
        }
    );

    # ElasticSearch::SearchBuilder Perlish query language
    $results = $es->search(
        index  => 'twitter',
        type   => 'tweet',
        queryb => {
            message   => 'Perl API',
            user      => 'kimchy',
            post_date => {
                '>'   => '2010-01-01',
                '<='  => '2011-01-01',
            }
        }
    );


    $dodgy_qs = "foo AND AND bar";
    $results = $es->search(
        index => 'twitter',
        type  => 'tweet',
        query => {
            query_string => {
                query => $es->query_parser->filter($dodgy_qs)
            },
        }
    );

=head1 DESCRIPTION

See L<Search::Elasticsearch::Compat> for an explanation of why this module exists.

=head1 CALLING CONVENTIONS

I've tried to follow the same terminology as used in the Elasticsearch docs
when naming methods, so it should be easy to tie the two together.

Some methods require a specific C<index> and a specific C<type>, while others
allow a list of indices or types, or allow you to specify all indices or
types. I distinguish between them as follows:

   $es->method( index => multi, type => single, ...)

C<single> values must be a scalar, and are required parameters

      type  => 'tweet'

C<multi> values can be:

      index   => 'twitter'          # specific index
      index   => ['twitter','user'] # list of indices
      index   => undef              # (or not specified) = all indices

C<multi_req> values work like C<multi> values, but at least one value is
required, so:

      index   => 'twitter'          # specific index
      index   => ['twitter','user'] # list of indices
      index   => '_all'             # all indices

      index   => []                 # error
      index   => undef              # error

Also, see L</"use_index()/use_type()">.

=head2 as_json

If you pass C<< as_json => 1 >> to any request to the Elasticsearch server,
it will return the raw UTF8-decoded JSON response, rather than a Perl
datastructure.

=head1 RETURN VALUES AND EXCEPTIONS

Methods that query the Elasticsearch cluster return the raw data structure
that the cluster returns.  This may change in the future, but as these
data structures are still in flux, I thought it safer not to try to interpret.

Anything that is known to be an error throws an exception, eg trying to delete
a non-existent index.

=head1 INTEGRATION WITH ElasticSearch::SearchBuilder

L<ElasticSearch::SearchBuilder> provides a concise Perlish
L<SQL::Abstract>-style query language, which gets translated into the native
L<Query DSL|http://www.elasticsearch.org/guide/reference/query-dsl> that
Elasticsearch uses.

For instance:

    {
        content => 'search keywords',
        -filter => {
            tags        => ['perl','ruby'],
            date        => {
                '>'     => '2010-01-01',
                '<='    => '2011-01-01'
            },
        }
    }

Would be translated to:

    { query => {
        filtered => {
            query  => { text => { content => "search keywords" } },
            filter => {
                and => [
                    { terms => { tags => ["perl", "ruby"] } },
                    { numeric_range => {
                        date => {
                            gt => "2010-01-01",
                            lte => "2011-01-01"
                    }}},
                ],
            }
    }}}

All you have to do to start using L<ElasticSearch::SearchBuilder> is to change
your C<query> or C<filter> parameter to C<queryb> or C<filterb> (where the
extra C<b> stands for C<builder>):

    $es->search(
        queryb => { content => 'keywords' }
    )

If you want to see what your SearchBuilder-style query is being converted into,
you can either use L</"trace_calls()"> or access it directly with:

    $native_query  = $es->builder->query( $query )
    $native_filter = $es->builder->filter( $filter )

See the L<ElasticSearch::SearchBuilder> docs for more information about
the syntax.

=head1 METHODS

=head2 Document-indexing methods

=head3 index()

    $result = $es->index(
        index       => single,
        type        => single,
        id          => $document_id,        # optional, otherwise auto-generated
        data        => {
            key => value,
            ...
        },

        # optional
        consistency  => 'quorum' | 'one' | 'all',
        create       => 0 | 1,
        parent       => $parent,
        percolate    => $percolate,
        refresh      => 0 | 1,
        replication  => 'sync' | 'async',
        routing      => $routing,
        timeout      => eg '1m' or '10s'
        version      => int,
        version_type => 'internal' | 'external',
    );

eg:

    $result = $es->index(
        index   => 'twitter',
        type    => 'tweet',
        id      => 1,
        data    => {
            user        => 'kimchy',
            post_date   => '2009-11-15T14:12:12',
            message     => 'trying out Elastic Search'
        },
    );

Used to add a document to a specific C<index> as a specific C<type> with
a specific C<id>. If the C<index/type/id> combination already exists,
then that document is updated, otherwise it is created.

Note:

=over

=item *

If the C<id> is not specified, then Elasticsearch autogenerates a unique
ID and a new document is always created.

=item *

If C<version> is passed, and the current version in Elasticsearch is
different, then a C<Conflict> error will be thrown.

=item *

C<data> can also be a raw JSON encoded string (but ensure that it is correctly
encoded, otherwise you see errors when trying to retrieve it from Elasticsearch).

    $es->index(
        index   => 'foo',
        type    =>  'bar',
        id      =>  1,
        data    =>  '{"foo":"bar"}'
    );

=item *

C<timeout> for all CRUD methods and L</"search()"> is a query timeout,
specifying the amount of time Elasticsearch will spend (roughly) processing a
query. Units can be concatenated with the integer value, e.g., C<500ms> or
C<1s>.

See also: L<http://www.elasticsearch.org/guide/reference/api/search/request-body.html>

Note: this is distinct from the transport timeout, see L</"timeout()">.

=back

See also: L<http://www.elasticsearch.org/guide/reference/api/index_.html>,
L</"bulk()"> and L</"put_mapping()">

=head3 set()

C<set()> is a synonym for L</"index()">

=head3 create()

    $result = $es->create(
        index       => single,
        type        => single,
        id          => $document_id,        # optional, otherwise auto-generated
        data        => {
            key => value,
            ...
        },

        # optional
        consistency  => 'quorum' | 'one' | 'all',
        parent       => $parent,
        percolate    => $percolate,
        refresh      => 0 | 1,
        replication  => 'sync' | 'async',
        routing      => $routing,
        timeout      => eg '1m' or '10s',
        version      => int,
        version_type => 'internal' | 'external',
    );

eg:

    $result = $es->create(
        index   => 'twitter',
        type    => 'tweet',
        id      => 1,
        data    => {
            user        => 'kimchy',
            post_date   => '2009-11-15T14:12:12',
            message     => 'trying out Elastic Search'
        },
    );

Used to add a NEW document to a specific C<index> as a specific C<type> with
a specific C<id>. If the C<index/type/id> combination already exists,
then a C<Conflict> error is thrown.

If the C<id> is not specified, then Elasticsearch autogenerates a unique
ID.

If you pass a C<version> parameter to C<create>, then it must be C<0> unless
you also set C<version_type> to C<external>.

See also: L</"index()">

=head3 update()

    $result = $es->update(
        index             => single,
        type              => single,
        id                => single,

        # required
        script            => $script,
      | doc               => $doc

        # optional
        params            => { params },
        upsert            => { new_doc },
        consistency       => 'quorum' | 'one' | 'all',
        fields            => ['_source'],
        ignore_missing    => 0 | 1,
        parent            => $parent,
        percolate         => $percolate,
        retry_on_conflict => 2,
        routing           => $routing,
        timeout           => '10s',
        replication       => 'sync' | 'async'
    )

The C<update()> method accepts a C<script> to update, or a C<doc> to be merged
with, an existing doc, without having to retrieve and reindex the doc yourself,
eg:

    $es->update(
        index   => 'test',
        type    => 'foo',
        id      => 123,
        script  => 'ctx._source.tags+=[tag]',
        params  => { tag => 'red' }
    );

You can also pass a new doc which will be inserted if the doc does not
already exist, via the C<upsert> paramater.

See L<http://www.elasticsearch.org/guide/reference/api/update.html> for more.

=head3 get()

    $result = $es->get(
        index   => single,
        type    => single or blank,
        id      => single,

        # optional
        fields          => 'field' or ['field1',...]
        preference      => '_local' | '_primary' | '_primary_first' | $string,
        refresh         => 0 | 1,
        routing         => $routing,
        parent          => $parent,
        ignore_missing  => 0 | 1,

    );

Returns the document stored at C<index/type/id> or throws an exception if
the document doesn't exist.

Example:

    $es->get( index => 'twitter', type => 'tweet', id => 1)

Returns:

    {
      _id     => 1,
      _index  => "twitter",
      _source => {
                   message => "trying out Elastic Search",
                   post_date=> "2009-11-15T14:12:12",
                   user => "kimchy",
                 },
      _type   => "tweet",
    }

By default the C<_source> field is returned.  Use C<fields> to specify
a list of (stored) fields to return instead, or C<[]> to return no fields.

Pass a true value for C<refresh> to force an index refresh before performing
the get.

If the requested C<index>, C<type> or C<id> is not found, then a C<Missing>
exception is thrown, unless C<ignore_missing> is true.

See also: L</"bulk()">, L<http://www.elasticsearch.org/guide/reference/api/get.html>

=head3 exists()

    $bool = $es->exists(
        index           => single,
        type            => single,
        id              => single,

        preference      => '_local' | '_primary' | '_primary_first' | $string,
        refresh         => 0 | 1,
        routing         => $routing,
        parent          => $parent,
    );

Returns true or false depending on whether the doc exists.

=head3 mget()

    $docs = $es->mget(
        index          => single,
        type           => single or blank,
        ids            => \@ids,
        fields         => ['field_1','field_2'],
        filter_missing => 0 | 1
    );

    $docs = $es->mget(
        index          => single or blank,
        type           => single or blank,
        docs           => \@doc_info,
        fields         => ['field_1','field_2'],
        filter_missing => 0 | 1
    );

C<mget> or "multi-get" returns multiple documents at once. There are two
ways to call C<mget()>:

If all docs come from the same index (and potentially the same type):

    $docs = $es->mget(
        index => 'myindex',
        type  => 'mytype',   # optional
        ids   => [1,2,3],
    )

Alternatively you can specify each doc separately:

    $docs = $es->mget(
        docs => [
            { _index => 'index_1', _type => 'type_1', _id => 1 },
            { _index => 'index_2', _type => 'type_2', _id => 2 },
        ]
    )

Or:

    $docs = $es->mget(
        index  => 'myindex',                    # default index
        type   => 'mytype',                     # default type
        fields => ['field_1','field_2'],        # default fields
        docs => [
            { _id => 1 },                       # uses defaults
            { _index => 'index_2',
              _type  => 'type_2',
              _id    => 2,
              fields => ['field_2','field_3'],
            },
        ]
    );

If C<$docs> or C<$ids> is an empty array ref, then C<mget()> will just return
an empty array ref.

Returns an array ref containing all of the documents requested.  If a document
is not found, then its entry will include C<< {exists => 0} >>. If you would
rather filter these missing docs, pass C<< filter_missing => 1 >>.

See L<http://www.elasticsearch.org/guide/reference/api/multi-get.html>

=head3 delete()

    $result = $es->delete(
        index           => single,
        type            => single,
        id              => single,

        # optional
        consistency     => 'quorum' | 'one' | 'all'
        ignore_missing  => 0 | 1
        refresh         => 0 | 1
        parent          => $parent,
        routing         => $routing,
        replication     => 'sync' | 'async'
        version         => int
    );

Deletes the document stored at C<index/type/id> or throws an C<Missing>
exception if the document doesn't exist and C<ignore_missing> is not true.

If you specify a C<version> and the current version of the document is
different (or if the document is not found), a C<Conflict> error will
be thrown.

If C<refresh> is true, an index refresh will be forced after the delete has
completed.

Example:

    $es->delete( index => 'twitter', type => 'tweet', id => 1);

See also: L</"bulk()">,
L<http://www.elasticsearch.org/guide/reference/api/delete.html>

=head3 bulk()

    $result = $es->bulk( [ actions ] )

    $result = $es->bulk(
        actions     => [ actions ]                  # required

        index       => 'foo',                       # optional
        type        => 'bar',                       # optional
        consistency => 'quorum' |  'one' | 'all'    # optional
        refresh     => 0 | 1,                       # optional
        replication => 'sync' | 'async',            # optional

        on_conflict => sub {...} | 'IGNORE'         # optional
        on_error    => sub {...} | 'IGNORE'         # optional
    );

Perform multiple C<index>, C<create> and C<delete> actions in a single request.
This is about 10x as fast as performing each action in a separate request.

Each C<action> is a HASH ref with a key indicating the action type (C<index>,
C<create> or C<delete>), whose value is another HASH ref containing the
associated metadata.

The C<index> and C<type> parameters can be specified for each individual action,
or inherited from the top level C<index> and C<type> parameters, as shown
above.

NOTE: C<bulk()> also accepts the C<_index>, C<_type>, C<_id>, C<_source>,
C<_parent>, C<_routing> and C<_version> parameters so that you can pass search
results directly to C<bulk()>.

=head4 C<index> and C<create> actions

    { index  => {
        index           => 'foo',
        type            => 'bar',
        id              => 123,
        data            => { text => 'foo bar'},

        # optional
        routing         => $routing,
        parent          => $parent,
        percolate       => $percolate,
        timestamp       => $timestamp,
        ttl             => $ttl,
        version         => $version,
        version_type    => 'internal' | 'external'
    }}

    { create  => { ... same options as for 'index' }}

The C<index> and C<type> parameters, if not specified, are inherited from
the top level bulk request.

C<data> can also be a raw JSON encoded string (but ensure that it is correctly
encoded, otherwise you see errors when trying to retrieve it from Elasticsearch).

    actions => [{
        index => {
            index   => 'foo',
            type    =>  'bar',
            id      =>  1,
            data    =>  '{"foo":"bar"}'
        }
    }]

=head4 C<delete> action

    { delete  => {
        index           => 'foo',
        type            => 'bar',
        id              => 123,

        # optional
        routing         => $routing,
        parent          => $parent,
        version         => $version,
        version_type    => 'internal' | 'external'
    }}

The C<index> and C<type> parameters, if not specified, are inherited from
the top level bulk request.

=head4 Error handlers

The C<on_conflict> and C<on_error> parameters accept either a coderef or the
string C<'IGNORE'>.  Normally, any errors are returned under the C<errors>
key (see L</Return values>).

The logic works as follows:

=over

=item *

If the error is a versioning conflict error, or if you try to C<create> a doc
whose ID already exists,  and there is an C<on_conflict>
handler, then call the handler and move on to the next document

=item *

If the error is still unhandled, and we have an C<on_error> handler, then call
it and move on to the next document.

=item *

If no handler exists, then add the error to the C<@errors> array which is
returned by L</bulk()>

=back

Setting C<on_conflict> or C<on_error> to C<'IGNORE'> is the equivalent
of passing an empty no-op handler.

The handler callbacks are called as:

    $handler->( $action, $document, $error, $req_no );

For instance:

=over

=item C<$action>

    "index"

=item C<$document>

    { id => 1, data => { count => "foo" }}

=item C<$error>

    "MapperParsingException[Failed to parse [count]]; ... etc ... "

=item C<$req_no>

    0

=back

The C<$req_no> is the array index of the current C<$action> from the original
array of C<@actions>.

=head4 Return values

The L</"bulk()"> method returns a HASH ref containing:

    {
        actions => [ the list of actions you passed in ],
        results => [ the result of each of the actions ],
        errors  => [ a list of any errors              ]
    }

The C<results> ARRAY ref contains the same values that would be returned
for individiual C<index>/C<create>/C<delete> statements, eg:

    results => [
         { create => { _id => 123, _index => "foo", _type => "bar", _version => 1 } },
         { index  => { _id => 123, _index => "foo", _type => "bar", _version => 2 } },
         { delete => { _id => 123, _index => "foo", _type => "bar", _version => 3 } },
    ]

The C<errors> key is only present if an error has occured and has not been handled
by an C<on_conflict> or C<on_error> handler, so you can do:

    $results = $es->bulk(\@actions);
    if ($results->{errors}) {
        # handle errors
    }

Each error element contains the C<error> message plus the C<action> that
triggered the error.  Each C<result> element will also contain the error
message., eg:

    $result = {
        actions => [

            ## NOTE - num is numeric
            {   index => { index => 'bar', type  => 'bar', id => 123,
                           data  => { num => 123 } } },

            ## NOTE - num is a string
            {   index => { index => 'bar', type  => 'bar', id => 123,
                           data  => { num => 'foo bar' } } },
        ],
        errors => [
            {
                action => {
                    index => { index => 'bar', type  => 'bar', id => 123,
                               data  => { num => 'text foo' } }
                },
                error => "MapperParsingException[Failed to parse [num]]; ...",
            },
        ],
        results => [
            { index => { _id => 123, _index => "bar", _type => "bar", _version => 1 }},
            {   index => {
                    error => "MapperParsingException[Failed to parse [num]];...",
                    id    => 123, index => "bar", type  => "bar",
                },
            },
        ],

    };

See L<http://www.elasticsearch.org/guide/reference/api/bulk.html> for
more details.

=head3 bulk_index(), bulk_create(), bulk_delete()

These are convenience methods which allow you to pass just the metadata, without
the C<index>, C<create> or C<index> action for each record.

These methods accept the same parameters as the L</"bulk()"> method, except
that the C<actions> parameter is replaced by C<docs>, eg:

    $result = $es->bulk_index( [ docs ] );

    $result = $es->bulk_index(
        docs        => [ docs ],                    # required

        index       => 'foo',                       # optional
        type        => 'bar',                       # optional
        consistency => 'quorum' |  'one' | 'all'    # optional
        refresh     => 0 | 1,                       # optional
        replication => 'sync' | 'async',            # optional

        on_conflict => sub {...} | 'IGNORE'         # optional
        on_error    => sub {...} | 'IGNORE'         # optional
    );

For instance:

    $es->bulk_index(
        index   => 'foo',
        type    => 'bar',
        refresh => 1,
        docs    => [
            { id => 123,                data => { text=>'foo'} },
            { id => 124, type => 'baz', data => { text=>'bar'} },
        ]
    );

=head3 reindex()

    $es->reindex(
        source      => $scrolled_search,

        # optional
        bulk_size   => 1000,
        dest_index  => $index,
        quiet       => 0 | 1,
        transform   => sub {....},

        on_conflict => sub {...} | 'IGNORE'
        on_error    => sub {...} | 'IGNORE'
    )

C<reindex()> is a utility method which can be used for reindexing data
from one index to another (eg if the mapping has changed), or copying
data from one cluster to another.

=head4 Params

=over

=item *

C<source> is a required parameter, and should be an instance of
L<Search::Elasticsearch::Compat::ScrolledSearch>.

=item *

C<dest_index> is the name of the destination index, ie where the docs are
indexed to.  If you are indexing your data from one cluster to another,
and you want to use the same index name in your destination cluster, then
you can leave this blank.

=item *

C<bulk_size> - the number of docs that will be indexed at a time. Defaults
to 1,000

=item *

Set C<quiet> to C<1> if you don't want any progress information to be
printed to C<STDOUT>

=item *

C<transform> should be a sub-ref which will be called for each doc, allowing
you to transform some element of the doc, or to skip the doc by returning
C<undef>.

=item *

See L</Error handlers> for an explanation C<on_conflict> and C<on_error>.

=back

=head4 Examples:

To copy the Elasticsearch website index locally, you could do:

    my $local = Search::Elasticsearch::Compat->new(
        servers => 'localhost:9200'
    );
    my $remote = Search::Elasticsearch::Compat->new(
        servers    => 'search.elasticsearch.org:80',
        no_refresh => 1
    );

    my $source = $remote->scrolled_search(
        search_type => 'scan',
        scroll      => '5m'
    );
    $local->reindex(source=>$source);

To copy one local index to another, make the title upper case,
exclude docs of type C<boring>, and to preserve the version numbers
from the original index:

    my $source = $es->scrolled_search(
        index       => 'old_index',
        search_type => 'scan',
        scroll      => '5m',
        version     => 1
    );

    $es->reindex(
        source      => $source,
        dest_index  => 'new_index',
        transform   => sub {
            my $doc = shift;
            return if $doc->{_type} eq 'boring';
            $doc->{_source}{title} = uc( $doc->{_source}{title} );
            return $doc;
        }
    );

B<NOTE:> If some of your docs have parent/child relationships, and you want
to preserve this relationship, then you should add this to your
scrolled search parameters: C<< fields => ['_source','_parent'] >>.

For example:

    my $source = $es->scrolled_search(
        index       => 'old_index',
        search_type => 'scan',
        fields      => ['_source','_parent'],
        version     => 1
    );

    $es->reindex(
        source      => $source,
        dest_index  => 'new_index',
    );

See also L</"scrolled_search()">, L<Search::Elasticsearch::Compat::ScrolledSearch>,
and L</"search()">.

=head3 analyze()

    $result = $es->analyze(
      text          =>  $text_to_analyze,           # required
      index         =>  single,                     # optional

      # either
      field         =>  'type.fieldname',           # requires index

      analyzer      =>  $analyzer,

      tokenizer     => $tokenizer,
      filters       => \@filters,

      # other options
      format        =>  'detailed' | 'text',
      prefer_local  =>  1 | 0
    );

The C<analyze()> method allows you to see how Elasticsearch is analyzing
the text that you pass in, eg:

    $result = $es->analyze( text => 'The Man' )

    $result = $es->analyze(
        text        => 'The Man',
        analyzer    => 'simple'
    );

    $result = $es->analyze(
        text        => 'The Man',
        tokenizer   => 'keyword',
        filters     => ['lowercase'],
    );

    $result = $es->analyze(
        text        => 'The Man',
        index       => 'my_index',
        analyzer    => 'my_custom_analyzer'
    );

    $result = $es->analyze(
        text        => 'The Man',
        index       => 'my_index',
        field       => 'my_type.my_field',
    );

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-analyze.html> for
more.

=head2 Query methods

=head3 search()

    $result = $es->search(
        index           => multi,
        type            => multi,

        # optional
        query           => { native query },
        queryb          => { searchbuilder query },

        filter          => { native filter },
        filterb         => { searchbuilder filter },

        explain         => 1 | 0,
        facets          => { facets },
        fields          => [$field_1,$field_n],
        partial_fields  => { my_field => { include => 'foo.bar.*' }},
        from            => $start_from,
        highlight       => { highlight }.
        ignore_indices  => 'none' | 'missing',
        indices_boost   => { index_1 => 1.5,... },
        min_score       => $score,
        preference      => '_local' | '_primary' | '_primary_first' | $string,
        routing         => [$routing, ...]
        script_fields   => { script_fields }
        search_type     => 'dfs_query_then_fetch'
                           | 'dfs_query_and_fetch'
                           | 'query_then_fetch'
                           | 'query_and_fetch'
                           | 'count'
                           | 'scan'
        size            => $no_of_results
        sort            => ['_score',$field_1]
        scroll          => '5m' | '30s',
        stats           => ['group_1','group_2'],
        track_scores    => 0 | 1,
        timeout         => '10s'
        version         => 0 | 1
    );

Searches for all documents matching the query, with a request-body search.
Documents can be matched against multiple indices and multiple types, eg:

    $result = $es->search(
        index   => undef,                           # all
        type    => ['user','tweet'],
        query   => { term => {user => 'kimchy' }}
    );

You can provide either the C<query> parameter, which uses the native
Elasticsearch Query DSL, or the C<queryb> parameter, which uses the
more concise L<ElasticSearch::SearchBuilder> query syntax.

Similarly, use C<filterb> instead of C<filter>. SearchBuilder can also be
used in facets, for instance, instead of:

    $es->search(
        facets  => {
            wow_facet => {
                query        => { text => { content => 'wow'  }},
                facet_filter => { term => {status => 'active' }},
            }
        }
    )

You can use:

    $es->search(
        facets  => {
            wow_facet => {
                queryb        => { content => 'wow'   },  # note the extra 'b'
                facet_filterb => { status => 'active' },  # note the extra 'b'
            }
        }
    )

See L</"INTEGRATION WITH ElasticSearch::SearchBuilder"> for more.

For all of the options that can be included in the native C<query> parameter,
see L<http://www.elasticsearch.org/guide/reference/api/search>,
L<http://www.elasticsearch.org/guide/reference/api/search/request-body.html>
and L<http://www.elasticsearch.org/guide/reference/query-dsl>

=head3 searchqs()

    $result = $es->searchqs(
        index                    => multi,
        type                     => multi,

        # optional
        q                        => $query_string,
        analyze_wildcard         => 0 | 1,
        analyzer                 => $analyzer,
        default_operator         => 'OR | AND ',
        df                       => $default_field,
        explain                  => 1 | 0,
        fields                   => [$field_1,$field_n],
        from                     => $start_from,
        ignore_indices           => 'none' | 'missing',
        lenient                  => 0 | 1,
        lowercase_expanded_terms => 0 | 1,
        preference               => '_local' | '_primary' | '_primary_first' | $string,
        quote_analyzer           => $analyzer,
        quote_field_suffix       => '.unstemmed',
        routing                  => [$routing, ...]
        search_type              => $search_type
        size                     => $no_of_results
        sort                     => ['_score:asc','last_modified:desc'],
        scroll                   => '5m' | '30s',
        stats                    => ['group_1','group_2'],
        timeout                  => '10s'
        version                  => 0 | 1

Searches for all documents matching the C<q> query_string, with a URI request.
Documents can be matched against multiple indices and multiple types, eg:

    $result = $es->searchqs(
        index   => undef,                           # all
        type    => ['user','tweet'],
        q       => 'john smith'
    );

For all of the options that can be included in the C<query> parameter, see
L<http://www.elasticsearch.org/guide/reference/api/search> and
L<http://www.elasticsearch.org/guide/reference/api/search/uri-request.html>.

=head3 scroll()

    $result = $es->scroll(
        scroll_id => $scroll_id,
        scroll    => '5m' | '30s',
    );

If a search has been executed with a C<scroll> parameter, then the returned
C<scroll_id> can be used like a cursor to scroll through the rest of the
results.

If a further scroll request will be issued, then the C<scroll> parameter
should be passed as well.  For instance;

    my $result = $es->search(
                    query=>{match_all=>{}},
                    scroll => '5m'
                 );

    while (1) {
        my $hits = $result->{hits}{hits};
        last unless @$hits;                 # if no hits, we're finished

        do_something_with($hits);

        $result = $es->scroll(
            scroll_id   => $result->{_scroll_id},
            scroll      => '5m'
        );
    }

See L<http://www.elasticsearch.org/guide/reference/api/search/scroll.html>

=head3 scrolled_search()

C<scrolled_search()> returns a convenience iterator for scrolled
searches. It accepts the standard search parameters that would be passed
to L</"search()"> and requires a C<scroll> parameter, eg:

    $scroller = $es->scrolled_search(
                    query  => {match_all=>{}},
                    scroll => '5m'               # keep the scroll request
                                                 # live for 5 minutes
                );

See L<Search::Elasticsearch::Compat::ScrolledSearch>, L</"search()">, L</"searchqs()">
and L</"scroll()">.

=head3 count()

    $result = $es->count(
        index           => multi,
        type            => multi,

        # optional
        routing         => [$routing,...]
        ignore_indices  => 'none' | 'missing',

        # one of:
        query           => { native query },
        queryb          => { search builder query },
    );

Counts the number of documents matching the query. Documents can be matched
against multiple indices and multiple types, eg

    $result = $es->count(
        index   => undef,               # all
        type    => ['user','tweet'],
        queryb  => { user  => 'kimchy' }
    );

B<Note>: C<count()> supports L<ElasticSearch::SearchBuilder>-style
queries via the C<queryb> parameter.  See
L</"INTEGRATION WITH ElasticSearch::SearchBuilder"> for more details.

C<query> defaults to C<< {match_all=>{}} >> unless specified.

B<DEPRECATION>: C<count()> previously took query types at the top level, eg
C<< $es->count( term=> { ... }) >>. This form still works, but is deprecated.
Instead use the C<queryb> or C<query> parameter as you would in L</"search()">.

See also L</"search()">,
L<http://www.elasticsearch.org/guide/reference/api/count.html>
and L<http://www.elasticsearch.org/guide/reference/query-dsl>

=head3 msearch()

    $results = $es->msearch(
        index       => multi,
        type        => multi,
        queries     => \@queries | \%queries,
        search_type => $search_type,
    );

With L</"msearch()"> you can run multiple searches in parallel. C<queries>
can contain either an array of queries, or a hash of named queries.  C<$results>
will return either an array or hash of results, depending on what you pass in.

The top-level C<index>, C<type> and C<search_type> parameters define default
values which will be used for each query, although these can be overridden in
the query parameters:

    $results = $es->msearch(
        index   => 'my_index',
        type    => 'my_type',
        queries => {
            first   => {
                query => { match_all: {}}   # my_index/my_type
            },
            second  => {
                index => 'other_index',
                query => { match_all: {}}   # other_index/my_type
            },
        }
    )

In the above example, C<$results> would look like:

    {
        first  => { hits => ... },
        second => { hits => ... }
    }

A query can contain the following options:

    {
          index          => 'index_name' | ['index_1',...],
          type           => 'type_name'  | ['type_1',...],

          query          => { native query },
          queryb         => { search_builder query },
          filter         => { native filter },
          filterb        => { search_builder filter },

          facets         => { facets },
          from           => 0,
          size           => 10,
          sort           => { sort },
          highlight      => { highlight },
          fields         => [ 'field1', ... ],

          explain        => 0 | 1,
          indices_boost  => { index_1 => 5, ... },
          ignore_indices => 'none' | 'missing',
          min_score      => 2,
          partial_fields => { partial fields },
          preference     => '_local' | '_primary' | '_primary_first' | $string,
          routing        => 'routing' | ['route_1',...],
          script_fields  => { script fields },
          search_type    => $search_type,
          stats          => 'group_1' | ['group_1','group_2'],
          timeout        => '30s',
          track_scores   => 0 | 1,
          version        => 0 | 1,
    }

See L<http://www.elasticsearch.org/guide/reference/api/multi-search.html>.

=head3 delete_by_query()

    $result = $es->delete_by_query(
        index           => multi,
        type            => multi,

        # optional
        consistency     => 'quorum' | 'one' | 'all'
        replication     => 'sync' | 'async'
        routing         => [$routing,...]

        # one of:
        query           => { native query },
        queryb          => { search builder query },

    );

Deletes any documents matching the query. Documents can be matched against
multiple indices and multiple types, eg

    $result = $es->delete_by_query(
        index   => undef,               # all
        type    => ['user','tweet'],
        queryb  => {user => 'kimchy' },
    );

B<Note>: C<delete_by_query()> supports L<ElasticSearch::SearchBuilder>-style
queries via the C<queryb> parameter.  See
L</"INTEGRATION WITH ElasticSearch::SearchBuilder"> for more details.

B<DEPRECATION>: C<delete_by_query()> previously took query types at the top level,
eg C<< $es->delete_by_query( term=> { ... }) >>. This form still works, but is
deprecated. Instead use the C<queryb> or C<query> parameter as you would in
L</"search()">.

See also L</"search()">,
L<http://www.elasticsearch.org/guide/reference/api/delete-by-query.html>
and L<http://www.elasticsearch.org/guide/reference/query-dsl>

=head3 mlt()

    # mlt == more_like_this

    $results = $es->mlt(
        index               => single,              # required
        type                => single,              # required
        id                  => $id,                 # required

        # optional more-like-this params
        boost_terms          =>  float
        mlt_fields           =>  'scalar' or ['scalar_1', 'scalar_n']
        max_doc_freq         =>  integer
        max_query_terms      =>  integer
        max_word_len         =>  integer
        min_doc_freq         =>  integer
        min_term_freq        =>  integer
        min_word_len         =>  integer
        pct_terms_to_match   =>  float
        stop_words           =>  'scalar' or ['scalar_1', 'scalar_n']

        # optional search params
        explain              =>  {explain}
        facets               =>  {facets}
        fields               =>  {fields}
        filter               =>  { native filter },
        filterb              =>  { search builder filter },
        indices_boost        =>  { index_1 => 1.5,... }
        min_score            =>  $score
        routing              =>  [$routing,...]
        script_fields        =>  { script_fields }
        search_scroll        =>  '5m' | '10s',
        search_indices       =>  ['index1','index2],
        search_from          =>  integer,
        search_size          =>  integer,
        search_type          =>  $search_type
        search_types         =>  ['type1','type],
        sort                 =>  {sort}
        scroll               =>  '5m' | '30s'
    )

More-like-this (mlt) finds related/similar documents. It is possible to run
a search query with a C<more_like_this> clause (where you pass in the text
you're trying to match), or to use this method, which uses the text of
the document referred to by C<index/type/id>.

This gets transformed into a search query, so all of the search parameters
are also available.

Note: C<mlt()> supports L<ElasticSearch::SearchBuilder>-style filters via
the C<filterb> parameter.  See L</"INTEGRATION WITH ElasticSearch::SearchBuilder">
for more details.

See L<http://www.elasticsearch.org/guide/reference/api/more-like-this.html>
and L<http://www.elasticsearch.org/guide/reference/query-dsl/mlt-query.html>

=head3 explain()

    $result = $ex->explain(
        index                      =>  single,
        type                       =>  single,
        id                         =>  single,


        query                      => { native query}
      | queryb                     => { search builder query }
      | q                          => $query_string,

        analyze_wildcard           => 1 | 0,
        analyzer                   => $string,
        default_operator           => 'OR' | 'AND',
        df                         => $default_field
        fields                     => ['_source'],
        lenient                    => 1 | 0,
        lowercase_expanded_terms   => 1 | 0,
        preference                 => _local | _primary | _primary_first | $string,
        routing                    => $routing
    );

The L<explain()> method is very useful for debugging queries.  It will run
the query on the specified document and report whether the document matches
the query or not, and why.

See L<http://www.elasticsearch.org/guide/reference/api/search/explain.html>

=head3 validate_query()

    $bool = $es->validate_query(
        index          => multi,
        type           => multi,

        query          => { native query }
      | queryb         => { search builder query }
      | q              => $query_string

        explain        => 0 | 1,
        ignore_indices => 'none' | 'missing',
    );

Returns a hashref with C<< { valid => 1} >> if the passed in C<query>
(native ES query) C<queryb> (SearchBuilder style query) or C<q> (Lucene
query string) is valid. Otherwise C<valid> is false. Set C<explain> to C<1>
to include the explanation of why the query is invalid.

See L<http://www.elasticsearch.org/guide/reference/api/validate.html>

=head2 Index Admin methods

=head3 index_status()

    $result = $es->index_status(
        index           => multi,
        recovery        => 0 | 1,
        snapshot        => 0 | 1,
        ignore_indices  => 'none' | 'missing',
    );

Returns the status of
    $result = $es->index_status();                               #all
    $result = $es->index_status( index => ['twitter','buzz'] );
    $result = $es->index_status( index => 'twitter' );

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-status.html>

=head3 index_stats()

    $result = $es->index_stats(
        index           => multi,
        types           => multi,

        docs            => 1|0,
        store           => 1|0,
        indexing        => 1|0,
        get             => 1|0,

        all             => 0|1,  # returns all stats
        clear           => 0|1,  # clears default docs,store,indexing,get,search

        flush           => 0|1,
        merge           => 0|1
        refresh         => 0|1,

        level           => 'shards',
        ignore_indices  => 'none' | 'missing',
    );

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-stats.html>

=head3 index_segments()

    $result = $es->index_segments(
        index           => multi,
        ignore_indices  => 'none' | 'missing',
    );

Returns low-level Lucene segments information for the specified indices.

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-segments.html>

=head3 create_index()

    $result = $es->create_index(
        index       => single,

        # optional
        settings    => {...},
        mappings    => {...},
        warmers     => {...},
    );

Creates a new index, optionally passing index settings and mappings, eg:

    $result = $es->create_index(
        index   => 'twitter',
        settings => {
            number_of_shards      => 3,
            number_of_replicas    => 2,
            analysis => {
                analyzer => {
                    default => {
                        tokenizer   => 'standard',
                        char_filter => ['html_strip'],
                        filter      => [qw(standard lowercase stop asciifolding)],
                    }
                }
            }
        },
        mappings => {
            tweet   => {
                properties  => {
                    user    => { type => 'string' },
                    content => { type => 'string' },
                    date    => { type => 'date'   }
                }
            }
        },
        warmers => {
            warmer_1 => {
                types  => ['tweet'],
                source => {
                    queryb => { date    => { gt => '2012-01-01' }},
                    facets => {
                        content => {
                            terms => {
                                field=>'content'
                            }
                        }
                    }
                }
            }
        }
    );

Throws an exception if the index already exists.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html>

=head3 delete_index()

    $result = $es->delete_index(
        index           => multi_req,
        ignore_missing  => 0 | 1        # optional
    );

Deletes one or more existing indices, or throws a C<Missing> exception if a
specified index doesn't exist and C<ignore_missing> is not true:

    $result = $es->delete_index( index => 'twitter' );

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-delete-index.html>

=head3 index_exists()

    $result = $e->index_exists(
        index => multi
    );

Returns C<< {ok => 1} >> if all specified indices exist, or an empty list
if it doesn't.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-indices-exists.html>

=head3 index_settings()

    $result = $es->index_settings(
        index           => multi,
    );

Returns the current settings for all, one or many indices.

    $result = $es->index_settings( index=> ['index_1','index_2'] );

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-get-settings.html>

=head3 update_index_settings()

    $result = $es->update_index_settings(
        index           => multi,
        settings        => { ... settings ...},
    );

Update the settings for all, one or many indices.  Currently only the
C<number_of_replicas> is exposed:

    $result = $es->update_index_settings(
        settings    => {  number_of_replicas => 1 }
    );

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-update-settings.html>

=head3 aliases()

    $result = $es->aliases( actions => [actions] | {actions} )

Adds or removes an alias for an index, eg:

    $result = $es->aliases( actions => [
                { remove => { index => 'foo', alias => 'bar' }},
                { add    => { index => 'foo', alias => 'baz'  }}
              ]);

C<actions> can be a single HASH ref, or an ARRAY ref containing multiple HASH
refs.

Note: C<aliases()> supports L<ElasticSearch::SearchBuilder>-style
filters via the C<filterb> parameter.  See
L</"INTEGRATION WITH ElasticSearch::SearchBuilder"> for more details.

    $result = $es->aliases( actions => [
        { add    => {
            index           => 'foo',
            alias           => 'baz',
            index_routing   => '1',
            search_routing  => '1,2',
            filterb => { foo => 'bar' }
        }}
    ]);

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html>

=head3 get_aliases()

    $result = $es->get_aliases(
        index          => multi,
        ignore_missing => 0 | 1,
    );

Returns a hashref listing all indices and their corresponding aliases, eg:

    {
       "foo" : {
          "aliases" : {
             "foo_1" : {
                "search_routing" : "1,2",
                "index_routing" : "1"
                "filter" : {
                   "term" : {
                      "foo" : "bar"
                   }
                }
             },
             "foo_2" : {}
          }
       }
    }

If you pass in the optional C<index> argument, which can be an index name
or an alias name, then it will only return the indices related
to that argument.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html>

=head3 open_index()

    $result = $es->open_index( index => single);

Opens a closed index.

The open and close index APIs allow you to close an index, and later on open
it.

A closed index has almost no overhead on the cluster (except for maintaining
its metadata), and is blocked for read/write operations. A closed index can
be opened which will then go through the normal recovery process.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-open-close.html> for more

=head3 close_index()

    $result = $es->close_index( index => single);

Closes an open index.  See
L<http://www.elasticsearch.org/guide/reference/api/admin-indices-open-close.html> for more

=head3 create_index_template()

    $result = $es->create_index_template(
        name     => single,
        template => $template,  # required
        mappings => {...},      # optional
        settings => {...},      # optional
        warmers  => {...},      # optional
        order    => $order,     # optional
    );

Index templates allow you to define templates that will automatically be
applied to newly created indices. You can specify both C<settings> and
C<mappings>, and a simple pattern C<template> that controls whether
the template will be applied to a new index.

For example:

    $result = $es->create_index_template(
        name        => 'my_template',
        template    => 'small_*',
        settings    =>  { number_of_shards => 1 }
    );

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-templates.html> for more.

=head3 index_template()

    $result = $es->index_template(
        name    => single
    );

Retrieves the named index template.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-templates.html#GETting_a_Template>

=head3 delete_index_template()

    $result = $es->delete_index_template(
        name            => single,
        ignore_missing  => 0 | 1    # optional
    );

Deletes the named index template.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-templates.html#Deleting_a_Template>

=head3 flush_index()

    $result = $es->flush_index(
        index           => multi,
        full            => 0 | 1,
        refresh         => 0 | 1,
        ignore_indices  => 'none' | 'missing',
    );

Flushes one or more indices, which frees
memory from the index by flushing data to the index storage and clearing the
internal transaction log. By default, Elasticsearch uses memory heuristics
in order to automatically trigger flush operations as required in order to
clear memory.

Example:

    $result = $es->flush_index( index => 'twitter' );

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-flush.html>

=head3 refresh_index()

    $result = $es->refresh_index(
        index           => multi,
        ignore_indices  => 'none' | 'missing',
    );

Explicitly refreshes one or more indices, making all operations performed
since the last refresh available for search. The (near) real-time capabilities
depends on the index engine used. For example, the robin one requires
refresh to be called, but by default a refresh is scheduled periodically.

Example:

    $result = $es->refresh_index( index => 'twitter' );

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-refresh.html>

=head3 optimize_index()

    $result = $es->optimize_index(
        index               => multi,
        only_deletes        => 0 | 1,  # only_expunge_deletes
        flush               => 0 | 1,  # flush after optmization
        refresh             => 0 | 1,  # refresh after optmization
        wait_for_merge      => 1 | 0,  # wait for merge to finish
        max_num_segments    => int,    # number of segments to optimize to
        ignore_indices      => 'none' | 'missing',
    )

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-optimize.html>

=head3 gateway_snapshot()

    $result = $es->gateway_snapshot(
        index           => multi,
        ignore_indices  => 'none' | 'missing',
    );

Explicitly performs a snapshot through the gateway of one or more indices
(backs them up ). By default, each index gateway periodically snapshot changes,
though it can be disabled and be controlled completely through this API.

Example:

    $result = $es->gateway_snapshot( index => 'twitter' );

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-gateway-snapshot.html>
and L<http://www.elasticsearch.org/guide/reference/modules/gateway>

=head3 snapshot_index()

C<snapshot_index()> is a synonym for L</"gateway_snapshot()">

=head3 clear_cache()

    $result = $es->clear_cache(
        index           => multi,
        bloom           => 0 | 1,
        field_data      => 0 | 1,
        filter          => 0 | 1,
        id              => 0 | 1,
        fields          => 'field1' | ['field1','fieldn',...],
        ignore_indices  => 'none' | 'missing',
    );

Clears the caches for the specified indices. By default, clears all caches,
but if any of C<id>, C<field>, C<field_data> or C<bloom> are true, then
it clears just the specified caches.

Throws a C<Missing> exception if the specified indices do not exist.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-clearcache.html>

=head2 Mapping methods

=head3 put_mapping()

    $result = $es->put_mapping(
        index               => multi,
        type                => single,
        mapping             => { ... }      # required
        ignore_conflicts    => 0 | 1
    );

A C<mapping> is the data definition of a C<type>.  If no mapping has been
specified, then Elasticsearch tries to infer the types of each field in
document, by looking at its contents, eg

    'foo'       => string
    123         => integer
    1.23        => float

However, these heuristics can be confused, so it safer (and much more powerful)
to specify an official C<mapping> instead, eg:

    $result = $es->put_mapping(
        index   => ['twitter','buzz'],
        type    => 'tweet',
        mapping => {
            _source => { compress => 1 },
            properties  =>  {
                user        =>  {type  =>  "string", index      =>  "not_analyzed"},
                message     =>  {type  =>  "string", null_value =>  "na"},
                post_date   =>  {type  =>  "date"},
                priority    =>  {type  =>  "integer"},
                rank        =>  {type  =>  "float"}
            }
        }
    );

See also: L<http://www.elasticsearch.org/guide/reference/api/admin-indices-put-mapping.html>
and L<http://www.elasticsearch.org/guide/reference/mapping>

B<DEPRECATION>: C<put_mapping()> previously took the mapping parameters
at the top level, eg C<< $es->put_mapping( properties=> { ... }) >>.
This form still works, but is deprecated. Instead use the C<mapping>
parameter.

=head3 delete_mapping()

    $result = $es->delete_mapping(
        index           => multi_req,
        type            => single,
        ignore_missing  => 0 | 1,
    );

Deletes a mapping/type in one or more indices.
See also L<http://www.elasticsearch.org/guide/reference/api/admin-indices-delete-mapping.html>

Throws a C<Missing> exception if the indices or type don't exist and
C<ignore_missing> is false.

=head3 mapping()

    $mapping = $es->mapping(
        index       => single,
        type        => multi
    );

Returns the mappings for all types in an index, or the mapping for the specified
type(s), eg:

    $mapping = $es->mapping(
        index       => 'twitter',
        type        => 'tweet'
    );

    $mappings = $es->mapping(
        index       => 'twitter',
        type        => ['tweet','user']
    );
    # { twitter => { tweet => {mapping}, user => {mapping}} }

Note: the index name which as used in the results is the actual index name. If
you pass an alias name as the C<index> name, then this key will be the
index (or indices) that the alias points to.

See also: L<http://www.elasticsearch.org/guide/reference/api/admin-indices-get-mapping.html>

=head3 type_exists()

    $result = $e->type_exists(
        index          => multi,             # optional
        type           => multi,             # required
        ignore_indices => 'none' | 'missing',
    );

Returns C<< {ok => 1} >> if all specified types exist in all specified indices,
or an empty list if they doesn't.

See L<http://www.elasticsearch.org/guide/reference/api/admin-indices-types-exists.html>

=head2 Warmer methods

Index warming allow you to run typical search requests to "warm up"
new segments before they become available for search.
Warmup searches typically include requests that require heavy loading of
data, such as faceting or sorting on specific fields.

=head3 create_warmer()

    $es->create_warmer(
        warmer        => $warmer,
        index         => multi,
        type          => multi,

        # optional

        query         => { raw query }
      | queryb        => { search builder query },

        filter        => { raw filter }
      | filterb       => { search builder filter},

        facets        => { facets },
        script_fields => { script fields },
        sort          => { sort },
    );

Create an index warmer called C<$warmer>: a search which is run whenever a
matching C<index>/C<type> segment is about to be brought online.

See L<https://github.com/elasticsearch/elasticsearch/issues/1913> for more.

=head2 warmer()

    $result = $es->warmer(
        index          => multi,       # optional
        warmer         => $warmer,     # optional

        ignore_missing => 0 | 1
    );

Returns any matching registered warmers. The C<$warmer> can be blank,
the name of a particular warmer, or use wilcards, eg C<"warmer_*">. Throws
an error if no matching warmer is found, and C<ignore_missing> is false.

See L<https://github.com/elasticsearch/elasticsearch/issues/1913> for more.

=head2 delete_warmer()

    $result = $es->delete_warmer(
        index          => multi,       # required
        warmer         => $warmer,     # required

        ignore_missing => 0 | 1
    );

Deletes any matching registered warmers. The C<index> parameter is
required and can be set to C<_all> to match all indices. The C<$warmer> can be
the name of a particular warmer, or use wilcards, eg C<"warmer_*">
or C<"*"> for any warmer. Throws an error if no matching warmer is found,
and C<ignore_missing> is false.

See L<https://github.com/elasticsearch/elasticsearch/issues/1913> for more.

=head2 River admin methods

See L<http://www.elasticsearch.org/guide/reference/river/>
and L<http://www.elasticsearch.org/guide/reference/river/twitter.html>.

=head3 create_river()

    $result = $es->create_river(
        river   => $river_name,     # required
        type    => $type,           # required
        $type   => {...},           # depends on river type
        index   => {...},           # depends on river type
    );

Creates a new river with name C<$name>, eg:

    $result = $es->create_river(
        river   => 'my_twitter_river',
        type    => 'twitter',
        twitter => {
            user        => 'user',
            password    => 'password',
        },
        index   => {
            index       => 'my_twitter_index',
            type        => 'status',
            bulk_size   => 100
        }
    )

=head3 get_river()

    $result = $es->get_river(
        river           => $river_name,
        ignore_missing  => 0 | 1        # optional
    );

Returns the river details eg

    $result = $es->get_river ( river => 'my_twitter_river' )

Throws a C<Missing> exception if the river doesn't exist and C<ignore_missing>
is false.

=head3 delete_river()

    $result = $es->delete_river( river => $river_name );

Deletes the corresponding river, eg:

    $result = $es->delete_river ( river => 'my_twitter_river' )

See L<http://www.elasticsearch.org/guide/reference/river/>.

=head3 river_status()

    $result = $es->river_status(
        river           => $river_name,
        ignore_missing  => 0 | 1        # optional
    );

Returns the status doc for the named river.

Throws a C<Missing> exception if the river doesn't exist and C<ignore_missing>
is false.

=head2 Percolate methods

See also: L<http://www.elasticsearch.org/guide/reference/api/percolate.html>
and L<http://www.elasticsearch.org/blog/2011/02/08/percolator.html>

=head3 create_percolator()

    $es->create_percolator(
        index           =>  single
        percolator      =>  $percolator

        # one of queryb or query is required
        query           =>  { native query }
        queryb          =>  { search builder query }

        # optional
        data            =>  {data}
    )

Create a percolator, eg:

    $es->create_percolator(
        index           => 'myindex',
        percolator      => 'mypercolator',
        queryb          => { field => 'foo'  },
        data            => { color => 'blue' }
    )

Note: C<create_percolator()> supports L<ElasticSearch::SearchBuilder>-style
queries via the C<queryb> parameter.  See
L</"INTEGRATION WITH ElasticSearch::SearchBuilder"> for more details.

=head3 get_percolator()

    $es->get_percolator(
        index           =>  single
        percolator      =>  $percolator,
        ignore_missing  =>  0 | 1,
    )

Retrieves a percolator, eg:

    $es->get_percolator(
        index           => 'myindex',
        percolator      => 'mypercolator',
    )

Throws a C<Missing> exception if the specified index or percolator does not exist,
and C<ignore_missing> is false.

=head3 delete_percolator()

    $es->delete_percolator(
        index           =>  single
        percolator      =>  $percolator,
        ignore_missing  =>  0 | 1,
    )

Deletes a percolator, eg:

    $es->delete_percolator(
        index           => 'myindex',
        percolator      => 'mypercolator',
    )

Throws a C<Missing> exception if the specified index or percolator does not exist,
and C<ignore_missing> is false.

=head3 percolate()

    $result = $es->percolate(
        index           => single,
        type            => single,
        doc             => { doc to percolate },

        # optional
        query           => { query to filter percolators },
        prefer_local    => 1 | 0,
    )

Check for any percolators which match a document, optionally filtering
which percolators could match by passing a C<query> param, for instance:

    $result = $es->percolate(
        index           => 'myindex',
        type            => 'mytype',
        doc             => { text => 'foo' },
        query           => { term => { color => 'blue' }}
    );

Returns:

    {
        ok      => 1,
        matches => ['mypercolator']
    }

=head2 Cluster admin methods

=head3 cluster_state()

    $result = $es->cluster_state(
         # optional
         filter_blocks          => 0 | 1,
         filter_nodes           => 0 | 1,
         filter_metadata        => 0 | 1,
         filter_routing_table   => 0 | 1,
         filter_indices         => [ 'index_1', ... 'index_n' ],
    );

Returns cluster state information.

See L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-state.html>

=head3 cluster_health()

    $result = $es->cluster_health(
        index                         => multi,
        level                         => 'cluster' | 'indices' | 'shards',
        timeout                       => $seconds
        wait_for_status               => 'red' | 'yellow' | 'green',
        | wait_for_relocating_shards  => $number_of_shards,
        | wait_for_nodes              => eg '>=2',
    );

Returns the status of the cluster, or index|indices or shards, where the
returned status means:

=over

=item C<red>: Data not allocated

=item C<yellow>: Primary shard allocated

=item C<green>: All shards allocated

=back

It can block to wait for a particular status (or better), or can block to
wait until the specified number of shards have been relocated (where 0 means
all) or the specified number of nodes have been allocated.

If waiting, then a timeout can be specified.

For example:

    $result = $es->cluster_health( wait_for_status => 'green', timeout => '10s')

See: L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-health.html>

=head3 cluster_settings()

    $result = $es->cluster_settings()

Returns any cluster wide settings that have been set with
L</"update_cluster_settings">.

See L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-update-settings.html>

=head3 update_cluster_settings()

    $result = $es->update_cluster_settings(
        persistent  => {...},
        transient   => {...},
    )

For example:

    $result = $es->update_cluster_settings(
        persistent  => {
            "discovery.zen.minimum_master_nodes" => 2
        },
    )

C<persistent> settings will survive a full cluster restart. C<transient>
settings won't.

See L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-update-settings.html>

=head3 nodes()

    $result = $es->nodes(
        nodes       => multi,
        settings    => 0 | 1,
        http        => 0 | 1,
        jvm         => 0 | 1,
        network     => 0 | 1,
        os          => 0 | 1,
        process     => 0 | 1,
        thread_pool => 0 | 1,
        transport   => 0 | 1
    );

Returns information about one or more nodes or servers in the cluster.

See: L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-nodes-info.html>

=head3 nodes_stats()

    $result = $es->nodes_stats(
        node    => multi,

        indices     => 1 | 0,
        clear       => 0 | 1,
        all         => 0 | 1,
        fs          => 0 | 1,
        http        => 0 | 1,
        jvm         => 0 | 1,
        network     => 0 | 1,
        os          => 0 | 1,
        process     => 0 | 1,
        thread_pool => 0 | 1,
        transport   => 0 | 1,

    );

Returns various statistics about one or more nodes in the cluster.

See: L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-nodes-stats.html>

=head3 cluster_reroute()

    $result = $es->cluster_reroute(
        commands => [
            { move => {
                  index     => 'test',
                  shard     => 0,
                  from_node => 'node1',
                  to_node   => 'node2',
            }},
            { allocate => {
                  index         => 'test',
                  shard         => 1,
                  node          => 'node3',
                  allow_primary => 0 | 1
            }},
            { cancel => {
                  index         => 'test',
                  shard         => 2,
                  node          => 'node4',
                  allow_primary => 0 | 1
            }},
        ],
        dry_run  => 0 | 1
    );

The L</cluster_reroute> command allows you to explicitly affect shard allocation
within a cluster. For example, a shard can be moved from one node to another,
an allocation can be cancelled, or an unassigned shard can be explicitly
allocated on a specific node.

B<NOTE:> after executing the commands, the cluster will automatically
rebalance itself if it is out of balance.  Use the C<dry_run> parameter
to see what the final outcome will be after automatic rebalancing, before
executing the real L</cluster_reroute> call.

Without any C<\@commands>, the current cluster routing will be returned.

See L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-reroute.html>

=head3 shutdown()

    $result = $es->shutdown(
        node        => multi,
        delay       => '5s' | '10m'        # optional
    );

Shuts down one or more nodes (or the whole cluster if no nodes specified),
optionally with a delay.

C<node> can also have the values C<_local>, C<_master> or C<_all>.

See: L<http://www.elasticsearch.org/guide/reference/api/admin-cluster-nodes-shutdown.html>

=head3 restart()

    $result = $es->restart(
        node        => multi,
        delay       => '5s' | '10m'        # optional
    );

Restarts one or more nodes (or the whole cluster if no nodes specified),
optionally with a delay.

C<node> can also have the values C<_local>, C<_master> or C<_all>.

See: L</"KNOWN ISSUES">

=head3 current_server_version()

    $version = $es->current_server_version()

Returns a HASH containing the version C<number> string and
whether or not the current server is a C<snapshot_build>.

=head2 Other methods

=head3 use_index()/use_type()

C<use_index()> and C<use_type()> can be used to set default values for
any C<index> or C<type> parameter. The default value can be overridden
by passing a parameter (including C<undef>) to any request.

    $es->use_index('one');
    $es->use_type(['foo','bar']);

    $es->index(                         # index: one, types: foo,bar
        data=>{ text => 'my text' }
    );

    $es->index(                         # index: two, type: foo,bar
        index=>'two',
        data=>{ text => 'my text' }
    )

    $es->search( type => undef );       # index: one, type: all

=head3 trace_calls()

    $es->trace_calls(1);            # log to STDERR
    $es->trace_calls($filename);    # log to $filename.$PID
    $es->trace_calls(\*STDOUT);     # log to STDOUT
    $es->trace_calls($fh);          # log to given filehandle
    $es->trace_calls(0 | undef);    # disable logging

C<trace_calls()> is used for debugging.  All requests to the cluster
are logged either to C<STDERR>, or the specified filehandle,
or the specified filename, with the
current C<$PID> appended, in a form that can be rerun with curl.

The cluster response will also be logged, and commented out.

Example: C<< $es->cluster_health >> is logged as:

    # [Tue Oct 19 15:32:31 2010] Protocol: http, Server: 127.0.0.1:9200
    curl -XGET 'http://127.0.0.1:9200/_cluster/health'

    # [Tue Oct 19 15:32:31 2010] Response:
    # {
    #    "relocating_shards" : 0,
    #    "active_shards" : 0,
    #    "status" : "green",
    #    "cluster_name" : "elasticsearch",
    #    "active_primary_shards" : 0,
    #    "timed_out" : false,
    #    "initializing_shards" : 0,
    #    "number_of_nodes" : 1,
    #    "unassigned_shards" : 0
    # }

=head3 query_parser()

    $qp = $es->query_parser(%opts);

Returns an L<Search::Elasticsearch::Compat::QueryParser> object for tidying up
query strings so that they won't cause an error when passed to Elasticsearch.

See L<Search::Elasticsearch::Compat::QueryParser> for more information.

=head3 transport()

    $transport = $es->transport

Returns the Transport object, eg L<Search::Elasticsearch::Compat::Transport::HTTP>.

=head3 timeout()

    $timeout = $es->timeout($timeout)

Convenience method which does the same as:

   $es->transport->timeout($timeout)

=head3 refresh_servers()

    $es->refresh_servers()

Convenience method which does the same as:

    $es->transport->refresh_servers()

This tries to retrieve a list of all known live servers in the Elasticsearch
cluster by connecting to each of the last known live servers (and the initial
list of servers passed to C<new()>) until it succeeds.

This list of live servers is then used in a round-robin fashion.

C<refresh_servers()> is called on the first request and every C<max_requests>.
This automatic refresh can be disabled by setting C<max_requests> to C<0>:

    $es->transport->max_requests(0)

Or:

    $es = Search::Elasticsearch::Compat->new(
            servers         => '127.0.0.1:9200',
            max_requests    => 0,
    );

=head3 builder_class() | builder()

The C<builder_class> is set to L<ElasticSearch::SearchBuilder> by default.
This can be changed, eg:

    $es = Search::Elasticsearch::Compat->new(
            servers         => '127.0.0.1:9200',
            builder_class   => 'My::Builder'
    );

C<builder()> will C<require> the module set in C<builder_class()>, create
an instance, and store that instance for future use.  The C<builder_class>
should implement the C<filter()> and C<query()> methods.

=head3 camel_case()

    $bool = $es->camel_case($bool)

Gets/sets the camel_case flag. If true, then all JSON keys returned by
Elasticsearch are in camelCase, instead of with_underscores.  This flag
does not apply to the source document being indexed or fetched.

Defaults to false.

=head3 error_trace()

    $bool = $es->error_trace($bool)

If the Elasticsearch server is returning an error, setting C<error_trace>
to true will return some internal information about where the error originates.
Mostly useful for debugging.

=head1 AUTHOR

Clinton Gormley, C<< <drtech at cpan.org> >>

=head1 KNOWN ISSUES

=over

=item L</"get()">

The C<_source> key that is returned from a L</"get()"> contains the original JSON
string that was used to index the document initially.  Elasticsearch parses
JSON more leniently than L<JSON::XS>, so if invalid JSON is used to index the
document (eg unquoted keys) then C<< $es->get(....) >> will fail with a
JSON exception.

Any documents indexed via this module will be not susceptible to this problem.

=item L</"restart()">

C<restart()> is currently disabled in Elasticsearch as it doesn't work
correctly.  Instead you can L</"shutdown()"> one or all nodes and then
start them up from the command line.

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: The client compatibility layer for migrating from ElasticSearch.pm











