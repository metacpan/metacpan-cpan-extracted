# NAME

Net::API::CPAN - Meta CPAN API

# SYNOPSIS

    use Net::API::CPAN;
    my $cpan = Net::API::CPAN->new(
        api_version => 1,
        ua => HTTP::Promise->new( %options ),
        debug => 4,
    ) || die( Net::API::CPAN->error, "\n" );
    $cpan->api_uri( 'https://api.example.org' );
    my $uri = $cpan->api_uri;
    $cpan->api_version(1);
    my $version = $cpan->api_version;

# VERSION

    v0.1.0

# DESCRIPTION

`Net::API::CPAN` is a client to issue queries to the MetaCPAN REST API.

Make sure to check out the ["TERMINOLOGY"](#terminology) section for the exact meaning of key words used in this documentation.

# CONSTRUCTOR

## new

This instantiates a new [Net::API::CPAN](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN) object. This accepts the following options, which can later also be set using their associated method.

- `api_version`

    Integer. This is the `CPAN` API version, and defaults to `1`.

- `debug`

    Integer. This sets the debugging level. Defaults to 0. The higher and the more verbose will be the debugging output on STDERR.

- `ua`

    An optional [HTTP::Promise](https://metacpan.org/pod/HTTP%3A%3APromise) object. If not provided, one will be instantiated automatically.

# METHODS

## api\_uri

Sets or gets the `CPAN` API `URI` to use. This defaults to the `Net::API::CPAN` constant `API_URI` followed by the API version, such as:

    https://fastapi.metacpan.org/v1

This returns an [URI](https://metacpan.org/pod/URI) object.

## api\_version

Sets or gets the `CPAN` API version. As of 2023-09-01, this can only `1`

This returns a [scalar object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar)

## cache\_file

Sets or gets a cache file path to use instead of issuing the `HTTP` request. This affects how ["fetch"](#fetch) works since it does not issue an actual `HTTP` request, but does not change the rest of the workflow.

Returns a [file object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AFile) or `undef` if nothing was set.

## fetch

This takes an object type, such as `author`, `release`, `file`, etc, and the following options and performs an `HttP` request to the remote MetaCPAN REST API and return the appropriate data or object.

If an error occurs, this set an [error object](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AError) and return `undef` in scalar context, and an empty list in list context.

- `class`

    One of `Net::API::CPAN` classes, such as [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor)

- `endpoint`

    The endpoint to access, such as `/author`

- `headers`

    An array reference of headers with their corresponding values.

- `method`

    The `HTTP` method to use. This defaults to `GET`. This is case insensitive.

- `payload`

    The `POST` payload to send to the remote MetaCPAN API. It must be already encoded in `UTF-8`.

- `postprocess`

    A subroutine reference or an anonymous subroutine that will be call backed, taking the data received as the sole argument and returning the modified data.

- `query`

    An hash reference of key-value pairs representing the query string elements. This will be passed to ["query\_form" in URI](https://metacpan.org/pod/URI#query_form), so make sure to check what data structure is acceptable by [URI](https://metacpan.org/pod/URI)

- `request`

    An [HTTP::Promise::Request](https://metacpan.org/pod/HTTP%3A%3APromise%3A%3ARequest) object.

## http\_request

The latest [HTTP::Promise::Request](https://metacpan.org/pod/HTTP%3A%3APromise%3A%3ARequest) issued to the remote MetaCPAN API server.

## http\_response

The latest [HTTP::Promise::Response](https://metacpan.org/pod/HTTP%3A%3APromise%3A%3AResponse) received from the remote MetaCPAN API server.

## json

Returns a new [JSON](https://metacpan.org/pod/JSON) object.

## new\_filter

This instantiates a new [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter), passing whatever arguments were received, and setting the debugging mode too.

# API METHODS

## activity

    # Get all the release activity for author OALDERS in the last 24 months
    my $activity_obj = $cpan->activity(
        author => 'OALDERS',
        # distribution => 'HTTP-Message',
        # module => 'HTTP::Message',
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    # Get all the release activity that depend on HTTP::Message in the last 24 months
    my $activity_obj = $cpan->activity(
        # author => 'OALDERS',
        # distribution => 'HTTP-Message',
        module => 'HTTP::Message',
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

This method is used to query the CPAN REST API for the release activity for all, or for a given `author`, or a given `distribution`, or a given `module` dependency. An optional aggregation interval can be stipulated with `res` and it defaults to `1w` (set by the API).

- `author` -> `/activity`

    If a string is provided representing a specific `author`, this will issue a query to the API endpoint `/activity` to retrieve the release activity for that `author` for the past 24 months for the specified author, such as:

        /activity?author=OALDERS

    For example:

        my $activity_obj = $cpan->activity(
            author => 'OALDERS',
            interval => '1M',
        ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    This would return, upon success, a [Net::API::CPAN::Activity](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AActivity) object containing release activity for the `author` `OALDERS` for the past 24 months.

    Note that the value of the `author` is case insensitive and will automatically be transformed in upper case, so you could also do:

    Possible options are:

    - `interval`

        Specifies an interval for the aggregate value. Defaults to `1w`, which is 1 week. See [ElasticSearch document](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries) for the proper value to use as interval.

    - `new`

        Limit the result to newly issued distributions.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Factivity%3Fauthor%3DOALDERS) to see the data returned by the CPAN REST API.

- `distribution` -> `/activity`

    If a string is provided representing a specific `distribution`, this will issue a query to the API endpoint `/activity` to retrieve the release activity for that `distribution` for the past 24 months for the specified `distribution`, such as:

        /activity?distribution=HTTP-Message

    For example:

        my $activity_obj = $cpan->activity(
            distribution => 'HTTP-Message',
            interval => '1M',
        ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    This would return, upon success, a [Net::API::CPAN::Activity](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AActivity) object containing release activity for the `distribution` `HTTP-Message` for the past 24 months.

    Possible options are:

    - `interval`

        Specifies an interval for the aggregate value. Defaults to `1w`, which is 1 week. See [ElasticSearch document](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries) for the proper value to use as interval.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Factivity%3Fdistribution%3DHTTP-Message) to see the data returned by the CPAN REST API.

- `module` -> `/activity`

    If a string is provided representing a specific `module`, this will issue a query to the API endpoint `/activity` to retrieve the release activity that have a dependency on that `module` for the past 24 months, such as:

        /activity?res=1M&module=HTTP::Message

    For example:

        my $activity_obj = $cpan->activity(
            module => 'HTTP::Message',
            interval => '1M',
        ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    This would return, upon success, a [Net::API::CPAN::Activity](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AActivity) object containing release activity for all the distributions depending on the `module` `HTTP::Message` for the past 24 months.

    Possible options are:

    - `interval`

        Specifies an interval for the aggregate value. Defaults to `1w`, which is 1 week. See [ElasticSearch document](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries) for the proper value to use as interval.

    - `new`

        Limit the result to newly issued distributions.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Factivity%3Fres%3D1M%26module%3DHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

- `new` -> `/activity`

    If `new` is provided with any value (true or not does not matter), this will issue a query to the API endpoint `/activity` to retrieve the new release activity in the past 24 months, such as:

        /activity?res=1M&new_dists=n

    For example:

        my $activity_obj = $cpan->activity(
            new => 1,
            interval => '1M',
        ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    This would return, upon success, a [Net::API::CPAN::Activity](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AActivity) object containing all new distributions release activity for the past 24 months.

    Possible options are:

    - `interval`

        Specifies an interval for the aggregate value. Defaults to `1w`, which is 1 week. See [ElasticSearch document](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries) for the proper value to use as interval.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Factivity%3Fres%3D1M%26new_dists%3Dn) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## author

    # Retrieves the information details for the specified author
    my $author_obj = $cpan->author( 'OALDERS' ) ||
        die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    # Retrieves author information details for the specified pause IDs
    my $list_obj = $cpan->author( [qw( OALDERS NEILB )] ) ||
        die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    # Queries authors information details
    my $list_obj = $cpan->author(
        query => 'Olaf',
        from => 10,
        size => 20,
    ) || die( $cpan->error );

    # Queries authors information details using ElasticSearch format
    my $list_obj = $cpan->author( $filter_object ) ||
        die( $cpan->error );

    # Queries authors information using a prefix
    my $list_obj = $cpan->author( prefix => 'O' ) || 
        die( $cpan->error );

    # Retrieves authors information using their specified IDs
    my $list_obj = $cpan->author( user => [qw( FepgBJBZQ8u92eG_TcyIGQ 6ZuVfdMpQzy75_Mazx2_nw )] ) || 
        die( $cpan->error );

This method is used to query the CPAN REST API for a specific `author`, a list of `authors`, or search an `author` using a query.
It takes a string, an array reference, an hash or alternatively an hash reference as possible parameters.

- `author` -> `/author/{author}`

    If a string is provided representing a specific `author`, this will issue a query to the API endpoint `/author/{author}` to retrieve the information details for the specified author, such as:

        /author/OALDERS

    For example:

        my $author_obj = $cpan->author( 'OALDERS' ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor) object.

    Note that the value of the `author` is case insensitive and will automatically be transformed in upper case, so you could also do:

        my $author_obj = $cpan->author( 'OAlders' ) ||
            die( $cpan->error );

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fauthor%2FOALDERS) to see the data returned by the CPAN REST API.

- \[`author`\] -> `/author/by_ids`

    And providing an array reference of `authors` will trigger a query to the API endpoint `/author/by_ids`, such as:

        /author/by_ids?id=OALDERS&id=NEILB

    For example:

        my $list_obj = $cpan->author( [qw( OALDERS NEILB )] ) || 
            die( $cpan->error );

    This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fauthor%2Fby_ids%3Fid%3DOALDERS%26id%3DNEILB) to see the data returned by the CPAN REST API.

- `query` -> `/author`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/author`, such as:

        /author?q=Tokyo

    For example:

        my $list_obj = $cpan->author(
            query => 'Tokyo',
            from => 10,
            size => 10,
        ) || die( $cpan->error );

    will find all `authors` related to Tokyo.

    This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fauthor%3Fq%3DTokyo) to see the data returned by the CPAN REST API.

- `prefix` -> `/author/by_prefix/{prefix}`

    However, if the property `prefix` is provided, this will issue a query to the endpoint `/author/by_prefix/{prefix}`, such as:

        /author/by_prefix/O

    which will find all `authors` whose Pause ID starts with the specified prefix; in this example, the letter `O`

    For example:

        my $list_obj = $cpan->author( prefix => 'O' ) || 
            die( $cpan->error );

    This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor) objects.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fauthor%2Fby_prefix%2FO) to see the data returned by the CPAN REST API.

- `user` -> `/author/by_user`

    And if the property `user` is provided, this will issue a query to the endpoint `/author/by_user`, such as:

        /author/by_user?user=FepgBJBZQ8u92eG_TcyIGQ&user=6ZuVfdMpQzy75_Mazx2_nw

    which will fetch the information for the authors whose user ID are `FepgBJBZQ8u92eG_TcyIGQ` and `6ZuVfdMpQzy75_Mazx2_nw` (here respectively corresponding to the `authors` `OALDERS` and `HAARG`)

    For example:

        my $list_obj = $cpan->author( user => [qw( FepgBJBZQ8u92eG_TcyIGQ 6ZuVfdMpQzy75_Mazx2_nw )] ) || 
            die( $cpan->error );

    This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor) objects.

    However, note that not all `CPAN` account have a user ID, surprisingly enough.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fauthor%2Fby_user%3Fuser%3DFepgBJBZQ8u92eG_TcyIGQ%26user%3D6ZuVfdMpQzy75_Mazx2_nw) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/author/_search`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/author/_search` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

    This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor) objects.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## autocomplete

This takes a string and will issue a query to the endpoint `/search/autocomplete` to retrieve the result set based on the autocomplete search query specified, such as:

    /search/autocomplete?q=HTTP

For example:

    my $list_obj = $cpan->autocomplete( 'HTTP' ) || die( $cpan->error );

This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::File](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFile) objects.

You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsearch%2Fautocomplete%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## changes

    # Retrieves the specified distribution Changes file content
    my $change_obj = $cpan->changes( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Retrieves one or more distribution Changes file details using author and release information
    my $change_obj = $cpan->changes(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36'
    ) || die( $cpan->error );

    # Same:
    my $change_obj = $cpan->changes( release => 'OALDERS/HTTP-Message-6.36' ) ||
        die( $cpan->error );

    # With multiple author and releases
    my $list_obj = $cpan->changes(
        author => [qw( OALDERS NEILB )],
        release => [qw( HTTP-Message-6.36 Data-HexDump-0.04 )]
    ) || die( $cpan->error );

    # Same:
    my $list_obj = $cpan->changes( release => [qw( OALDERS/HTTP-Message-6.36 NEILB/Data-HexDump-0.04 )] ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API for one or more particular `release`'s `Changes` (or `CHANGES` depending on the release) file content.

- `distribution` -> `/changes/{distribution}`

    If the property `distribution` is provided, this will issue a query to the endpoint `/changes/{distribution}` to retrieve a distribution Changes file details, such as:

        /changes/HTTP-Message

    For example:

        my $change_obj = $cpan->changes( distribution => 'HTTP-Message' ) ||
            die( $cpan->error );

    which will retrieve the `Changes` file information for the **latest** `release` of the specified `distribution`, and return a [Net::API::CPAN::Changes](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AChanges) object upon success.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fchanges%2FHTTP-Message) to see the data returned by the CPAN REST API.

- `release` -> `/changes/`
- `author` and `release` -> `/changes/{author}/{release}`

    If the properties `author` and `release` have been provided or that the value of the property `release` has the form `author`/`release`, this will issue a query to the endpoint `/changes/{author}/{release}` to retrieve an author distribution Changes file details:

        /changes/OALDERS/HTTP-Message-6.36

    For example:

        my $change_obj = $cpan->changes(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36'
        ) || die( $cpan->error );
        # or
        my $change_obj = $cpan->changes( release => 'OALDERS/HTTP-Message-6.36' ) ||
            die( $cpan->error );

    which will retrieve the `Changes` file information for the specified `release`, and return, upon success, a [Net::API::CPAN::Changes](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AChanges) object.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fchanges%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

- \[`author`\] and \[`release`\] -> `/author/by_releases`

    And, if both properties `author` and `release` have been provided and are both an array reference of equal size, this will issue a query to the endpoint `/author/by_releases` to retrieve one or more distribution Changes file details using the specified author and release information, such as:

        /changes/by_releases?release=OALDERS%2FHTTP-Message-6.37&release=NEILB%2FData-HexDump-0.04

    For example:

        my $list_obj = $cpan->changes(
            author => [qw( OALDERS NEILB )],
            release => [qw( HTTP-Message-6.36 Data-HexDump-0.04 )]
        ) || die( $cpan->error );

    Alternatively, you can provide the property `release` having, as value, an array reference of `author`/`release`, such as:

        my $list_obj = $cpan->changes(
            release => [qw(
                OALDERS/HTTP-Message-6.36
                NEILB/Data-HexDump-0.04
            )]
        ) || die( $cpan->error );

    which will retrieve the `Changes` file information for the specified `releases`, and return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Changes](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AChanges) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fchanges%2Fby_releases%3Frelease%3DOALDERS%252FHTTP-Message-6.37%26release%3DNEILB%252FData-HexDump-0.04) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## clientinfo

This issue a query to the endpoint `https://clientinfo.metacpan.org` and retrieves the information of the various base URL.

It returns an hash reference with the following structure:

    {
        future => {
            domain => "https://fastapi.metacpan.org/",
            url => "https://fastapi.metacpan.org/v1/",
            version => "v1",
        },
        production => {
            domain => "https://fastapi.metacpan.org/",
            url => "https://fastapi.metacpan.org/v1/",
            version => "v1",
        },
        testing => {
            domain => "https://fastapi.metacpan.org/",
            url => "https://fastapi.metacpan.org/v1/",
            version => "v1",
        },
    }

Each of the URL is an [URL](https://metacpan.org/pod/URL) object.

## contributor

    # Retrieves a list of module contributed to by the specified PauseID
    my $list_obj = $cpan->contributor( author => 'OALDERS' ) ||
        die( $cpan->error );

    # Retrieves a list of module contributors details
    my $list_obj = $cpan->contributor(
        author => 'OALDERS'
        release => 'HTTP-Message-6.37'
    ) || die( $cpan->error );

This method is used to query the CPAN REST API for either the list of `releases` a CPAN account has contributed to, or to get the list of `contributors` for a specified `release`.

- `author` -> `/contributor/by_pauseid/{author}`

    If the property `author` is provided, this will issue a query to the endpoint `/contributor/by_pauseid/{author}` to retrieve a list of module contributed to by the specified PauseID, such as:

        /contributor/by_pauseid/OALDERS

    For example:

        my $list_obj = $cpan->contributor( author => 'OALDERS' ) ||
            die( $cpan->error );

    This will, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Contributor](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AContributor) objects containing the details of the release to which the specified `author` has contributed.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fcontributor%2Fby_pauseid%2FOALDERS) to see the data returned by the CPAN REST API.

- `author` and `release` -> `/contributor/{author}/{release}`

    And if the properties `author` and `release` are provided, this will issue a query to the endpoint `/contributor/{author}/{release}` to retrieve a list of release contributors details, such as:

        /contributor/OALDERS/HTTP-Message-6.36

    For example:

        my $list_obj = $cpan->contributor(
            author => 'OALDERS'
            release => 'HTTP-Message-6.37'
        ) || die( $cpan->error );

    This will, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Contributor](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AContributor) objects containing the specified `release` information and the `pauseid` of all the `authors` who have contributed to the specified `release`.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fcontributor%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## cover

This method is used to query the CPAN REST API to the endpoint `/v1/cover/{release}` to get the `cover` information including `distribution` name, `release` name, `version` and download `URL`, such as:

    /cover/HTTP-Message-6.37

For example:

    my $cover_obj = $cpan->cover(
        release => 'HTTP-Message-6.37',
    ) || die( $cpan->error );

It returns, upon success, a [Net::API::CPAN::Cover](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ACover) object.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## diff

    # Retrieves a diff of two files with output as JSON
    my $diff_obj = $cpan->diff(
        file1 => 'AcREzFgg3ExIrFTURa0QJfn8nto',
        file2 => 'Ies7Ysw0GjCxUU6Wj_WzI9s8ysU',
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

    # Retrieves a diff of two files with output as plain text
    my $diff_text = $cpan->diff(
        file1 => 'AcREzFgg3ExIrFTURa0QJfn8nto',
        file2 => 'Ies7Ysw0GjCxUU6Wj_WzI9s8ysU',
        # Default
        accept => 'text/plain',
    ) || die( $cpan->error );

    # Retrieves a diff of two releases with output as JSON
    my $diff_obj = $cpan->diff(
        author1 => 'OALDERS',
        # This is optional if it is the same
        author2 => 'OALDERS',
        release1 => 'HTTP-Message-6.35'
        release2 => 'HTTP-Message-6.36'
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

    # Retrieves a diff of two releases with output as plain text
    my $diff_text = $cpan->diff(
        author1 => 'OALDERS',
        # This is optional if it is the same
        author2 => 'OALDERS',
        release1 => 'HTTP-Message-6.35'
        release2 => 'HTTP-Message-6.36'
        # Default
        accept => 'text/plain',
    ) || die( $cpan->error );

    # Retrieves a diff of the latest release and its previous version with output as JSON
    my $diff_obj = $cpan->diff(
        distribution => 'HTTP-Message',
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

    # Retrieves a diff of the latest release and its previous version with output as plain text
    my $diff_text = $cpan->diff(
        distribution => 'HTTP-Message',
        # Default
        accept => 'text/plain',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to get the `diff` output between 2 files, or 2 releases.

- `file1` and `file2` -> `/diff/file/{file1}/{file2}`

    If the properties `file1` and `file2` are provided, this will issue a query to the endpoint `/diff/file/{file1}/{file2}`, such as:

        /diff/file/AcREzFgg3ExIrFTURa0QJfn8nto/Ies7Ysw0GjCxUU6Wj_WzI9s8ysU

    The result returned will depend on the optional `accept` property, which is, by default `application/json`, but can also be set to `text/plain`.

    When set to `application/json`, this will retrieve the result as `JSON` data and return a [Net::API::CPAN::Diff](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADiff) object. If this is set to `text/plain`, then this will return a raw `diff` output as a string encoded in [Perl internal utf-8 encoding](https://metacpan.org/pod/perlunicode).

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fdiff%2Ffile%2FAcREzFgg3ExIrFTURa0QJfn8nto%2FIes7Ysw0GjCxUU6Wj_WzI9s8ysU) to see the data returned by the CPAN REST API.

- `author1`, `author2`, `release1`, and `release2` -> `/diff/release/{author1}/{release1}/{author2}/{release2}`

    If the properties `author1`, `author2`, `release1`, and `release2` are provided, this will issue a query to the endpoint `/diff/release/{author1}/{release1}/{author2}/{release2}`, such as:

        /diff/release/OALDERS/HTTP-Message-6.35/OALDERS/HTTP-Message-6.36

    For example:

        my $diff_obj = $cpan->diff(
            author1 => 'OALDERS',
            # This is optional if it is the same
            author2 => 'OALDERS',
            release1 => 'HTTP-Message-6.35'
            release2 => 'HTTP-Message-6.36'
            # Default
            accept => 'application/json',
        ) || die( $cpan->error );

    Note that, if `author1` and `author2` are the same, `author2` is optional.

    It is important, however, that the `release` specified with `release1` belongs to `author1` and the `release` specified with `release2` belongs to `author2`

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fdiff%2Frelease%2FOALDERS%2FHTTP-Message-6.35%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

- `distribution` -> `/diff/release/{distribution}`

    You can also specify the property `distribution`, and this will issue a query to the endpoint `/diff/release/{distribution}`, such as:

        /diff/release/HTTP-Message

    For example:

        my $diff_obj = $cpan->diff(
            distribution => 'HTTP-Message',
            # Default
            accept => 'application/json',
        ) || die( $cpan->error );

    If `accept` is set to `application/json`, which is the default value, this will return a [Net::API::CPAN::Diff](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADiff) object representing the difference between the previous version and current version for the `release` of the `distribution` specified. If, however, `accept` is set to `text/plain`, a string of the diff output will be returned encoded in [Perl internal utf-8 encoding](https://metacpan.org/pod/perlunicode).

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fdiff%2Frelease%2FHTTP-Message) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## distribution

    # Retrieves a distribution information details
    my $dist_obj = $cpan->distribution( 'HTTP-Message' ) ||
        die( $cpan->error );

    # Queries distribution information details using simple search
    my $list_obj = $cpan->distribution(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );
    
    # Queries distribution information details using advanced search with ElasticSearch
    my $list_obj = $cpan->distribution( $filter_object ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `distribution` information.

- `distribution` -> `/distribution/{distribution}`

    If a string representing a `distribution` is provided, it will issue a query to the endpoint `/distribution/{distribution}` to retrieve a distribution information details, such as:

        /distribution/HTTP-Message

    For example:

        my $dist_obj = $cpan->distribution( 'HTTP-Message' ) ||
            die( $cpan->error );

    This will return, upon success, a [Net::API::CPAN::Distribution](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADistribution) object.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fdistribution%2FHTTP-Message) to see the data returned by the CPAN REST API.

- `query` -> `/distribution`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/distribution`, such as:

        /distribution?q=HTTP

    For example:

        my $list_obj = $cpan->distribution(
            query => 'HTTP',
            from => 10,
            size => 10,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Distribution](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADistribution) objects.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

        You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fdistribution%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

    - [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/distribution`

        And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/distribution` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

        This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Distribution](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADistribution) objects.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## download\_url

    # Retrieve the latest release download URL information details
    my $dl_obj = $cpan->download_url( 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve the specified `module` latest `release` `download_url` information.

- `module` -> `/download_url/{module}`

    If a string representing a `module` is provided, it will issue a query to the endpoint `/download_url/{module}` to retrieve the download URL information details of the specified module, such as:

        /download_url/HTTP::Message

    This will return, upon success, a [Net::API::CPAN::DownloadUrl](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADownloadUrl) object.

    The following options are also supported:

    - `dev`

            # Retrieves a development release
            my $dl_obj = $cpan->download_url( 'HTTP::Message',
            {
                dev => 1,
                version => '>1.01',
            }) || die( $cpan->error );

        Specifies if the `release` is a development version.

    - `version`

            # Retrieve the download URL of a specific release version
            my $dl_obj = $cpan->download_url( 'HTTP::Message',
            {
                version => '1.01',
            }) || die( $cpan->error );

            # or, using a range
            my $dl_obj = $cpan->download_url( 'HTTP::Message',
            {
                version => '<=1.01',
            }) || die( $cpan->error );
            my $dl_obj = $cpan->download_url( 'HTTP::Message',
            {
                version => '>1.01,<=2.00',
            }) || die( $cpan->error );

        Specifies the version requirement or version range requirement.

        Supported range operators are `==` `!=` `<=` `>=` `<` `>` `!`

        Separate the ranges with a comma when specifying multiple ranges.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fdownload_url%2FHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## favorite

    # Queries favorites using a simple search
    my $list_obj = $cpan->favorite(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries favorites using a advanced search with ElasticSearch format
    my $list_obj = $cpan->favorite( $filter_object ) ||
        die( $cpan->error );

    # Retrieves favorites agregate by distributions as an hash reference
    # e.g.: HTTP-Message => 63
    my $hash_ref = $cpan->favorite( aggregate => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Same
    my $hash_ref = $cpan->favorite( agg => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Same with multiple distributions
    my $hash_ref = $cpan->favorite( aggregate => [qw( HTTP-Message Data-HexDump)] ) ||
        die( $cpan->error );

    # Same
    my $hash_ref = $cpan->favorite( agg => [qw( HTTP-Message Data-HexDump)] ) ||
        die( $cpan->error );

    # Retrieves list of users who favorited a distribution as an array reference
    # e.g. [ '9nGbVdZ4QhO4Ia5ZhNpjtg', 'c4QLX0YORN6-quL15MGwqg', ... ]
    my $array_ref = $cpan->favorite( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Retrieves user favorites information details
    my $list_obj = $cpan->favorite( user => 'q_15sjOkRminDY93g9DuZQ' ) ||
        die( $cpan->error );

    # Retrieves top favorite distributions a.k.a. leaderboard as an array reference
    my $array_ref = $cpan->favorite( leaderboard => 1 ) ||
        die( $cpan->error );

    # Retrieves list of recent favorite distribution
    my $list_obj = $cpan->favorite( recent => 1 ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `favorite` information.

- `query` -> `/favorite`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/favorite`, such as:

        /favorite?q=HTTP

    For example:

        my $list_obj = $cpan->favorite( query => 'HTTP' ) || 
            die( $cpan->error );

    which will find all `favorite` related to the query term `HTTP`.

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite) objects.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffavorite%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/favorite`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/favorite` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite) objects.

- `aggregate` or `agg` -> `/favorite/agg_by_distributions`

    If the property `aggregate` or `agg`, for short, is provided, this will issue a query to the endpoint `/favorite/agg_by_distributions` to retrieve favorites agregate by distributions, such as:

        /favorite/agg_by_distributions?distribution=HTTP-Message&distribution=Data-HexDump

    For example:

        my $hash_ref = $cpan->favorite( aggregate => 'HTTP-Message' ) ||
            die( $cpan->error );
        my $hash_ref = $cpan->favorite( aggregate => [qw( HTTP-Message Data-HexDump)] ) ||
            die( $cpan->error );

    The `aggregate` value can be either a string representing a `distribution`, or an array reference of `distributions`

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffavorite%2Fagg_by_distributions%3Fdistribution%3DHTTP-Message%26distribution%3DData-HexDump) to see the data returned by the CPAN REST API.

- `distribution` -> `/favorite/users_by_distribution/{distribution}`

    If the property `distribution` is provided, will issue a query to the endpoint `/favorite/users_by_distribution/{distribution}` to retrieves the list of users who favorited the specified distribution, such as:

        /favorite/users_by_distribution/HTTP-Message

    For example:

        my $array_ref = $cpan->favorite( distribution => 'HTTP-Message' ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffavorite%2Fusers_by_distribution%2FHTTP-Message) to see the data returned by the CPAN REST API.

- `user` -> `/favorite/by_user/{user}`

    If the property `user` is provided, this will issue a query to the endpoint `/favorite/by_user/{user}` to retrieve the specified user favorites information details, such as:

        /favorite/by_user/q_15sjOkRminDY93g9DuZQ

    For example:

        my $list_obj = $cpan->favorite( user => 'q_15sjOkRminDY93g9DuZQ' ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffavorite%2Fby_user%2Fq_15sjOkRminDY93g9DuZQ) to see the data returned by the CPAN REST API.

- `leaderboard` -> `/favorite/leaderboard`

    If the property `leaderboard` is provided with any value true or false does not matter, this will issue a query to the endpoint `/favorite/leaderboard` to retrieve the top favorite distributions a.k.a. leaderboard, such as:

        /favorite/leaderboard

    For example:

        my $array_ref = $cpan->favorite( leaderboard => 1 ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffavorite%2Fleaderboard) to see the data returned by the CPAN REST API.

- `recent` -> `/favorite/recent`

    Finally, if the property `recent` is provided with any value true or false does not matter, this will issue a query to the endpoint `/favorite/recent` to retrieve the list of recent favorite distributions, such as:

        /favorite/recent

    For example:

        my $list_obj = $cpan->favorite( recent => 1 ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite) objects.

    The following options are also supported:

    - `page`

        An integer representing the page offset starting from 1.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffavorite%2Frecent) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## file

    # Queries files using simple search
    my $list_obj = $cpan->file(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries files with advanced search using ElasticSearch
    my $list_obj = $cpan->file( $filter_object ) ||
        die( $cpan->error );

    # Retrieves a directory content
    my $list_obj = $cpan->file(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        dir => 'lib/HTTP',
    ) || die( $cpan->error );

    # Retrieves a file information details
    my $file_obj = $cpan->file(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `file` information.

- `query` -> `/file`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/file`, such as:

        /file?q=HTTP

    For example:

        my $list_obj = $cpan->file(
            query => 'HTTP',
            from => 10,
            size => 10,
        ) || die( $cpan->error );

    will find all `files` related to `HTTP`.

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffile%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/file`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/file` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

        my $list_obj = $cpan->file( $filter_object ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::File](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFile) objects.

- `author`, `release` and `dir` -> `/file/dir/{author}/{release}/{dir}`

    If the properties, `author`, `release` and `dir` are provided, this will issue a query to the endpoint `/file/dir/{author}/{release}/{dir}` to retrieve the specified directory content, such as:

        /file/dir/OALDERS/HTTP-Message-6.36/lib/HTTP

    For example:

        my $list_obj = $cpan->file(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            dir => 'lib/HTTP',
        ) || die( $cpan->error );

    For this to yield correct results, the `dir` specified must be a directory.

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of all the files and directories contained within the specified directory.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffile%2Fdir%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP) to see the data returned by the CPAN REST API.

- `author`, `release` and `path` -> `/file/{author}/{release}/{path}`

    If the properties, `author`, `release` and `path` are provided, this will issue a query to the endpoint `/file/{author}/{release}/{path}` to retrieve the specified file (or directory) information details, such as:

        /file/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm

    For example:

        my $file_obj = $cpan->file(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            path => 'lib/HTTP/Message.pm',
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::File](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFile) object of the information retrieved.

    Note that the path can point to either a file or a directory within the given release.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Ffile%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP%2FMessage.pm) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## first

This takes a string and will issue a query to the endpoint `/search/first` to retrieve the first result found based on the search query specified, such as:

    /search/first?q=HTTP

For example:

    my $list_obj = $cpan->first( 'HTTP' ) || die( $cpan->error );

This would, upon success, return a [Net::API::CPAN::Module](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AModule) object.

You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsearch%2Fautocomplete%2Fsuggest%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

## history

    # Retrieves the history of a given module
    my $list_obj = $cpan->history(
        type => 'module',
        module => 'HTTP::Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

    # Retrieves the history of a given distribution file
    my $list_obj = $cpan->history(
        type => 'file',
        distribution => 'HTTP-Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

    # Retrieves the history of a given module documentation
    my $list_obj = $cpan->history(
        type => 'documentation',
        module => 'HTTP::Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `file` history information.

- `module` -> `/search/history/module`

    If the property `module` is provided, this will trigger a query to the endpoint `/search/history/module` to retrieve the history of a given module, such as:

        /search/history/module/HTTP::Message/lib/HTTP/Message.pm

    For example:

        my $list_obj = $cpan->history(
            type => 'module',
            module => 'HTTP::Message',
            path => 'lib/HTTP/Message.pm',
        ) || die( $cpan->error );

    will find all `module` history related to the module `HTTP::Message`.

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsearch%2Fhistory%2Fmodule%2FHTTP%3A%3AMessage%2Flib%2FHTTP%2FMessage.pm) to see the data returned by the CPAN REST API.

- `file` -> `/search/history/file`

    If the property `file` is provided, this will trigger a query to the endpoint `/search/history/file` to retrieve the history of a given distribution file, such as:

        /search/history/file/HTTP-Message/lib/HTTP/Message.pm

    For example:

        my $list_obj = $cpan->history(
            type => 'file',
            distribution => 'HTTP-Message',
            path => 'lib/HTTP/Message.pm',
        ) || die( $cpan->error );

    will find all `files` history related to the distribution `HTTP-Message`.

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsearch%2Fhistory%2Ffile%2FHTTP-Message%2Flib%2FHTTP%2FMessage.pm) to see the data returned by the CPAN REST API.

- `documentation` -> `/search/history/documentation`

    If the property `documentation` is provided, this will trigger a query to the endpoint `/search/history/documentation` to retrieve the history of a given module documentation, such as:

        /search/history/documentation/HTTP::Message/lib/HTTP/Message.pm

    For example:

        my $list_obj = $cpan->history(
            type => 'documentation',
            module => 'HTTP::Message',
            path => 'lib/HTTP/Message.pm',
        ) || die( $cpan->error );

    will find all `documentation` history related to the module `HTTP::Message`.

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsearch%2Fhistory%2Fdocumentation%2FHTTP%3A%3AMessage%2Flib%2FHTTP%2FMessage.pm) to see the data returned by the CPAN REST API.

## mirror

    my $list_obj = $cpan->mirror;

This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object.

Actually there is no mirroring anymore, because for some time now CPAN runs on a CDN (Content Distributed Network) which performs the same result, but transparently.

See more on this [here](https://www.cpan.org/SITES.html)

This endpoint also has search capability, but given there is now only one entry, it is completely useless.

You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fmirror) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## module

    # Queries modules with a simple search
    my $list_obj = $cpan->module(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries modules with an advanced search using ElasticSearch
    my $list_obj = $cpan->module( $filter_object ) ||
        die( $cpan->error );

    # Retrieves the specified module information details
    my $module_obj = $cpan->module(
        module => 'HTTP::Message',
    ) || die( $cpan->error );

    # And if you want to join with other object types
    my $module_obj = $cpan->module(
        module => 'HTTP::Message',
        join => [qw( release author )],
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `module` information.

- `query` -> `/module`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/module`, such as:

        /module?q=HTTP

    For example:

        my $list_obj = $cpan->module( query => 'HTTP' ) || 
            die( $cpan->error );

    will find all `modules` related to `HTTP`.

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fmodule%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/module`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/module` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

- `$module` -> `/module/{module}`

    If a string representing a `module` is provided, this will be used to issue a query to the endpoint `/module/{module}` to retrieve the specified module information details, such as:

        /module/HTTP::Message

    For example:

        my $module_obj = $cpan->module(
            module => 'HTTP::Message',
            join => [qw( release author )],
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::Module](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AModule) object.

    The following options are also supported:

    - `join`

        You can join a.k.a. merge other objects data by setting `join` to that object type, such as `release` or `author`. `join` value can be either a string or an array of object types.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fmodule%2FHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## package

    # Queries packages with a simple search
    my $list_obj = $cpan->package(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries packages with an advanced search using ElasticSearch
    my $list_obj = $cpan->package( $filter_object ) ||
        die( $cpan->error );

    # Retrieves the list of a distribution packages
    my $list_obj = $cpan->package( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Retrieves the latest release and package information for the specified module
    my $package_obj = $cpan->package( 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `package` information.

- `query` -> `/package`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/package`, such as:

        /package?q=HTTP

    For example:

        my $list_obj = $cpan->package( query => 'HTTP' ) || 
            die( $cpan->error );

    will find all `packages` related to `HTTP`.

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Package](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APackage)

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpackage%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/package`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/package` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

- `distribution` -> `/package/modules/{distribution}`

    If the property `distribution` is provided, this will issue a query to the endpoint `/package/modules/{distribution}` to retrieve the list of a distribution packages, such as:

        /package/modules/HTTP-Message

    For example:

        my $list_obj = $cpan->package( distribution => 'HTTP-Message' ) ||
            die( $cpan->error );

    This would return, upon success, an [array object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) containing all the modules name provided within the specified `distribution`.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpackage%2Fmodules%2FHTTP-Message) to see the data returned by the CPAN REST API.

- `$package` -> `/package/{module}`

    If a string representing a package name is directly passed, this will issue a query to the endpoint `/package/{module}` to retrieve the latest release and package information for the specified module, such as:

        /package/HTTP::Message

    For example:

        my $package_obj = $cpan->package( 'HTTP::Message' ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::Package](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APackage) object.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpackage%2FHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## permission

    # Queries permissions with a simple search
    my $list_obj = $cpan->permission(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries permissions with an advanced search using ElasticSearch
    my $list_obj = $cpan->permission( $filter_object ) ||
        die( $cpan->error );

    # Retrieves permission information details for the specified author
    my $list_obj = $cpan->permission(
        author => 'OALDERS',
        from => 40,
        size => 20,
    ) || die( $cpan->error );

    # Retrieves permission information details for the specified module
    my $list_obj = $cpan->permission(
        module => 'HTTP::Message',
    ) || die( $cpan->error );

    # Retrieves permission information details for the specified modules
    my $list_obj = $cpan->permission(
        module => [qw( HTTP::Message Data::HexDump )],
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `package` information.

- `query` -> `/permission`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/permission`, such as:

        /permission?q=HTTP

    For example:

        my $list_obj = $cpan->permission(
            query => 'HTTP',
            from => 10,
            size => 10,
        ) || die( $cpan->error );

    will find all `permissions` related to `HTTP`.

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Permission](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APermission) objects.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpermission%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/permission`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/permission` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

- `author` -> `/permission/by_author/{author}`

    If the property `author` is provided, this will trigger a simple search query to the endpoint `/permission/by_author/{author}` to retrieve the permission information details for the specified author, such as:

        /permission/by_author/OALDERS?from=40&q=HTTP&size=20

    For example:

        my $list_obj = $cpan->permission(
            author => 'OALDERS',
            from => 40,
            size => 20,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Permission](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APermission) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpermission%2Fby_author%2FOALDERS%3Ffrom%3D40%26q%3DHTTP%26size%3D20) to see the data returned by the CPAN REST API.

- `module` -> `/permission/{module}`

    If the property `module` is provided, and its value is a string, this will issue a query to the endpoint `/permission/{module}` to retrieve permission information details for the specified module, such as:

        /permission/HTTP::Message

    For example:

        my $list_obj = $cpan->permission(
            module => 'HTTP::Message',
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::Permission](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APermission) object.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpermission%2FHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

- \[`module`\] -> `/permission/by_module`

    If the property `module` is provided, and its value is an array reference, this will issue a query to the endpoint `/permission/by_module` to retrieve permission information details for the specified modules, such as:

        /permission/by_module?module=HTTP%3A%3AMessage&module=Data%3A%3AHexDump

    For example:

        my $list_obj = $cpan->permission(
            module => [qw( HTTP::Message Data::HexDump )],
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Permission](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APermission) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpermission%2Fby_module%3Fmodule%3DHTTP%253A%253AMessage%26module%3DData%253A%253AHexDump) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## pod

    # Returns the POD of the given module in the 
    # specified release in markdown format
    my $string = $cpan->pod(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
        accept => 'text/x-markdown',
    ) || die( $cpan->error );

    # Returns the POD of the given module in 
    # markdown format
    my $string = $cpan->pod(
        module => 'HTTP::Message',
        accept => 'text/x-markdown',
    ) || die( $cpan->error );

    # Renders the specified POD code into HTML
    my $html = $cpan->pod(
        render => qq{=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n}
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `pod` documentation from specified modules and to render pod into `HTML` data.

- `author`, `release` and `path` -> `/pod/{author}/{release}/{path}`

    If the properties `author`, `release` and `path` are provided, this will issue a query to the endpoint `/pod/{author}/{release}/{path}` to retrieve the POD of the given module in the specified release, such as:

        /pod/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm

    For example:

        my $string = $cpan->pod(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            path => 'lib/HTTP/Message.pm',
            accept => 'text/x-markdown',
        ) || die( $cpan->error );

    This would return a string of data in the specified format, which can be one of `text/html`, `text/plain`, `text/x-markdown` or `text/x-pod`. By default this is `text/html`. The preferred data type is specified with the property `accept`

    The following options are also supported:

    - `accept`

        This value instructs the MetaCPAN API to return the pod data in the desired format.

        Supported formats are: `text/html`, `text/plain`, `text/x-markdown`, `text/x-pod`

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpod%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP%2FMessage.pm) to see the data returned by the CPAN REST API.

- `module` -> `/v1/pod/{module}`

    If the property `module` is provided, this will issue a query to the endpoint `/v1/pod/{module}` to retrieve the POD of the specified module, such as:

        /pod/HTTP::Message

    For example:

        my $string = $cpan->pod(
            module => 'HTTP::Message',
            accept => 'text/x-markdown',
        ) || die( $cpan->error );

    Just like the previous one, this would return a string of data in the specified format (in the above example markdown), which can be one of `text/html`, `text/plain`, `text/x-markdown` or `text/x-pod`. By default this is `text/html`. The preferred data type is specified with the property `accept`.

    The following options are also supported:

    - `accept`

        This value instructs the MetaCPAN API to return the pod data in the desired format.

        Supported formats are: `text/html`, `text/plain`, `text/x-markdown`, `text/x-pod`

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpod%2FHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

- `render` -> `/pod_render`

    If the property `render` is provided with a string of `POD` data, this will issue a query to the endpoint `/pod_render`, such as:

        /pod_render?pod=%3Dencoding+utf-8%0A%0A%3Dhead1+Hello+World%0A%0ASomething+here%0A%0A%3Doops%0A%0A%3Dcut%0A

    For example:

        my $html = $cpan->pod(
            render => qq{=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n}
        ) || die( $cpan->error );

    This would return a string of `HTML` formatted data.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fpod_render%3Fpod%3D%253Dencoding%2Butf-8%250A%250A%253Dhead1%2BHello%2BWorld%250A%250ASomething%2Bhere%250A%250A%253Doops%250A%250A%253Dcut%250A) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## rating

    # Queries permissions with a simple search
    my $list_obj = $cpan->rating(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries permissions with an advanced search using ElasticSearch format
    my $list_obj = $cpan->rating( $filter_object ) ||
        die( $cpan->error );

    # Retrieves rating information details of the specified distribution
    my $list_obj = $cpan->rating(
        distribution => 'HTTP-Tiny',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `rating` historical data for the specified search query or `distribution`.

It is worth mentioning that although this endpoint still works, CPAN Ratings has been decommissioned some time ago, and thus its usefulness is questionable.

- `query` -> `/rating`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/rating`, such as:

        /rating?q=HTTP

    For example:

        my $list_obj = $cpan->rating(
            query => 'HTTP',
            from => 10,
            size => 10,
        ) || die( $cpan->error );

    will find all `ratings` related to `HTTP`.

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frating%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/rating`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/rating` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

- `distribution` -> `/rating/by_distributions`

    If a property `distribution` is provided, this will issue a query to the endpoint `/rating/by_distributions` to retrieve rating information details of the specified distribution, such as:

        /rating/by_distributions?distribution=HTTP-Tiny

    For example:

        my $list_obj = $cpan->rating(
            distribution => 'HTTP-Tiny',
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Rating](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARating) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frating%2Fby_distributions%3Fdistribution%3DHTTP-Tiny) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## release

    # Perform a simple query
    my $list_obj = $cpan->release(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Perform an advanced query using ElasticSearch format
    my $list_obj = $cpan->release( $filter_object ) ||
        die( $cpan->error );

    # Retrieves a list of all releases for a given author
    my $list_obj = $cpan->release(
        all => 'OALDERS',
        page => 2,
        size => 100,
    ) || die( $cpan->error );

    # Retrieves a shorter list of all releases for a given author
    my $list_obj = $cpan->release( author => 'OALDERS' ) ||
        die( $cpan->error );

    # Retrieve a release information details
    my $release_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
    ) || die( $cpan->error );

    # Retrieves the latest distribution release information details
    my $release_obj = $cpan->release(
        distribution => 'HTTP-Message',
    ) || die( $cpan->error );

    # Retrieves the list of contributors for the specified distributions
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        contributors => 1,
    ) || die( $cpan->error );

    # Retrieves the list of release key files by category
    my $hash_ref = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        files => 1,
    ) || die( $cpan->error );

    # Retrieves the list of interesting files for the given release
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        # You can also use just 'interesting'
        interesting_files => 1,
    ) || die( $cpan->error );

    # Get latest releases by the specified author
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        latest => 1,
    ) || die( $cpan->error );

    # Get the latest releases for the specified distribution
    my $release_obj = $cpan->release(
        distribution => 'HTTP-Message',
        latest => 1,
    ) || die( $cpan->error );

    # Retrieves the list of modules in the specified release
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        modules => 1,
    ) || die( $cpan->error );

    # Get the list of recent releases
    my $list_obj = $cpan->release(
        recent => 1,
    ) || die( $cpan->error );

    # get all releases by versions for the specified distribution
    my $list_obj = $cpan->release(
        versions => 'HTTP-Message',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve `release` information.

- `query` -> `/release`

    If the property `query` is provided, this will trigger a simple search query to the endpoint `/release`, such as:

        /release?q=HTTP

    For example:

        my $list_obj = $cpan->release(
            query => 'HTTP',
            from => 10,
            size => 10,
        ) || die( $cpan->error );

    will find all `releases` related to `HTTP`.

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    The following options are also supported:

    - `from`

        An integer representing the offset starting from 0 within the total data.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

- [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) -> `/release`

    And if a [search filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) is passed, this will trigger a more advanced ElasticSearch query to the endpoint `/release` using the `HTTP` `POST` method. See the [Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter) module on more details on what granular queries you can execute.

- `all` -> `/release/all_by_author/{author}`

    If the property `all` is provided, this will issue a query to the endpoint `/release/all_by_author/{author}` to get all releases by the specified author, such as:

        /release/all_by_author/OALDERS?page=2&page_size=100

    For example:

        my $list_obj = $cpan->release(
            all => 'OALDERS',
            page => 2,
            size => 100,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    The following options are also supported:

    - `page`

        An integer representing the page offset starting from 1.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Fall_by_author%2FOALDERS%3Fpage%3D1%26page_size%3D100) to see the data returned by the CPAN REST API.

- `author` -> `/release/by_author/{author}`

    If the property `author` alone is provided, this will issue a query to the endpoint `/release/by_author/{author}` to get releases by author, such as:

        /release/by_author/OALDERS

    For example:

        my $list_obj = $cpan->release( author => 'OALDERS' ) ||
            die( $cpan->error );

    This would return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object upon success.

    Note that this is similar to `all`, but returns a subset of all the author's data.

    The following options are also supported:

    - `page`

        An integer representing the page offset starting from 1.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Fby_author%2FOALDERS) to see the data returned by the CPAN REST API.

- `author` and `release` -> `/v1/release/{author}/{release}`

    If the property `author` and `release` are provided, this will issue a query to the endpoint `/v1/release/{author}/{release}` tp retrieve a distribution release information, such as:

        /release/OALDERS/HTTP-Message-6.36

    For example:

        my $release_obj = $cpan->release(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
        ) || die( $cpan->error );

    This would return a [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) object upon success.

    The following options are also supported:

    - `join`

        You can join a.k.a. merge other objects data by setting `join` to that object type, such as `module` or `author`. `join` value can be either a string or an array of object types.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

- `distribution` -> `/release/{distribution}`

    If the property `distribution` alone is provided, this will issue a query to the endpoint `/release/{distribution}` to retrieve a release information details., such as:

        /release/HTTP-Message

    For example:

        my $release_obj = $cpan->release(
            distribution => 'HTTP-Message',
        ) || die( $cpan->error );

    This would return a [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) object upon success.

    The following options are also supported:

    - `join`

        You can join a.k.a. merge other objects data by setting `join` to that object type, such as `module` or `author`. `join` value can be either a string or an array of object types.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2FHTTP-Message) to see the data returned by the CPAN REST API.

- `contributors`, `author` and `release` -> `/release/contributors/{author}/{release}`

    If the property `contributors`, `author` and `release` are provided, this will issue a query to the endpoint `/release/contributors/{author}/{release}` to retrieve the list of contributors for the specified release, such as:

        /release/contributors/OALDERS/HTTP-Message-6.36

    For example:

        my $list_obj = $cpan->release(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            contributors => 1,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.
    :List> object upon success.

    The following options are also supported:

    - `join`

        You can join a.k.a. merge other objects data by setting `join` to that object type, such as `module` or `author`. `join` value can be either a string or an array of object types.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Fcontributors%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

- `files`, `author` and `release` -> `/release/files_by_category/{author}/{release}`

    If the property `files`, `author` and `release` are provided, this will issue a query to the endpoint `/release/files_by_category/{author}/{release}` to retrieve the list of key files by category for the specified release, such as:

        /release/files_by_category/OALDERS/HTTP-Message-6.36

    For example:

        my $hash_ref = $cpan->release(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            files => 1,
        ) || die( $cpan->error );

    This would return an [hash object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AHash) of the following category names, each having, as their value, an array of the specified `release` files.

    The categories are:

    - `changelog`

        This is typically the `Changes` or `CHANGES` file.

    - `contributing`

        This is typically the `CONTRIBUTING.md` file.

    - `dist`

        This is typically other files that are part of the `release`, such as `cpanfile`, `Makefile.PL`, `dist.ini`, `META.json`, `META.yml`, `MANIFEST`.

    - `install`

        This is typically the `INSTALL` file.

    - `license`

        This is typically the `LICENSE` file.

    - `other`

        This is typically the `README.md` file.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Ffiles_by_category%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

- `interesting_files`, `author` and `release` -> `/release/interesting_files/{author}/{release}`

    If the property `interesting_files` (or also just `interesting`), `author` and `release` are provided, this will issue a query to the endpoint `/release/interesting_files/{author}/{release}` to retrieve the list of release interesting files for the specified release, such as:

        /release/interesting_files/OALDERS/HTTP-Message-6.36

    For example:

        my $list_obj = $cpan->release(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            interesting_files => 1,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Finteresting_files%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

- `latest`, and `author` -> `/release/latest_by_author/{author}`

    If the property `latest`, and `author` are provided, this will issue a query to the endpoint `/release/latest_by_author/{author}` to retrieve the latest releases by the specified author, such as:

        /release/latest_by_author/OALDERS

    For example:

        my $list_obj = $cpan->release(
            author => 'OALDERS',
            latest => 1,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Flatest_by_author%2FOALDERS) to see the data returned by the CPAN REST API.

- `latest`, and `distribution` -> `/release/latest_by_distribution/{distribution}`

    If the property `latest`, and `distribution` are provided, this will issue a query to the endpoint `/release/latest_by_distribution/{distribution}` to retrieve the latest releases of the specified distribution, such as:

        /release/latest_by_distribution/HTTP-Message

    For example:

        my $release_obj = $cpan->release(
            distribution => 'HTTP-Message',
            latest => 1,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) object representing the latest `release` for the specified `distribution`.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Flatest_by_distribution%2FHTTP-Message) to see the data returned by the CPAN REST API.

- `modules`, `author`, and `release` -> `/release/modules/{author}/{release}`

    If the property `modules`, `author`, and `release` are provided, this will issue a query to the endpoint `/release/modules/{author}/{release}` to retrieve the list of modules in the specified distribution, such as:

        /release/modules/OALDERS/HTTP-Message-6.36

    For example:

        my $list_obj = $cpan->release(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            modules => 1,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    The following options are also supported:

    - `join`

        You can join a.k.a. merge other objects data by setting `join` to that object type, such as `module` or `author`. `join` value can be either a string or an array of object types.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Fmodules%2FOALDERS%2FHTTP-Message-6.36) to see the data returned by the CPAN REST API.

- `recent` -> `/release/recent`

    If the property `recent`, alone is provided, this will issue a query to the endpoint `/release/recent` to retrieve the list of recent releases, such as:

        /release/recent

    For example:

        my $list_obj = $cpan->release(
            recent => 1,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    The following options are also supported:

    - `page`

        An integer specifying the page offset starting from 1.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Frecent) to see the data returned by the CPAN REST API.

- `versions` -> `distribution`

    If the property `versions` is provided having a value representing a `distribution`, this will issue a query to the endpoint `/release/versions/{distribution}` to retrieve all releases by versions for the specified distribution, such as:

        /release/versions/HTTP-Message

    For example:

        my $list_obj = $cpan->release(
            distribution => 'HTTP-Message',
            # or, alternatively: version => '6.35,6.36,6.34',
            versions => [qw( 6.35 6.36 6.34 )],
            # Set this to true to get a raw list of version -> download URL instead of a list object
            # plain => 1,
        ) || die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of all the `distribution` versions released.

    The following options are also supported:

    - `versions`

        An array reference of versions to return, or a string specifying the version(s) to return as a comma-sepated value

    - `plain`

        A boolean value specifying whether the result should be returned in plain mode.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Fversions%2FHTTP-Message) to see the data returned by the CPAN REST API and [here for the result in plain text mode](https://explorer.metacpan.org/?url=%2Frelease%2Fversions%2FHTTP-Message%3Fplain%3D1).

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## reverse

    # Returns a list of all the modules who depend on the specified distribution
    my $list_obj = $cpan->reverse( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Returns a list of all the modules who depend on the specified module
    my $list_obj = $cpan->reverse( module => 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve reverse dependencies, i.e. releases on `CPAN` that depend on the specified `distribution` or `module`.

- `distribution` -> `/reverse_dependencies/dist/{distribution}`

    If the property `distribution` representing a distribution is provided, this will issue a query to the endpoint `/reverse_dependencies/dist/{distribution}` to retrieve a list of all the modules who depend on the specified distribution, such as:

        /reverse_dependencies/dist/HTTP-Message

    For example:

        my $list_obj = $cpan->reverse( distribution => 'HTTP-Message' ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    The following options are also supported:

    - `page`

        An integer representing the page offset starting from 1.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    - `sort`

        A string representing a field specifying how the result is sorted.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Freverse_dependencies%2Fdist%2FHTTP-Message) to see the data returned by the CPAN REST API.

- `module` -> `/reverse_dependencies/module/{module}`

    If the property `module` representing a module is provided, this will issue a query to the endpoint `/reverse_dependencies/module/{module}` to retrieve a list of all the modules who depend on the specified module, such as:

        /reverse_dependencies/module/HTTP::Message

    For example:

        my $list_obj = $cpan->reverse( module => 'HTTP::Message' ) ||
            die( $cpan->error );

    This would return, upon success, a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease) objects.

    The following options are also supported:

    - `page`

        An integer representing the page offset starting from 1.

    - `size`

        An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

    - `sort`

        A string representing a field specifying how the result is sorted.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Freverse_dependencies%2Fmodule%2FHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## reverse\_dependencies

This is an alias for ["reverse"](#reverse)

## search

Provided with an hash or hash reference of options and this performs a search query and returns a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object, or an [Net::API::CPAN::Scroll](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AScroll) depending on the type of search query requested.

There are 3 types of search query:

- 1. Using [HTTP GET method](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches)
- 2. Using [HTTP POST method](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#post-searches) with [Elastic Search query](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter)
- 3. Using [HTTP POST method](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#post-searches) with Elastic Search query using [scroll](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AScroll)

## source

    # Retrieves the source code of the given module path within the specified release
    my $string = $cpan->source(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

    # Retrieves the full source of the latest, authorized version of the specified module
    my $string = $cpan->source( module => 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve the source code or data of the specified `release` element or `module`.

- `author`, `release` and `path` -> `/source/{author}/{release}/{path}`

    If the properties `author`, `release` and `path` are provided, this will issue a query to the endpoint `/source/{author}/{release}/{path}` to retrieve the source code of the given module path within the specified release, such as:

        /source/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm

    For example:

        my $string = $cpan->source(
            author => 'OALDERS',
            release => 'HTTP-Message-6.36',
            path => 'lib/HTTP/Message.pm',
        ) || die( $cpan->error );

    This will return a string representing the source data of the file located at the specified `path` and `release`.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsource%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP%2FMessage.pm) to see the data returned by the CPAN REST API.

- `module` -> `/source/{module}`

    If the properties `module` is provided, this will issue a query to the endpoint `/source/{module}` to retrieve the full source of the latest, authorized version of the specified module, such as:

        /source/HTTP::Message

    For example:

        my $string = $cpan->source( module => 'HTTP::Message' ) ||
            die( $cpan->error );

    This will return a string representing the source data of the specified `module`.

    You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsource%2FHTTP%3A%3AMessage) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## suggest

This takes a string and will issue a query to the endpoint `/search/autocomplete/suggest` to retrieve the suggested result set based on the autocomplete search query, such as:

    /search/autocomplete/suggest?q=HTTP

For example:

    my $list_obj = $cpan->suggest( query => 'HTTP' ) || die( $cpan->error );

This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Release::Suggest](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease%3A%3ASuggest) objects.

You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsearch%2Fautocomplete%2Fsuggest%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

## top\_uploaders

This will issue a query to the endpoint `/release/top_uploaders` to retrieve an [hash object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AHash) of the top uploading `authors` with the total as the key's value, such as:

    /release/top_uploaders

For example:

    my $hash_ref = $cpan->top_uploaders || die( $cpan->error );

This would return, upon success, an [hash object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AHash) of `author` and their recent total number of `release` upload on `CPAN`

For example:

    {
        OALDERS => 12,
        NEILB => 7,
    }

The following options are also supported:

- `range`

    A string specifying the result range. Valid values are `all`, `weekly`, `monthly` or `yearly`. It defaults to `weekly`

- `size`

    An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Frelease%2Ftop_uploaders) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

## web

This takes a string and will issue a query to the endpoint `/search/web` to retrieve the result set based on the search query specified similar to the one on the MetaCPAN website, such as:

    /search/web?q=HTTP

For example:

    my $list_obj = $cpan->web(
        query => 'HTTP',
        from => 0,
        size => 10,
    ) || die( $cpan->error );

This would, upon success, return a [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList) object of [Net::API::CPAN::Module](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AModule) objects.

Search terms can be:

- can be unqualified string, such as `paging`
- can be author, such as `author:OALDERS`
- can be module, such as `module:HTTP::Message`
- can be distribution, such as `dist:HTTP-Message`

The following options are also supported:

- `collapsed`

    Boolean. When used, this forces a collapsed even when searching for a particular distribution or module name.

- `from`

    An integer that represents offset to use in the result set.

- `size`

    An integer that represents the number of results per page.

You can try it out on [CPAN Explorer](https://explorer.metacpan.org/?url=%2Fsearch%2Fweb%3Fq%3DHTTP) to see the data returned by the CPAN REST API.

Upon failure, an [error](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) will be set and `undef` will be returned in scalar context, or an empty list in list context.

# TERMINOLOGY

The MetaCPAN REST API has quite a few endpoints returning sets of data containing properties. Below are the meanings of some of those keywords:

- `author`

    For example `JOHNDOE`

    This is a `CPAN` id, and `distribution` author. It is also referred as `cpanid`

- `cpanid`

    For example `JOHNDOE`

    See `author`

- `contributor`

    For example: `JOHNDOE`

    A `contributor` is a `CPAN` author who is contributing code to an `author`'s `distribution`.

- `distribution`

    For example: `HTTP-Message`

    This is a bundle of modules distributed over `CPAN` and available for download. A `distribution` goes through a series of `releases` over the course of its lifetime.

- `favorite`

    `favorite` relates to the appreciation a `distribution` received by having registered and non-registered user marking it as one of their favorite distributions.

- `file`

    A `file` is an element of a `distribution`

- `module`

    For example `HTTP::Message`

    This has the same meaning as in Perl. See [perlmod](https://metacpan.org/pod/perlmod) for more information on Perl modules.

- `package`

    For example `HTTP::Message`

    This is similar to `module`, but a `package` is a `class` and a `module` is a file.

- `permission`

    A `permission` defines the role a user has over a `distribution` and is one of `owner` or `co_maintainer`

- `release`

    For example: `HTTP-Message-6.36`

    A `release` is a `distribution` being released with a unique version number.

- `reverse_dependencies`

    This relates to the `distributions` depending on any given `distribution`

# ERRORS

This module does not die or croak, but instead set an [error object](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException) using ["error" in Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric#error) and returns `undef` in scalar context, or an empty list in list context.

You can retrieve the latest error object set by calling [error](https://metacpan.org/pod/Module%3A%3AGeneric#error) inherited from [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric)

Errors issued by this distributions are all instances of class [Net::API::CPAN::Exception](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AException)

# METACPAN OPENAPI SPECIFICATIONS

From the information I could gather, [I have produced the specifications](https://gitlab.com/jackdeguest/Net-API-CPAN/-/blob/master/build/cpan-openapi-spec-3.0.0.pl) for [Open API](https://spec.openapis.org/oas/v3.0.0) v3.0.0 for your reference. You can also find it [here](https://gitlab.com/jackdeguest/Net-API-CPAN/-/blob/master/build/cpan-openapi-spec-3.0.0.json) in `JSON` format.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[Meta CPAN API documentation](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md)

[https://metacpan.org/](https://metacpan.org/), [https://www.cpan.org/](https://www.cpan.org/)

[Net::API::CPAN::Activity](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AActivity), [Net::API::CPAN::Author](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AAuthor), [Net::API::CPAN::Changes](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AChanges), [Net::API::CPAN::Changes::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AChanges%3A%3ARelease), [Net::API::CPAN::Contributor](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AContributor), [Net::API::CPAN::Cover](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ACover), [Net::API::CPAN::Diff](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADiff), [Net::API::CPAN::Distribution](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADistribution), [Net::API::CPAN::DownloadUrl](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ADownloadUrl), [Net::API::CPAN::Favorite](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFavorite), [Net::API::CPAN::File](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFile), [Net::API::CPAN::Module](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AModule), [Net::API::CPAN::Package](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APackage), [Net::API::CPAN::Permission](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3APermission), [Net::API::CPAN::Rating](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARating), [Net::API::CPAN::Release](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3ARelease)

[Net::API::CPAN::Filter](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AFilter), [Net::API::CPAN::List](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AList), [Net::API::CPAN::Scroll](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AScroll)

[Net::API::CPAN::Mock](https://metacpan.org/pod/Net%3A%3AAPI%3A%3ACPAN%3A%3AMock)

# COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
