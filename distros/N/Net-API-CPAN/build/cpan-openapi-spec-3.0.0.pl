{
    components => 
    {
        schemas =>
        {
            # NOTE: schemas -> api_errors
            api_errors =>
            {
                description => q{Definition of standard errors returned by MetaCPAN API},
                properties =>
                {
                    code =>
                    {
                        description => q{A 3 digits code representing the error.},
                        maxLength => 3,
                        type => 'string',
                    },
                    message =>
                    {
                        description => q{The error message designed for human consumption with more details about the error.},
                        maxLength => 20000,
                        type => 'string',
                    },
                    param =>
                    {
                        description => q{If the error is parameter-specific, the parameter related to the error.},
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                required => [
                    'code',
                ],
                title => 'APIErrors',
                type => 'object',
            },
            # NOTE: schemas -> author_mapping
            author_mapping =>
            {
                description => q{This is the object representing the availble fields for the [author object](https://explorer.metacpan.org/?url=/author/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/profile",
                    }
                },
                title => 'AuthorMapping',
                type => 'object',
            },
            # NOTE: schemas -> changes
            changes =>
            {
                description => q{This is the object representing a MetaCPAN [module changes file](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches)},
                properties =>
                {
                    author =>
                    {
                        type => 'string',
                    },
                    authorized =>
                    {
                        type => 'boolean',
                    },
                    binary =>
                    {
                        type => 'boolean',
                    },
                    category =>
                    {
                        type => 'string',
                    },
                    content =>
                    {
                        type => 'string',
                    },
                    date =>
                    {
                        type => 'string',
                        format => 'date-time',
                    },
                    deprecated =>
                    {
                        type => 'boolean',
                    },
                    directory =>
                    {
                        type => 'boolean',
                    },
                    dist_fav_count =>
                    {
                        type => 'integer',
                    },
                    distribution =>
                    {
                        type => 'string',
                    },
                    download_url =>
                    {
                        type => 'string',
                    },
                    id =>
                    {
                        type => 'string',
                    },
                    indexed =>
                    {
                        type => 'boolean',
                    },
                    level =>
                    {
                        type => 'integer',
                    },
                    maturity =>
                    {
                        type => 'string',
                    },
                    mime =>
                    {
                        type => 'string',
                    },
                    module =>
                    {
                        items => 
                        {
                            type => 'string',
                        },
                        type => 'array',
                    },
                    name =>
                    {
                        type => 'string',
                    },
                    path =>
                    {
                        type => 'string',
                    },
                    pod =>
                    {
                        type => 'string',
                    },
                    release =>
                    {
                        type => 'string',
                    },
                    sloc =>
                    {
                        type => 'integer',
                    },
                    slop =>
                    {
                        type => 'integer',
                    },
                    'stat' =>
                    {
                        properties =>
                        {
                            mode =>
                            {
                                type => 'integer',
                            },
                            mtime => 
                            {
                                type => 'integer',
                            },
                            size => 
                            {
                                type => 'integer',
                            }
                        },
                    },
                    status =>
                    {
                        type => 'string',
                    },
                    version =>
                    {
                        description => 'Package version string',
                        type => 'string',
                    },
                    version_numified =>
                    {
                        type => 'number',
                        format => 'float',
                    }
                },
                title => 'Changes',
                type => 'object',
            },
            # NOTE: schemas -> contributor
            contributor =>
            {
                description => q{This is the object representing contributors},
                properties =>
                {
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    pauseid => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    release_author => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    release_name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                title => 'Contributor',
                type => 'object',
            },
            # NOTE: schemas -> contributor_mapping
            contributor_mapping =>
            {
                description => q{This is the object representing the availble fields for the [contributor object](https://explorer.metacpan.org/?url=/contributor/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/contributor",
                    }
                },
                title => 'ContributorMapping',
                type => 'object',
            },
            # NOTE: schemas -> cover
            cover =>
            {
                description => q{This is the object representing a MetaCPAN [module coverage](http://cpancover.com/)},
                properties =>
                {
                    criteria => 
                    {
                        description => 'CPAN Cover results',
                        properties =>
                        {
                            branch =>
                            {
                                description => 'Percentage of branch code coverage',
                                type => 'number',
                            },
                            condition =>
                            {
                                description => 'Percentage of condition code coverage',
                                type => 'number',
                            },
                            statement =>
                            {
                                description => 'Percentage of statement code coverage',
                                type => 'number',
                            },
                            subroutine =>
                            {
                                description => 'Percentage of subroutine code coverage',
                                type => 'number',
                            },
                            total =>
                            {
                                description => 'Percentage of total code coverage',
                                type => 'number',
                            }
                        },
                    },
                    distribution =>
                    {
                        description => 'Name of the distribution',
                        type => 'string',
                    },
                    release =>
                    {
                        description => 'Package name with version',
                        type => 'string',
                    },
                    url =>
                    {
                        description => 'URL for cpancover report',
                        type => 'string',
                    },
                    version =>
                    {
                        description => 'Package version string',
                        type => 'string',
                    },
                },
                title => 'Cover',
                type => 'object',
            },
            # NOTE: schemas -> diff
            diff =>
            {
                description => q{This is the object representing difference in multiple files between 2 releases},
                properties =>
                {
                    diff =>
                    {
                        description => 'This property is only available when comparing 2 file IDs',
                        type => 'string',
                    },
                    source => 
                    {
                        type => 'string',
                    },
                    statistics =>
                    {
                        items =>
                        {
                            properties =>
                            {
                                deletions =>
                                {
                                    type => 'integer',
                                },
                                diff =>
                                {
                                    type => 'string',
                                },
                                insertions =>
                                {
                                    type => 'integer',
                                },
                                source =>
                                {
                                    type => 'string',
                                },
                                target =>
                                {
                                    type => 'string',
                                },
                            },
                            type => 'object',
                        },
                        type => 'array',
                    },
                    target =>
                    {
                        type => 'string',
                    },
                },
                title => 'Diff',
                type => 'object',
            },
            # NOTE: schemas -> distribution
            distribution =>
            {
                description => q{This is the object representing a MetaCPAN [author distribution](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#distributiondistribution)},
                properties =>
                {
                    bugs => 
                    {
                        properties =>
                        {
                            github =>
                            {
                                properties =>
                                {
                                    active => { type => 'integer' },
                                    closed => { type => 'integer' },
                                    'open' => { type => 'integer' },
                                    source =>
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                            },
                            rt =>
                            {
                                properties =>
                                {
                                    '<html>' => { type => 'number' },
                                    active => { type => 'integer' },
                                    closed => { type => 'integer' },
                                    new => { type => 'integer' },
                                    'open' => { type => 'integer' },
                                    patched => { type => 'integer' },
                                    rejected => { type => 'integer' },
                                    resolved => { type => 'integer' },
                                    source =>
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    stalled => { type => 'integer' },
                                },
                            },
                        },
                    },
                    external_package => 
                    {
                        properties =>
                        {
                            cygwin =>
                            {
                                maxLength => 2048,
                                type => 'string',
                            },
                            debian =>
                            {
                                maxLength => 2048,
                                type => 'string',
                            },
                            fedora =>
                            {
                                maxLength => 2048,
                                type => 'string',
                            },
                        },
                    },
                    name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    river => 
                    {
                        properties =>
                        {
                            bucket => { type => 'integer' },
                            bus_factor => { type => 'integer' },
                            immediate => { type => 'integer' },
                            total => { type => 'integer' },
                        },
                    },
                },
                title => 'Distribution',
                type => 'object',
            },
            # NOTE: schemas -> distribution_mapping
            distribution_mapping =>
            {
                description => q{This is the object representing the availble fields for the [distribution object](https://explorer.metacpan.org/?url=/distribution/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/distribution",
                    }
                },
                title => 'DistributionMapping',
                type => 'object',
            },
            # NOTE: schemas -> distributions
            distributions =>
            {
                description => q{This is the object representing a list of distributions.},
                properties =>
                {
                    distributions => 
                    {
                        additionalProperties =>
                        {
                            type => 'object',
                            properties =>
                            {
                                avg =>
                                {
                                    format => 'float',
                                    type => 'number',
                                },
                                count =>
                                {
                                    type => 'integer',
                                },
                                max =>
                                {
                                    format => 'float',
                                    type => 'number',
                                },
                                min =>
                                {
                                    format => 'float',
                                    type => 'number',
                                },
                                sum =>
                                {
                                    format => 'float',
                                    type => 'number',
                                },
                            },
                        },
                        type => 'object',
                        description => 'This contains dynamic properties named after the perl distribution name, such as "HTTP-Message"',
                    },
                    took =>
                    {
                        type => 'integer',
                    },
                    total =>
                    {
                        type => 'integer',
                    },
                },
                title => 'Distributions',
                type => 'object',
            },
            # NOTE: schemas -> download_url
            download_url =>
            {
                description => q{This is the object representing a MetaCPAN [distribution download URL](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#download_urlmodule)},
                properties =>
                {
                    checksum_md5 =>
                    {
                        type => 'string',
                    },
                    checksum_sha256 =>
                    {
                        type => 'string',
                    },
                    date =>
                    {
                        description => 'An ISO 8601 datetime',
                        type => 'string',
                        format => 'date-time',
                    },
                    download_url =>
                    {
                        type => 'string',
                    },
                    release =>
                    {
                        type => 'string',
                    },
                    status =>
                    {
                        type => 'string',
                    },
                    version =>
                    {
                        type => 'string',
                    },
                },
                title => 'DownloadURL',
                type => 'object',
            },
            # NOTE: schemas -> elastic_search
            # Taken from ElasticSearch specs <https://www.elastic.co/guide/en/cloud/current/ec-openapi-specification.html>
            elastic_search =>
            {
                description => "An Elasticsearch search request with a subset of options.",
                properties =>
                {
                    _source =>
                    {
                        properties => {},
                        type => "object",
                    },
                    from =>
                    {
                        format => "int32",
                        type => "integer",
                    },
                    query =>
                    {
                        '$ref' => "#/components/schemas/es_query_container"
                    },
                    size =>
                    {
                        description => "The maximum number of search results to return.",
                        format => "int32",
                        type => "integer",
                    },
                    sort =>
                    {
                        description => "An array of fields to sort the search results by.",
                        items =>
                        {
                            properties => {},
                            type => "object",
                        },
                        type => "array",
                    },
                },
                title => 'Search',
                type => "object",
            },
            # NOTE: schemas -> es_bool_query
            es_bool_query =>
            {
                description => "A query for documents that match boolean combinations of other queries.",
                properties =>
                {
                    filter =>
                    {
                        items =>
                        {
                            '$ref' => "#/components/schemas/es_query_container"
                        },
                        type => "array",
                    },
                    minimum_should_match =>
                    {
                        description => "The minimum number of optional should clauses to match.",
                        format => "int32",
                        type => "integer",
                    },
                    must =>
                    {
                        items =>
                        {
                            '$ref' => "#/components/schemas/es_query_container"
                        },
                        type => "array",
                    },
                    must_not =>
                    {
                        items =>
                        {
                            '$ref' => "#/components/schemas/es_query_container"
                        },
                        type => "array",
                    },
                    should =>
                    {
                        items =>
                        {
                            '$ref' => "#/components/schemas/es_query_container"
                        },
                        type => "array",
                    },
                },
                type => "object",
            },
            # NOTE: schemas -> es_exists_query
            es_exists_query =>
            {
                description => "Matches documents that have at least one non-`null` value in the original field.",
                properties =>
                {
                    field =>
                    {
                        description => "The field to check for non-null values in.",
                        type => "string",
                    },
                },
                required => ["field"],
                type => "object",
            },
            # NOTE: schemas -> es_match_query
            es_match_query =>
            {
                description => "Consumes and analyzes text, numbers, and dates, then constructs a query.",
                properties =>
                {
                    analyzer =>
                    {
                        description => "The analyzer that will be used to perform the analysis process on the text. Defaults to the analyzer that was used to index the field.",
                        type => "string",
                    },
                    minimum_should_match =>
                    {
                        description => "The minimum number of optional should clauses to match.",
                        format => "int32",
                        type => "integer",
                    },
                    operator =>
                    {
                        description => "The operator flag can be set to or or and to control the boolean clauses (defaults to or).",
                        type => "string",
                    },
                    query =>
                    {
                        description => "The text/numeric/date to query for.",
                        type => "string",
                    },
                },
                required => ["query"],
                type => "object",
            },
            # NOTE: schemas -> es_match_all_query
            es_match_all_query =>
            {
                description => "A query that matches all documents.",
                type => "object",
            },
            # NOTE: schemas -> es_match_none_query
            es_match_none_query =>
            {
                description => "A query that doesn't match any documents.",
                type => "object",
            },
            # NOTE: schemas -> es_nested_query
            es_nested_query =>
            {
                description => "A query that matches nested objects.",
                properties =>
                {
                    path =>
                    {
                        description => "The path to the nested object.",
                        type => "string"
                    },
                    query =>
                    {
                        '$ref' => "#/components/schemas/es_query_container",
                        description => "The actual query to execute on the nested objects.",
                    },
                    score_mode =>
                    {
                        description => "Allows to specify how inner children matching affects score of the parent. Refer to the Elasticsearch documentation for details.",
                        enum => [qw( avg sum min max none )],
                        type => "string",
                    },
                },
                required => [qw( path query )],
                type => "object",
            },
            # NOTE: schemas -> es_prefix_query
            es_prefix_query =>
            {
                description => "The query that matches documents with fields that contain terms with a specified, not analyzed, prefix.",
                properties =>
                {
                    boost =>
                    {
                        description => "An optional boost value to apply to the query.",
                        format => "float",
                        type => "number",
                    },
                    value =>
                    {
                        description => "The prefix to search for.",
                        type => "string"
                    },
                },
                required => ["value"],
                type => "object",
            },
            # NOTE: schemas -> es_query_container
            es_query_container =>
            {
                description => "The container for all of the allowed Elasticsearch queries. Specify only one property each time.",
                properties =>
                {
                    bool =>
                    {
                        '$ref' => "#/components/schemas/es_bool_query"
                    },
                    exists =>
                    {
                        '$ref' => "#/components/schemas/es_exists_query"
                    },
                    match =>
                    {
                        additionalProperties =>
                        {
                            '$ref' => "#/components/schemas/es_match_query"
                        },
                        type => "object",
                    },
                    match_all =>
                    {
                        '$ref' => "#/components/schemas/es_match_all_query"
                    },
                    match_none =>
                    {
                        '$ref' => "#/components/schemas/es_match_none_query"
                    },
                    nested =>
                    {
                        '$ref' => "#/components/schemas/es_nested_query"
                    },
                    prefix =>
                    {
                        additionalProperties =>
                        {
                            '$ref' => "#/components/schemas/es_prefix_query"
                        },
                        type => "object",
                    },
                    query_string =>
                    {
                        '$ref' => "#/components/schemas/es_query_string_query"
                    },
                    range =>
                    {
                        additionalProperties =>
                        {
                            '$ref' => "#/components/schemas/es_range_query"
                        },
                        type => "object",
                    },
                    simple_query_string =>
                    {
                        '$ref' => "#/components/schemas/es_simple_query_string_query"
                    },
                    term =>
                    {
                        additionalProperties =>
                        {
                            '$ref' => "#/components/schemas/es_term_query"
                        },
                        type => "object",
                    },
                },
                type => "object",
            },
            # NOTE: schemas -> es_query_string_query
            es_query_string_query =>
            {
                description => "A query that uses the strict query string syntax for parsing. Will return an error for invalid syntax.",
                properties =>
                {
                    allow_leading_wildcard =>
                    {
                        description => "When set, * or ? are allowed as the first character. Defaults to false.",
                        type => "boolean",
                    },
                    analyzer =>
                    {
                        description => "The analyzer used to analyze each term of the query when creating composite queries.",
                        type => "string",
                    },
                    default_field =>
                    {
                        description => "The default field for query terms if no prefix field is specified.",
                        type => "string",
                    },
                    default_operator =>
                    {
                        description => "The default operator used if no explicit operator is specified.",
                        type => "string",
                    },
                    query =>
                    {
                        description => "The actual query to be parsed.",
                        type => "string",
                    },
                },
                required => ["query"],
                type => "object",
            },
            # NOTE: schemas -> es_range_query
            es_range_query =>
            {
                description => "The query that matches documents with fields that contain terms within a specified range.",
                properties =>
                {
                    boost =>
                    {
                        description => "An optional boost value to apply to the query.",
                        format => "float",
                        type => "number",
                    },
                    format =>
                    {
                        description => "Formatted dates will be parsed using the format specified on the date field by default, but it can be overridden by passing the format parameter.",
                        type => "string",
                    },
                    gt =>
                    {
                        description => "Greater-than",
                        properties => {},
                        type => "object"
                    },
                    gte =>
                    {
                        description => "Greater-than or equal to",
                        properties => {},
                        type => "object",
                    },
                    lt =>
                    {
                        description => "Less-than",
                        properties => {},
                        type => "object",
                    },
                    lte =>
                    {
                        description => "Less-than or equal to.",
                        properties => {},
                        type => "object",
                    },
                    time_zone =>
                    {
                        description => "Dates can be converted from another timezone to UTC either by specifying the time zone in the date value itself (if the format accepts it), or it can be specified as the time_zone parameter.",
                        type => "string",
                    },
                },
                type => "object",
            },
            # NOTE: schemas -> es_simple_query_string_query
            es_simple_query_string_query =>
            {
                description => "A query that uses simple query string syntax. Will ignore invalid syntax.",
                properties =>
                {
                    analyze_wildcard =>
                    {
                        description => "If `true`, the query attempts to analyze wildcard terms. Defaults to `false`.",
                        type => "boolean",
                    },
                    analyzer =>
                    {
                        description => "The name of the analyzer to use to convert the query text into tokens.",
                        type => "string",
                    },
                    auto_generate_synonyms_phrase_query =>
                    {
                        description => "If `true`, the parse creates a `match_phrase` uery for each multi-position token. Defaults to `true`.",
                        type => "boolean",
                    },
                    default_operator =>
                    {
                        description => "The boolean operator used to combine the terms of the query. Valid values are `OR` (default) and `AND`.",
                        type => "string",
                    },
                    fields =>
                    {
                        description => "Array of fields to search",
                        items =>
                        {
                            type => "string"
                        },
                        type => "array",
                    },
                    flags =>
                    {
                        description => "List of enabled operators for the simple query string syntax. Defaults to `ALL`.",
                        type => "string",
                    },
                    fuzzy_max_expansions =>
                    {
                        description => "Maximum number of terms to which the query expands for fuzzy matching. Defaults to 50.",
                        format => "int32",
                        type => "integer",
                    },
                    fuzzy_prefix_length =>
                    {
                        description => "Number of beginning characters left unchanged for fuzzy matching. Defaults to 0.",
                        format => "int32",
                        type => "integer",
                    },
                    fuzzy_transpositions =>
                    {
                        description => "If `true`, edits for fuzzy matching include transpositions of two adjacent characters. Defaults to `false`.",
                        type => "boolean",
                    },
                    lenient =>
                    {
                        description => "If `true`, format-based errors, such as providing a text value for a numeric field are ignored. Defaults to `false`.",
                        type => "boolean",
                    },
                    minimum_should_match =>
                    {
                        description => "Minimum number of clauses that must match for a document to be returned.",
                        type => "string",
                    },
                    query =>
                    {
                        description => "The query expressed in simple query string syntax.",
                        type => "string",
                    },
                    quote_field_suffix =>
                    {
                        description => "Suffix appended to quoted text in the query string.",
                        type => "string",
                    },
                },
                required => ["query"],
                type => "object",
            },
            # NOTE: schemas -> es_term_query
            es_term_query =>
            {
                description => "A query for documents that contain the specified term in the inverted index.",
                properties =>
                {
                    value =>
                    {
                        description => "The exact value to query for.",
                        type => "string"
                    },
                },
                required => ["value"],
                type => "object",
            },
            # NOTE: schemas -> error
            error =>
            {
                description => "An error response from the MetaCPAN API",
                properties =>
                {
                    error =>
                    {
                        '$ref' => '#/components/schemas/api_errors'
                    }
                },
                required => [
                    'error'
                ],
                title => 'Error',
                type => 'object',
            },
            # NOTE: schemas -> favorite
            favorite =>
            {
                description => q{This is the object representing favorites},
                properties =>
                {
                    author => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    date => 
                    {
                        description => 'ISO8601 date format',
                        type => 'string',
                        format => 'date-time',
                    },
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    id => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    release => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    user => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                title => 'Favorite',
                type => 'object',
            },
            # NOTE: schemas -> favorites
            favorites =>
            {
                description => q{This is the object representing a user favorites},
                properties =>
                {
                    favorites =>
                    {
                        items =>
                        {
                            '$ref' => '#/components/schemas/favorite',
                        },
                        type => 'array',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                },
                title => 'Favorites',
                type => 'object',
            },
            # NOTE: schemas -> favorite_mapping
            favorite_mapping =>
            {
                description => q{This is the object representing the availble fields for the [favorite object](https://explorer.metacpan.org/?url=/favorite/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/favorite",
                    }
                },
                title => 'FavoriteMapping',
                type => 'object',
            },
            # NOTE: schemas -> file
            file =>
            {
                description => q{This is the object representing a file},
                properties =>
                {
                    abstract => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    author => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    authorized => { type => 'boolean' },
                    binary => { type => 'boolean' },
                    date =>
                    {
                        description => 'ISO8601 date format',
                        type => 'string',
                        format => 'date-time',
                    },
                    deprecated => { type => 'boolean' },
                    description => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    dir => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    directory => { type => 'boolean' },
                    dist_fav_count => { type => 'integer' },
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    documentation => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    download_url => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    id => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    indexed => { type => 'boolean' },
                    level => { type => 'integer' },
                    maturity => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    mime => 
                    {
                        example => 'text/x-script.perl-module',
                        maxLength => 2048,
                        type => 'string',
                    },
                    # See <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Document/File.pm#L150>
                    module => 
                    {
                        items =>
                        {
                            '$ref' => '#/components/schemas/module',
                        },
                        type => 'array',
                    },
                    name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    path => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    pod => 
                    {
                        type => 'string',
                    },
                    pod_lines => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    release => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    sloc => { type => 'integer' },
                    slop => { type => 'integer' },
                    stat => 
                    {
                        properties =>
                        {
                            gid => { type => 'number' },
                            mode => { type => 'integer' },
                            mtime => { type => 'integer' },
                            size => { type => 'integer' },
                            uid => { type => 'number' },
                        },
                    },
                    status => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    # TODO Clueless as to what that could be. Find out
                    suggest => {},
                    version => { type => 'string' },
                    version_numified => { type => 'number' },
                },
                title => 'File',
                type => 'object',
            },
            # NOTE: schemas -> file_snapshot
            file_snapshot =>
            {
                description => q{This is the object representing a file snapshot},
                properties =>
                {
                    author => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    category => { type => 'string' },
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    documentation => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    path => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    pod_lines => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    release => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    status => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                title => 'FileSnapshot',
                type => 'object',
            },
            # NOTE: schemas -> file_preview
            file_preview =>
            {
                description => q{This represents a file preview used in endpoint `/file/dir`},
                properties =>
                {
                    directory => { type => 'boolean' },
                    documentation => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    mime => 
                    {
                        example => 'text/x-script.perl-module',
                        maxLength => 2048,
                        type => 'string',
                    },
                    name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    path => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    slop => { type => 'integer' },
                    'stat.mime' => { type => 'integer' },
                    'stat.size' => { type => 'integer' },
                },
                title => 'FilePreview',
                type => 'object',
            },
            # NOTE: schemas -> file_mapping
            file_mapping =>
            {
                description => q{This is the object representing the availble fields for the [file object](https://explorer.metacpan.org/?url=/module/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/file",
                    }
                },
                title => 'FileMapping',
                type => 'object',
            },
            # NOTE: schemas -> files
            files =>
            {
                description => q{This is the object representing a list of files},
                properties =>
                {
                    files =>
                    {
                        items =>
                        {
                            '$ref' => '#/components/schemas/file',
                        },
                        type => 'array',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                },
                title => 'Files',
                type => 'object',
            },
            # NOTE: schemas -> files_categories
            files_categories =>
            {
                description => q{This is the object representing a list of files by categories},
                properties =>
                {
                    categories =>
                    {
                        properties =>
                        {
                            changelog =>
                            {
                                items => 
                                {
                                    '$ref' => '#/components/schemas/file_snapshot',
                                },
                                type => 'array',
                            },
                            contributing =>
                            {
                                items => 
                                {
                                    '$ref' => '#/components/schemas/file_snapshot',
                                },
                                type => 'array',
                            },
                            dist =>
                            {
                                items => 
                                {
                                    '$ref' => '#/components/schemas/file_snapshot',
                                },
                                type => 'array',
                            },
                            license =>
                            {
                                items => 
                                {
                                    '$ref' => '#/components/schemas/file_snapshot',
                                },
                                type => 'array',
                            },
                            other =>
                            {
                                items => 
                                {
                                    '$ref' => '#/components/schemas/file_snapshot',
                                },
                                type => 'array',
                            },
                        },
                        type => 'object',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                },
                title => 'FilesCategories',
                type => 'object',
            },
            # NOTE: schemas -> files_interesting
            files_interesting =>
            {
                description => q{This is the object representing a list of files},
                properties =>
                {
                    files =>
                    {
                        items =>
                        {
                            '$ref' => '#/components/schemas/file_snapshot',
                        },
                        type => 'array',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                },
                title => 'FilesInteresting',
                type => 'object',
            },
            # NOTE: schemas -> metadata
            metadata =>
            {
                properties =>
                {
                    abstract =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    author =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    dynamic_config =>
                    {
                        type => 'boolean',
                    },
                    generated_by =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    license => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    meta_spec => 
                    {
                        properties =>
                        {
                            url =>
                            {
                                maxLength => 2048,
                                type => 'string',
                            },
                            version =>
                            {
                                type => 'integer',
                            }
                        },
                    },
                    name =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    no_index =>
                    {
                        properties =>
                        {
                            directory =>
                            {
                                maxLength => 2048,
                                type => 'string'
                            },
                            package =>
                            {
                                maxLength => 2048,
                                type => 'string'
                            }
                        }
                    },
                    prereqs =>
                    {
                        properties =>
                        {
                            build =>
                            {
                                properties =>
                                {
                                    requires =>
                                    {
                                        additionalProperties =>
                                        {
                                            description => "Key-value pairs of module names with their version number",
                                            type => 'string',
                                        },
                                    }
                                }
                            },
                            configure =>
                            {
                                properties =>
                                {
                                    requires =>
                                    {
                                        additionalProperties =>
                                        {
                                            description => "Key-value pairs of module names with their version number",
                                            type => 'string',
                                        },
                                    }
                                }
                            },
                            runtime =>
                            {
                                properties =>
                                {
                                    requires =>
                                    {
                                        additionalProperties =>
                                        {
                                            description => "Key-value pairs of module names with their version number",
                                            type => 'string',
                                        },
                                    }
                                }
                            },
                            test =>
                            {
                                properties =>
                                {
                                    requires =>
                                    {
                                        additionalProperties =>
                                        {
                                            description => "Key-value pairs of module names with their version number",
                                            type => 'string',
                                        },
                                    }
                                }
                            }
                        }
                    },
                    release_status =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    resources =>
                    {
                        properties => 
                        {
                            bugtracker =>
                            {
                                properties =>
                                {
                                    web =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                    type =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    }
                                }
                            },
                            repository =>
                            {
                                properties =>
                                {
                                    web =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                    type =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    }
                                }
                            },
                            homepage =>
                            {
                                type => 'string'
                            },
                            license =>
                            {
                                type => 'string'
                            }
                        },
                        type => 'object'
                    },
                    version =>
                    {
                        type => 'string'
                    }
                },
                title => 'Metadata',
                type => 'object',
            },
            # NOTE: schemas -> mirror
            mirror =>
            {
                description => q{This is the object representing a mirror},
                properties =>
                {
                    aka_name =>
                    {
                        type => 'string',
                    },
                    A_or_CNAME =>
                    {
                        type => 'string',
                    },
                    ccode =>
                    {
                        description => 'A 2-characters ISO 3166 country code',
                        maxLength => 2,
                        type => 'string',
                    },
                    city =>
                    {
                        type => 'string',
                    },
                    contact =>
                    {
                        items => 
                        {
                            properties =>
                            {
                                contact_site =>
                                {
                                    type => 'string',
                                },
                                contact_user =>
                                {
                                    type => 'string',
                                },
                            },
                            type => 'object'
                        },
                        type => 'array',
                    },
                    continent =>
                    {
                        type => 'string',
                    },
                    country =>
                    {
                        type => 'string',
                    },
                    distance =>
                    {
                        type => 'string',
                    },
                    distance =>
                    {
                        type => 'string',
                    },
                    dnsrr =>
                    {
                        type => 'string',
                    },
                    ftp =>
                    {
                        type => 'string',
                    },
                    freq =>
                    {
                        type => 'string',
                    },
                    http =>
                    {
                        type => 'string',
                    },
                    inceptdate =>
                    {
                        type => 'string',
                        format => 'date-time',
                    },
                    location =>
                    {
                        items =>
                        {
                            type => 'string',
                        },
                        type => 'array',
                    },
                    name =>
                    {
                        type => 'string',
                    },
                    note =>
                    {
                        type => 'string',
                    },
                    org =>
                    {
                        type => 'string',
                    },
                    region =>
                    {
                        type => 'string',
                    },
                    reitredate =>
                    {
                        type => 'string',
                        format => 'date-time',
                    },
                    rsync =>
                    {
                        type => 'string',
                    },
                    src =>
                    {
                        type => 'string',
                    },
                    tz =>
                    {
                        type => 'string',
                    },
                },
                title => 'Mirror',
                type => 'object',
            },
            # NOTE: schemas -> mirrors
            mirrors =>
            {
                description => q{This is the object representing a list of mirrors},
                properties =>
                {
                    mirrors => 
                    {
                        items =>
                        {
                            '$ref' => '#/components/schemas/mirror',
                        },
                        type => 'array',
                    },
                    total =>
                    {
                        type => 'integer',
                    },
                    took =>
                    {
                        type => 'integer',
                    },
                },
                title => 'Mirrors',
                type => 'object',
            },
            # NOTE: schemas -> module
            module =>
            {
                description => q{This is the object representing a module},
                properties =>
                {
                    abstract => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    # NOTE: This property is not found in file object
                    associated_pod => { type => 'string' },
                    author => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    authorized => { type => 'boolean' },
                    binary => { type => 'boolean' },
                    date =>
                    {
                        description => 'ISO8601 date format',
                        type => 'string',
                        format => 'date-time',
                    },
                    deprecated => { type => 'boolean' },
                    description => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    dir => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    directory => { type => 'boolean' },
                    dist_fav_count => { type => 'integer' },
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    documentation => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    download_url => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    id => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    indexed => { type => 'boolean' },
                    level => { type => 'integer' },
                    maturity => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    mime => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    # See <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Document/File.pm#L150>
                    module => 
                    {
                        '$ref' => '#/components/schemas/module',
                    },
                    name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    path => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    pod => 
                    {
                        type => 'string',
                    },
                    pod_lines => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    release => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    sloc => { type => 'integer' },
                    slop => { type => 'integer' },
                    stat => 
                    {
                        properties =>
                        {
                            gid => { type => 'number' },
                            mode => { type => 'integer' },
                            mtime => { type => 'integer' },
                            size => { type => 'integer' },
                            uid => { type => 'number' },
                        },
                    },
                    status => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    # TODO Clueless as to what that could be. Find out
                    suggest => {},
                    version => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    version_numified => { type => 'number' },
                },
                title => 'Module',
                type => 'object',
            },
            # NOTE: schemas -> module_mapping
            module_mapping =>
            {
                description => q{This is the object representing the availble fields for the [module object](https://explorer.metacpan.org/?url=/module/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/module",
                    }
                },
                title => 'ModuleMapping',
                type => 'object',
            },
            # NOTE: schemas -> package
            package =>
            {
                description => q{This is the object representing a MetaCPAN [module package](https://github.com/metacpan/metacpan-api/blob/master/lib/MetaCPAN/Document/Package.pm)},
                properties =>
                {
                    author => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    dist_version => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    file => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    module_name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    version => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                title => 'Package',
                type => 'object',
            },
            # NOTE: schemas -> permission
            permission =>
            {
                description => q{This is the object representing a MetaCPAN [module permission](https://github.com/metacpan/metacpan-api/blob/master/lib/MetaCPAN/Document/Permission.pm)},
                properties =>
                {
                    co_maintainers => 
                    {
                        items =>
                        {
                            maxLength => 2048,
                            type => 'string',
                        },
                        type => 'array',
                    },
                    module_name => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    owner => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                title => 'Permission',
                type => 'object',
            },
            # NOTE: schemas -> permissions
            permissions =>
            {
                description => q{This is the object representing a user permissions},
                properties =>
                {
                    permissions =>
                    {
                        items =>
                        {
                            properties =>
                            {
                                co_maintainers =>
                                {
                                    items =>
                                    {
                                        description => "List of co-maintainer's pause ID",
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    type => 'array',
                                },
                                module_name =>
                                {
                                    example => 'Bundle::DBI',
                                    maxLength => 2048,
                                    type => 'string',
                                },
                                owner =>
                                {
                                    description => "This is the owner's pause ID",
                                    example => 'TIMB',
                                    maxLength => 2048,
                                    type => 'string',
                                },
                            },
                            type => 'object',
                        },
                        type => 'array',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                },
                title => 'Permissions',
                type => 'object',
            },
            # NOTE: schemas -> profile
            profile =>
            {
                description => q{This is the object representing a MetaCPAN [author profile](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#authorauthor)},
                properties =>
                {
                    asciiname => 
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    blog => 
                    {
                        properties =>
                        {
                            feed => 
                            {
                                maxLength => 2048,
                                type => 'string'
                            },
                            url => 
                            {
                                maxLength => 2048,
                                type => 'string'
                            },
                        },
                    },
                    city => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    country => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    donation => 
                    {
                        items =>
                        {
                            anyOf => [
                            {
                                properties =>
                                {
                                    id => 
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                    name =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                            }],
                        },
                        type => 'array',
                    },
                    email => 
                    {
                        items =>
                        {
                            maxLength => 2048,
                            type => 'string',
                        },
                        type => 'array',
                    },
                    gravatar_url => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    is_pause_custodial_account => { type => 'boolean' },
                    # NOTE: although 'links' is present in data returned, it is undocumented
                    links =>
                    {
                        description => "An hash of key-URI pairs",
                        properties =>
                        {
                            backpan_directory => { type => 'string' },
                            cpan_directory => { type => 'string' },
                            cpantesters_matrix => { type => 'string' },
                            cpantesters_reports => { type => 'string' },
                            cpants => { type => 'string' },
                            metacpan_explorer => { type => 'string' },
                            repology => { type => 'string' },
                        },
                    },
                    # NOTE: location -> [ 52.847098, -8.98849 ]
                    location => 
                    {
                        items => 
                        {
                            type => 'number',
                            format => 'float',
                        },
                        type => 'array',
                    },
                    name => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    pauseid => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    perlmongers => 
                    {
                        properties => 
                        {
                            name =>
                            {
                                maxLength => 2048,
                                type => 'string'
                            },
                            url =>
                            {
                                maxLength => 2048,
                                type => 'string'
                            },
                        },
                    },
                    profile => 
                    {
                        items =>
                        {
                            properties =>
                            {
                                id =>
                                {
                                    maxLength => 2048,
                                    type => 'string'
                                },
                                name =>
                                {
                                    maxLength => 2048,
                                    type => 'string'
                                },
                            },
                            type => 'object',
                        },
                        type => 'array',
                    },
                    # NOTE: 'release_count' is present in data returned by the REST API, but is undocumented
                    release_count =>
                    {
                        properties =>
                        {
                            'backpan-only' => { type => 'integer' },
                            cpan => { type => 'integer' },
                            latest => { type => 'integer' },
                        },
                    },
                    region => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    updated => 
                    {
                        type => 'string',
                        format => 'date-time',
                    },
                    user => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    website => 
                    {
                        items =>
                        {
                            maxLength => 2048,
                            type => 'string',
                        },
                        type => 'array',
                    },
                },
                title => 'Profile',
                type => 'object',
            },
            # NOTE: schemas -> rating
            rating =>
            {
                description => q{This is the object representing a rating)},
                properties =>
                {
                    author => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    date => 
                    {
                        description => 'ISO8601 datetime',
                        type => 'string',
                        format => 'date-time',
                    },
                    # See <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Document/Rating.pm#L12>
                    details => 
                    {
                        properties =>
                        {
                            description =>
                            {
                                maxLength => 2048,
                                type => 'string',
                            },
                        },
                    },
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    helpful => 
                    {
                        items =>
                        {
                            properties =>
                            {
                                user =>
                                {
                                    maxLength => 2048,
                                    type => 'string'
                                },
                                value => { type => 'boolean' },
                            },
                            type => 'object',
                        },
                        type => 'array',
                    },
                    rating => { type => 'number' },
                    release => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    user => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                title => 'Rating',
                type => 'object',
            },
            # NOTE: schemas -> rating_mapping
            rating_mapping =>
            {
                description => q{This is the object representing the availble fields for the [rating object](https://explorer.metacpan.org/?url=/rating/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/rating",
                    }
                },
                title => 'RatingMapping',
                type => 'object',
            },
            # NOTE: schemas -> release
            release =>
            {
                description => q{This is the object representing a release)},
                properties =>
                {
                    abstract => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    archive => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    author => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    authorized => { type => 'boolean' },
                    changes_file => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    checksum_md5 => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    checksum_sha256 => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    date => 
                    {
                        description => 'ISO8601 datetime',
                        type => 'string',
                        format => 'date-time',
                    },
                    dependency => 
                    {
                        items => 
                        {
                            type => 'object',
                            properties =>
                            {
                                module =>
                                {
                                    maxLength => 2048,
                                    type => 'string'
                                },
                                phase =>
                                {
                                    maxLength => 2048,
                                    type => 'string'
                                },
                                relationship =>
                                {
                                    maxLength => 2048,
                                    type => 'string'
                                },
                                version =>
                                {
                                    maxLength => 2048,
                                    type => 'string'
                                },
                            },
                        },
                        type => 'array',
                    },
                    deprecated => { type => 'boolean' },
                    distribution => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    download_url => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    first => { type => 'boolean' },
                    id => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    license => 
                    {
                        items => 
                        {
                            # e.g.: perl_5
                            maxLength => 2048,
                            type => 'string',
                        },
                        type => 'array',
                    },
                    main_module => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    maturity => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    metadata =>
                    {
                        '$ref' => '#/components/schemas/metadata',
                    },
                    name => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    provides => 
                    {
                        items =>
                        {
                            maxLength => 2048,
                            type => 'string'
                        },
                        type => 'array'
                    },
                    # See <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Types/TypeTiny.pm#L74>
                    resources => 
                    {
                        properties =>
                        {
                            bugtracker =>
                            {
                                properties =>
                                {
                                    mailto =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                    web =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                            },
                            homepage =>
                            {
                                maxLength => 2048,
                                type => 'string'
                            },
                            license =>
                            {
                                items =>
                                {
                                    maxLength => 2048,
                                    type => 'string',
                                },
                                type => 'array',
                            },
                            repository =>
                            {
                                properties =>
                                {
                                    type =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                    url =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                    web =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                            },
                        },
                    },
                    stat => 
                    {
                        properties =>
                        {
                            gid => { type => 'number' },
                            mode => { type => 'integer' },
                            mtime => { type => 'integer' },
                            size => { type => 'integer' },
                            uid => { type => 'number' },
                        },
                    },
                    status => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    tests => 
                    {
                        properties =>
                        {
                            fail => { type => 'integer' },
                            na => { type => 'integer' },
                            pass => { type => 'integer' },
                            unknown => { type => 'integer' },
                        },
                    },
                    version => 
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                    version_numified => { type => 'number' },
                },
                title => 'Release',
                type => 'object',
            },
            # NOTE: schemas -> release_recents
            release_recents =>
            {
                description => q{This is the object representing a list of recent releases},
                properties =>
                {
                    releases =>
                    {
                        items =>
                        {
                            properties =>
                            {
                                abstract =>
                                {
                                    type => 'string',
                                },
                                author =>
                                {
                                    type => 'string',
                                },
                                date =>
                                {
                                    type => 'string',
                                    format => 'date-time',
                                },
                                distribution =>
                                {
                                    type => 'string',
                                },
                                name =>
                                {
                                    type => 'string',
                                },
                                status =>
                                {
                                    type => 'string',
                                },
                            },
                            type => 'object',
                        },
                        type => 'array',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                },
                title => 'ReleaseRecents',
                type => 'object',
            },
            # NOTE: schemas -> release_mapping
            release_mapping =>
            {
                description => q{This is the object representing the availble fields for the [release object](https://explorer.metacpan.org/?url=/release/_mapping).},
                properties => 
                {
                    schema =>
                    {
                        '$ref' => "#/components/schemas/release",
                    }
                },
                title => 'ReleaseMapping',
                type => 'object',
            },
            # NOTE: schemas -> releases
            releases =>
            {
                description => q{This is the object representing a list of releases},
                properties =>
                {
                    releases =>
                    {
                        items =>
                        {
                            '$ref' => '#/components/schemas/release',
                        },
                        type => 'array',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                },
                title => 'Releases',
                type => 'object',
            },
            # NOTE: schemas -> result_set
            result_set =>
            {
                description => q{This is the object representing a search result set)},
                properties =>
                {
                    hits => 
                    {
                        properties =>
                        {
                            hits => 
                            {
                                items => 
                                {
                                    properties =>
                                    {
                                        _id => { type => 'string' },
                                        _index => 
                                        {
                                            description => "For example: cpan_v1_01",
                                            type => "string",
                                        },
                                        _score => { type => 'number' },
                                        _source => 
                                        {
                                            oneOf => [
                                                { '$ref' => '#/components/schemas/profile' },
                                                { '$ref' => '#/components/schemas/distribution' },
                                                { '$ref' => '#/components/schemas/favorite' },
                                                { '$ref' => '#/components/schemas/file' },
                                                { '$ref' => '#/components/schemas/rating' },
                                                { '$ref' => '#/components/schemas/release' },
                                            ],
                                        },
                                        _type => 
                                        {
                                            enum => [qw( author distribution favorite file rating release )],
                                            type => 'string',
                                        },
                                    },
                                    type => 'object',
                                },
                                type => 'array',
                            },
                            total => { type => 'integer' },
                            max_score => { type => 'number' },
                        },
                    },
                    _shards => 
                    {
                        properties =>
                        {
                            total =>  { type => 'integer' },
                            successful => { type => 'integer' },
                            failed => { type => 'integer' },
                        },
                    },
                    took => { type => 'integer' },
                    timed_out => { type => 'boolean' },
                },
                title => 'ResultSet',
                type => 'object',
            },
            # NOTE: schemas -> result_web_set
            result_web_set =>
            {
                description => q{This is the object representing a web search result set)},
                properties =>
                {
                    collapsed => 
                    {
                        type => 'boolean',
                    },
                    results =>
                    {
                        items => 
                        {
                            properties =>
                            {
                                distribution =>
                                {
                                    type => 'string',
                                },
                                hits =>
                                {
                                    items =>
                                    {
                                        abstract =>
                                        {
                                            type => 'string',
                                        },
                                        author =>
                                        {
                                            type => 'string',
                                        },
                                        authorized =>
                                        {
                                            type => 'boolean',
                                        },
                                        date =>
                                        {
                                            type => 'datetime',
                                        },
                                        description =>
                                        {
                                            type => 'string',
                                        },
                                        distribution =>
                                        {
                                            type => 'string',
                                        },
                                        documentation =>
                                        {
                                            type => 'string',
                                        },
                                        favorites =>
                                        {
                                            type => 'integer',
                                        },
                                        id =>
                                        {
                                            type => 'string',
                                        },
                                        'index' =>
                                        {
                                            type => 'boolean',
                                        },
                                        path =>
                                        {
                                            type => 'string',
                                        },
                                        pod_lines =>
                                        {
                                            items =>
                                            {
                                                type => 'integer',
                                            },
                                            type => 'array',
                                        },
                                        release =>
                                        {
                                            type => 'string',
                                        },
                                        score =>
                                        {
                                            type => 'float',
                                        },
                                        status =>
                                        {
                                            type => 'string',
                                        },
                                    },
                                    type => 'array',
                                },
                                total => 
                                {
                                    type => 'integer',
                                },
                            },
                        },
                        type => 'array',
                    },
                    took => 
                    {
                        type => 'integer',
                    },
                    total => 
                    {
                        type => 'integer',
                    },
                },
            },
            # NOTE: schemas -> reverse_dependencies
            reverse_dependencies =>
            {
                description => q{This is the object representing a reverse dependencies result set)},
                properties =>
                {
                    data => 
                    {
                        items =>
                        {
                            '$ref' => '#/components/schemas/release',
                        },
                        type => 'array',
                    },
                    took => { type => 'integer' },
                    timed_out => { type => 'boolean' },
                },
                title => 'ReverseDependencies',
                type => 'object',
            },
            # NOTE: schemas -> river
            river =>
            {
                description => q{This is the object representing a distribution river)},
                example => '/v1/distribution/river/HTTP-Message',
                properties =>
                {
                    river => 
                    {
                        properties =>
                        {
                            module =>
                            {
                                properties =>
                                {
                                    bus_factor =>
                                    {
                                        type => 'integer',
                                    },
                                    bucket => 
                                    {
                                        type => 'integer',
                                    },
                                    immediate => 
                                    {
                                        type => 'integer',
                                    },
                                    total => 
                                    {
                                        type => 'integer',
                                    },
                                },
                                type => 'object',
                                example => 'HTTP-Message',
                            },
                        },
                        type => 'object'
                    },
                },
                title => 'River',
                type => 'object',
            },
            # NOTE: schemas -> scroll
            scroll =>
            {
                description => q{This is the object representing a scroll search follow-on query)},
                properties => 
                {
                    scroll =>
                    {
                        description => "Specifies the [scroll query time to live](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                        type => 'string',
                    },
                    size =>
                    {
                        description => "Specifies the [scroll page size](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                        type => 'integer',
                    },
                    scroll_id =>
                    {
                        description => "Specifies the [search scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                        type => 'string',
                    },
                },
                required => ["scroll", "scroll_id"],
                title => 'Scroll search',
                type => 'object',
            },
            # NOTE: schemas -> scroll_result_set
            scroll_result_set =>
            {
                description => q{This is the object representing a scroll search result set)},
                allOf => [
                    { '$ref' => '#/components/schemas/result_set' },
                    {
                        properties =>
                        {
                            _scroll_id => 
                            {
                                type => 'string',
                            },
                        },
                        type => 'object',
                    }
                ],
                title => 'ResultSet',
            },
        },
    },
    info =>
    {
        contact =>
        {
            email => 'admin@metacpan.org',
            name => 'CPAN Administrators',
            url => 'https://metacpan.org',
        },
        description => 'The MetaCPAN REST API. Please see https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md for more details.',
        termsOfService => "https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#being-polite",
        title => 'MetaCPAN API',
        version => '2023-07-27',
    },
    openapi => '3.0.0',
    paths =>
    {
        # NOTE: /v1/activity
        '/v1/activity' =>
        {
            get =>
            {
                description => 'Retrieves the release activity for the last 24 months',
                example => 'curl https://fastapi.metacpan.org/v1/activity?author=OALDERS&res=1M',
                operationId => 'GetActivity',
                parameters => [
                {
                    description => 'An optional author ID',
                    example => 'OALDERS',
                    in => 'query',
                    name => 'author',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'An optional distribution name',
                    example => 'HTTP-Message',
                    in => 'query',
                    name => 'distribution',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'An optional module used as a dependency.',
                    example => 'HTTP::Message',
                    in => 'query',
                    name => 'module',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'To show only new distributions',
                    example => 'n',
                    in => 'query',
                    name => 'new_dists',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( n )],
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The aggregation interval. See [ElasticSearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries)',
                    example => '1M',
                    in => 'query',
                    name => 'res',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( n )],
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        activity =>
                                        {
                                            items =>
                                            {
                                                type => 'integer',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post =>
            {
                description => 'Retrieves the release activity for the last 24 months',
                example => 'curl https://fastapi.metacpan.org/v1/activity?author=OALDERS&res=1M',
                operationId => 'PostActivity',
                parameters => [
                {
                    description => 'An optional author ID',
                    example => 'OALDERS',
                    in => 'query',
                    name => 'author',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'An optional distribution name',
                    example => 'HTTP-Message',
                    in => 'query',
                    name => 'distribution',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'An optional module used as a dependency.',
                    example => 'HTTP::Message',
                    in => 'query',
                    name => 'module',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'To show only new distributions',
                    example => 'n',
                    in => 'query',
                    name => 'new_dists',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( n )],
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The aggregation interval. See [ElasticSearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries)',
                    example => '1M',
                    in => 'query',
                    name => 'res',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( n )],
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    description => 'Although the `POST` method is supported, the API does not recognise JSON payload, but only query string.',
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        activity =>
                                        {
                                            items =>
                                            {
                                                type => 'integer',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/author
        '/v1/author' =>
        {
            get => 
            {
                description => 'Retrieves authors information details using a simple search.',
                example => 'curl https://fastapi.metacpan.org/v1/author?q=OALDERS',
                operationId => 'GetAuthor',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves authors information details using a simple search.',
                example => q{curl -XPOST https://fastapi.metacpan.org/v1/author -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
    "query": { "filtered": {
        "query": { "match_all":{} },
        "filter": {
            "and": [
                { "term": { "pauseid": "OALDERS" } }
            ]
        }
    }}
}
EOT},
                operationId => 'PostAuthor',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Author.pm#L45>
        # NOTE: /v1/author/by_ids
        '/v1/author/by_ids' =>
        {
            get => 
            {
                description => 'Retrieves author information details for the specified pause IDs.',
                example => 'curl https://fastapi.metacpan.org/v1/author/by_ids?id=OALDERS&id=JDEGUEST',
                operationId => 'GetAuthorByPauseID',
                parameters => [
                {
                    in => 'query',
                    name => 'id',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves author information details for the specified pause IDs.',
                example => q{curl -XPOST https://fastapi.metacpan.org/v1/author/by_ids -H 'Content-Type: application/json; charset=utf-8' -d '{"id" : ["OALDERS", "JDEGUEST"]}'},
                operationId => 'PostAuthorByPauseID',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    id => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    fields =>
                                    {
                                        description => "Specifies which fields in the response should be provided.",
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object',
                                required => ["id"],
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Author.pm#L64>
        # NOTE: /v1/author/by_prefix/{prefix}
        '/v1/author/by_prefix/{prefix}' =>
        {
            get => 
            {
                description => 'Retrieves authors information details using the initial characters of their pause ID.',
                example => q{curl https://fastapi.metacpan.org/v1/author/by_prefix/OAL},
                operationId => 'GetAuthorByPrefix',
                parameters => [
                {
                    in => 'path',
                    name => 'prefix',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies from which offset to return the results.",
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies the maximum size of the results.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves authors information details using the initial characters of their pause ID.',
                example => q{curl -XPOST https://fastapi.metacpan.org/v1/author/by_prefix/O?from=40&size=20'},
                operationId => 'PostAuthorByPrefix',
                parameters => [
                {
                    in => 'path',
                    name => 'prefix',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies from which offset to return the results.",
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies the maximum size of the results.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Author.pm#L57>
        # NOTE: /v1/author/by_user
        '/v1/author/by_user' =>
        {
            get => 
            {
                description => 'Retrieves authors information details using their user ID.',
                example => 'curl https://fastapi.metacpan.org/v1/author/by_user?user=oa-cmsLWTTOALauLxve1LA&user=2n2yGvQ4QxenVpSzkkTitQ',
                operationId => 'GetAuthorByUserIDQuery',
                parameters => [
                {
                    in => 'query',
                    name => 'user',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves authors information details using their user ID.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/author/by_user -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "user" : [
      "oa-cmsLWTTOALauLxve1LA",
      "2n2yGvQ4QxenVpSzkkTitQ"
   ]
}
EOT},
                operationId => 'PostAuthorByUserIDQuery',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    user =>
                                    {
                                        description => 'This is the user id, which is different from the PAUSEID',
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    fields =>
                                    {
                                        description => "Specifies which fields in the response should be provided.",
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object',
                                required => ["user"],
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Author.pm#L51>
        # NOTE: /v1/author/by_user/{user}
        '/v1/author/by_user/{user}' =>
        {
            get => 
            {
                description => 'Retrieves a author information details using his or her user ID.',
                example => 'curl https://fastapi.metacpan.org/v1/author/by_user/FepgBJBZQ8u92eG_TcyIGQ',
                operationId => 'GetAuthorByUserID',
                parameters => [
                {
                    description => 'This is the user id, which is different from the PAUSEID',
                    in => 'path',
                    name => 'user',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a author information details using his or her user ID.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/author/by_user/FepgBJBZQ8u92eG_TcyIGQ',
                operationId => 'PostAuthorByUserID',
                parameters => [
                {
                    description => 'This is the user id, which is different from the PAUSEID',
                    in => 'path',
                    name => 'user',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/author/{author}
        '/v1/author/{author}' =>
        {
            get => 
            {
                description => 'Retrieves an author information details.',
                example => 'curl https://fastapi.metacpan.org/v1/author/OALDERS?join=release',
                operationId => 'GetAuthorProfile',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/profile",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves an author information details.',
                example => q{curl -XPOST https://fastapi.metacpan.org/v1/author/OALDERS},
                operationId => 'PostAuthorProfile',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result. Even for the POST method, a query string is required.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/profile",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/author/_mapping
        '/v1/author/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [author object](https://explorer.metacpan.org/?url=/author/_mapping).},
                example => q{curl https://fastapi.metacpan.org/v1/author/_mapping},
                operationId => 'GetAuthorMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/author_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [author object](https://explorer.metacpan.org/?url=/author/_mapping).},
                example => q{curl -XPOST https://fastapi.metacpan.org/v1/author/_mapping},
                operationId => 'PostAuthorMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/author_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/author/_search
        '/v1/author/_search' =>
        {
            get => 
            {
                description => qq{Returns the result set for the author search.},
                example => q{curl https://fastapi.metacpan.org/v1/author/_search?from=10&q=Tokyo&size=10},
                operationId => 'GetAuthorSearch',
                parameters => [
                {
                    description => "Specifies the [search query](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches).",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the offset from which to return results.",
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the maximum number of [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result elements.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the author search.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/author/_search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "query" : {
      "filtered" : {
         "filter" : {
            "and" : [
               {
                  "term" : {
                     "city" : "Tokyo"
                  }
               }
            ]
         },
         "query" : {
            "match_all" : {}
         }
      }
   }
}
EOT},
                operationId => 'PostAuthorSearch',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/author/_search/scroll
        '/v1/author/_search/scroll' =>
        {
            'delete' =>
            {
                description => qq{Clear a [scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/paginate-search-results.html#clear-scroll)},
                operationId => 'DeleteAuthorSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                oneOf => [
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                type => 'string',
                                            },
                                        },
                                    },
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                items =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'array',
                                            },
                                        },
                                    },
                                ],
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    type => 'object',
                                    properties =>
                                    {
                                        # TODO: Need to find out what is returned upon clearing a scroll
                                        removed =>
                                        {
                                            type => 'boolean',
                                        }
                                    }
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            get => 
            {
                description => qq{Returns the result set for the author search.},
                operationId => 'GetAuthorSearchScroll',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the [scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                    in => 'query',
                    name => 'scroll_id',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the author search.},
                operationId => 'PostAuthorSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/scroll',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Changes.pm#L68>
        # NOTE: /v1/changes/by_releases
        '/v1/changes/by_releases' =>
        {
            get => 
            {
                description => 'Retrieves one or more distribution Changes file details using author and release information.',
                example => 'curl https://fastapi.metacpan.org/v1/changes/by_releases?release=OALDERS%2FHTTP-Message-6.37&release=JDEGUEST%2FModule-Generic-v0.30.1',
                operationId => 'GetChangesFileByRelease',
                parameters => [
                {
                    in => 'query',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                    description => 'One or more releases information.',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        changes => 
                                        {
                                            items =>
                                            {
                                                properties =>
                                                {
                                                    author =>
                                                    {
                                                        description => 'This is CPAN Pause ID.',
                                                        example => 'JOHNDOE',
                                                        type => 'string',
                                                    },
                                                    changes_file =>
                                                    {
                                                        description => 'This is the change file name, such as Changes or CHANGES.',
                                                        type => 'string',
                                                    },
                                                    changes_text =>
                                                    {
                                                        description => 'This contaisn the content of the release change file.',
                                                        type => 'string',
                                                    },
                                                    release =>
                                                    {
                                                        example => 'Foo-Bar-1.2345',
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves one or more distribution Changes file details using author and release information.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/changes/by_releases -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "release" : [
      "OALDERS/HTTP-Message-6.37",
      "JDEGUEST/Module-Generic-v0.30.1"
   ]
}
EOT},
                operationId => 'PostChangesFileByRelease',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    release =>
                                    {
                                        description => 'One mor more releases information',
                                        example => '{"release":"OALDERS/HTTP-Message-6.37"} or {"release":["OALDERS/HTTP-Message-6.37","Module-Generic-v0.30.1"]}',
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                required => ["release"],
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        changes => 
                                        {
                                            items =>
                                            {
                                                properties =>
                                                {
                                                    author =>
                                                    {
                                                        description => 'This is CPAN Pause ID.',
                                                        example => 'JOHNDOE',
                                                        type => 'string',
                                                    },
                                                    changes_file =>
                                                    {
                                                        description => 'This is the change file name, such as Changes or CHANGES.',
                                                        type => 'string',
                                                    },
                                                    changes_text =>
                                                    {
                                                        description => 'This contaisn the content of the release change file.',
                                                        type => 'string',
                                                    },
                                                    release =>
                                                    {
                                                        example => 'Foo-Bar-1.2345',
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Changes.pm#L55>
        # NOTE: /v1/changes/{distribution}
        '/v1/changes/{distribution}' =>
        {
            get => 
            {
                description => 'Retrieves a Changes file details based on the latest release of the specified distribution.',
                operationId => 'GetChangesFile',
                example => 'curl https://fastapi.metacpan.org/v1/changes/HTTP-Message',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/changes",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a Changes file details based on the latest release of the specified distribution.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/changes/HTTP-Message',
                operationId => 'PostChangesFile',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/changes",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/changes/{author}/{release}
        '/v1/changes/{author}/{release}' =>
        {
            get => 
            {
                description => 'Retrieves a Changes file details based on the specified release.',
                operationId => 'GetChangesFileAuthor',
                example => 'curl https://fastapi.metacpan.org/v1/changes/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    example => 'JDEGUEST',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    example => 'Nice-Try-v1.3.4',
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/changes",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a Changes file details based on the specified release.',
                operationId => 'PostChangesFileAuthor',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/changes/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    example => 'JDEGUEST',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    example => 'Nice-Try-v1.3.4',
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/changes",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Contributor.pm#L19>
        # NOTE: /v1/contributor/by_pauseid/{author}
        '/v1/contributor/by_pauseid/{author}' =>
        {
            get => 
            {
                description => 'Retrieves a list of module contributed to by the specified Pause ID.',
                example => 'curl https://fastapi.metacpan.org/v1/contributor/by_pauseid/OALDERS',
                operationId => 'GetModuleContributedByPauseID',
                parameters => [
                {
                    description => 'The author or Pause ID is an all uppercase ID, such as OALDERS',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        contributors =>
                                        {
                                            items => 
                                            {
                                                properties =>
                                                {
                                                    distribution =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    pauseid =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_author =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_name =>
                                                    {
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a list of module contributed to by the specified Pause ID.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/contributor/by_pauseid/OALDERS',
                operationId => 'PostModuleContributedByPauseID',
                parameters => [
                {
                    description => 'The author or Pause ID is an all uppercase ID, such as OALDERS',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        contributors =>
                                        {
                                            items => 
                                            {
                                                properties =>
                                                {
                                                    distribution =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    pauseid =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_author =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_name =>
                                                    {
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Contributor.pm#L13>
        # NOTE: /v1/contributor/{author}/{release}
        '/v1/contributor/{author}/{release}' =>
        {
            get => 
            {
                description => 'Retrieves a list of release contributors details.',
                example => 'curl https://fastapi.metacpan.org/v1/contributor/OALDERS/HTTP-Message-6.37',
                operationId => 'GetModuleContributors',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        contributors =>
                                        {
                                            items => 
                                            {
                                                properties =>
                                                {
                                                    distribution =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    pauseid =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_author =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_name =>
                                                    {
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a list of release contributors details.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/contributor/OALDERS/HTTP-Message-6.37',
                operationId => 'PostModuleContributors',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        contributors =>
                                        {
                                            items => 
                                            {
                                                properties =>
                                                {
                                                    distribution =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    pauseid =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_author =>
                                                    {
                                                        type => 'string',
                                                    },
                                                    release_name =>
                                                    {
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/contributor/_mapping
        '/v1/contributor/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [contributor object](https://explorer.metacpan.org/?url=/contributor/_mapping).},
                example => 'curl https://fastapi.metacpan.org/v1/contributor/_mapping',
                operationId => 'GetContributorMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/contributor_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [contributor object](https://explorer.metacpan.org/?url=/contributor/_mapping).},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/contributor/_mapping',
                operationId => 'PostContributorMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/contributor_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Changes.pm#L23>
        # NOTE: /v1/cover/{release}
        '/v1/cover/{release}' =>
        {
            get => 
            {
                description => 'Retrieves a module cover details.',
                operationId => 'GetModuleCover',
                example => 'curl https://fastapi.metacpan.org/v1/cover/HTTP-Message-6.37',
                parameters => [
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/cover",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a module cover details.',
                operationId => 'PostModuleCover',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/cover/HTTP-Message-6.37',
                parameters => [
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/cover",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/CVE.pm#L24>
        # NOTE: /v1/cve
        '/v1/cve' =>
        {
            get => 
            {
                description => 'Retrieves CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl https://fastapi.metacpan.org/v1/cve',
                operationId => 'GetCVE',
                parameters => [
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/cve',
                operationId => 'PostCVE',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    fields =>
                                    {
                                        description => "Specifies which fields in the response should be provided.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/CVE.pm#L24>
        # NOTE: /v1/cve/dist/{distribution}
        '/v1/cve/dist/{distribution}' =>
        {
            get => 
            {
                description => 'Retrieves Distribution CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl https://fastapi.metacpan.org/v1/cve/dist/HTTP-Message',
                operationId => 'GetCVEByDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies the release version.",
                    in => 'query',
                    name => 'version',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \1,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves Distribution CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/cve/dist/HTTP-Message',
                operationId => 'PostCVEByDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \1,
                                properties => 
                                {
                                    fields =>
                                    {
                                        description => "Specifies which fields in the response should be provided.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                    version =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/CVE.pm#L18>
        # NOTE: /v1/cve/release/{author}/{release}
        '/v1/cve/release/{author}/{release}' =>
        {
            get => 
            {
                description => 'Retrieves Release CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl https://fastapi.metacpan.org/v1/cve/release/OALDERS/HTTP-Message-6.36',
                operationId => 'GetCVEByAuthorRelease',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves Release CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/cve/release/OALDERS/HTTP-Message-6.36',
                operationId => 'PostCVEByAuthorRelease',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    fields =>
                                    {
                                        description => "Specifies which fields in the response should be provided.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/CVE.pm#L18>
        # NOTE: /v1/cve/{cpanid}
        '/v1/cve/{cpanid}' =>
        {
            get => 
            {
                description => 'Retrieves CPAN ID CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl https://fastapi.metacpan.org/v1/cve/OALDERS',
                operationId => 'GetCVEByCpanID',
                parameters => [
                {
                    in => 'path',
                    name => 'cpanid',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves CPAN ID CVE (Common Vulnerabilities & Exposures) information details. See [the source information](https://hackeriet.github.io/cpansa-feed/cpansa.json)',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/cve/OALDERS',
                operationId => 'PostCVEByCpanID',
                parameters => [
                {
                    in => 'path',
                    name => 'cpanid',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    fields =>
                                    {
                                        description => "Specifies which fields in the response should be provided.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Diff.pm#L19>
        # NOTE: /v1/diff/release/{distribution}
        '/v1/diff/release/{distribution}' =>
        {
            get => 
            {
                description => 'Retrieves a diff of the latest release and its previous version.',
                example => 'curl https://fastapi.metacpan.org/v1/diff/release/HTTP-Message',
                operationId => 'GetReleaseDiff',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    # See also: <https://metacpan.org/pod/Catalyst::TraitFor::Request::REST#accepted_content_types>
                    description => 'This influences the output rendered by the API. You can also use the `HTTP` headers `Accept` or `Content-Type`.',
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( application/json text/plain )],
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'application/json' =>
                            {
                                schema => 
                                {
                                    '$ref' => '#/components/schemas/diff',
                                },
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a diff of the latest release and its previous version.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/diff/release/HTTP-Message',
                operationId => 'PostReleaseDiff',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    # See also: <https://metacpan.org/pod/Catalyst::TraitFor::Request::REST#accepted_content_types>
                    description => 'This influences the output rendered by the API. You can also use the `HTTP` headers `Accept` or `Content-Type`.',
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( application/json text/plain )],
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'application/json' =>
                            {
                                schema => 
                                {
                                    '$ref' => '#/components/schemas/diff',
                                },
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Diff.pm#L19>
        # NOTE: /v1/diff/release/{author1}/{release1}/{author2}/{release2}
        '/v1/diff/release/{author1}/{release1}/{author2}/{release2}' =>
        {
            get => 
            {
                description => 'Retrieves a diff of two releases.',
                operationId => 'Get2ReleasesDiff',
                example => 'curl https://fastapi.metacpan.org/v1/diff/release/OALDERS/HTTP-Message-6.35/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    in => 'path',
                    name => 'author1',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release1',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'author2',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release2',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    # See also: <https://metacpan.org/pod/Catalyst::TraitFor::Request::REST#accepted_content_types>
                    description => 'This influences the output rendered by the API. You can also use the `HTTP` headers `Accept` or `Content-Type`.',
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( application/json text/plain )],
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'application/json' =>
                            {
                                schema => 
                                {
                                    '$ref' => '#/components/schemas/diff',
                                },
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a diff of two releases.',
                operationId => 'Post2ReleasesDiff',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/diff/release/OALDERS/HTTP-Message-6.35/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    in => 'path',
                    name => 'author1',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release1',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'author2',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release2',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    # See also: <https://metacpan.org/pod/Catalyst::TraitFor::Request::REST#accepted_content_types>
                    description => 'This influences the output rendered by the API. You can also use the `HTTP` headers `Accept` or `Content-Type`.',
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( application/json text/plain )],
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'application/json' =>
                            {
                                schema => 
                                {
                                    '$ref' => '#/components/schemas/diff',
                                },
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Diff.pm#L49C7-L49C73>
        # NOTE: /v1/diff/file/{file1}/{file2}
        '/v1/diff/file/{file1}/{file2}' =>
        {
            get => 
            {
                description => 'Retrieves a diff of two files.',
                operationId => 'Get2FilesDiff',
                example => 'curl https://fastapi.metacpan.org/v1/diff/file/AcREzFgg3ExIrFTURa0QJfn8nto/Ies7Ysw0GjCxUU6Wj_WzI9s8ysU',
                parameters => [
                {
                    in => 'path',
                    name => 'file1',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'file2',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    # See also: <https://metacpan.org/pod/Catalyst::TraitFor::Request::REST#accepted_content_types>
                    description => 'This influences the output rendered by the API. You can also use the `HTTP` headers `Accept` or `Content-Type`.',
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( application/json text/plain )],
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'application/json' =>
                            {
                                schema => 
                                {
                                    '$ref' => '#/components/schemas/diff',
                                },
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a diff of two files.',
                operationId => 'Post2FilesDiff',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/diff/file/AcREzFgg3ExIrFTURa0QJfn8nto/Ies7Ysw0GjCxUU6Wj_WzI9s8ysU',
                parameters => [
                {
                    in => 'path',
                    name => 'file1',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'file2',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    # See also: <https://metacpan.org/pod/Catalyst::TraitFor::Request::REST#accepted_content_types>
                    description => 'This influences the output rendered by the API. You can also use the `HTTP` headers `Accept` or `Content-Type`.',
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        enum => [qw( application/json text/plain )],
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'application/json' =>
                            {
                                schema => 
                                {
                                    '$ref' => '#/components/schemas/diff',
                                },
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/distribution
        '/v1/distribution' =>
        {
            get => 
            {
                description => 'Retrieves distributions information details.',
                example => 'curl https://fastapi.metacpan.org/v1/distribution?from=10&q=HTTP&size=10',
                operationId => 'GetDistribution',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves distributions information details.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/distribution -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "query" : {
      "regexp" : {
         "name" : "HTTP.*"
      }
   }
}
EOT},
                operationId => 'PostDistribution',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/distribution/{distribution}
        '/v1/distribution/{distribution}' =>
        {
            get => 
            {
                description => 'Retrieves the specified distribution latest release information.',
                example => 'curl https://fastapi.metacpan.org/v1/distribution/HTTP-Message',
                operationId => 'GetModuleDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/distribution",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves the specified distribution latest release information.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/distribution/HTTP-Message',
                operationId => 'PostModuleDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/distribution",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Distribution.pm#L18>
        # NOTE: /v1/distribution/river
        '/v1/distribution/river' =>
        {
            get => 
            {
                description => 'Returns the river of specified distributions',
                operationId => 'GetModuleDistributionRiverWithQuery',
                example => 'curl https://fastapi.metacpan.org/v1/distribution/river?distribution=HTTP-Message&distribution=Module-Generic',
                parameters => [
                {
                    description => "Specifies one or more distributions to get the river data.",
                    in => 'query',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/river",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Returns the river of specified distributions',
                operationId => 'PostModuleDistributionRiverWithJSON',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/distribution/river -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "distribution" : [
      "HTTP-Message",
      "Module-Generic"
   ]
}
EOT},
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    distribution =>
                                    {
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                required => ["distribution"],
                                type => 'object'
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/river",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Distribution.pm#L13>
        # NOTE: /v1/distribution/river/{distribution}
        '/v1/distribution/river/{distribution}' =>
        {
            get => 
            {
                description => 'Returns the river of a specific distribution.',
                operationId => 'GetModuleDistributionRiverWithParam',
                example => 'curl https://fastapi.metacpan.org/v1/distribution/river/HTTP-Message',
                parameters => [
                {
                    description => 'Distribution name',
                    example => 'HTTP-Message',
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/river",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Returns the river of a specific distribution.',
                operationId => 'PostModuleDistributionRiverWithParam',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/distribution/river/HTTP-Message',
                parameters => [
                {
                    description => 'Distribution name',
                    example => 'HTTP-Message',
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/river",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/distribution/_mapping
        '/v1/distribution/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [distribution object](https://explorer.metacpan.org/?url=/distribution/_mapping).},
                example => 'curl https://fastapi.metacpan.org/v1/distribution/_mapping',
                operationId => 'GetDistributionMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/distribution_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [distribution object](https://explorer.metacpan.org/?url=/distribution/_mapping).},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/distribution/_mapping',
                operationId => 'PostDistributionMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/distribution_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/distribution/_search
        '/v1/distribution/_search' =>
        {
            get => 
            {
                description => qq{Returns the result set for the distribution search.},
                example => 'curl https://fastapi.metacpan.org/v1/distribution/_search?q=HTTP.*&size=10',
                operationId => 'GetDistributionSearch',
                parameters => [
                {
                    description => "Specifies the [search query](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches).",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the maximum number of [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result elements.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the distribution search.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/distribution/_search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "query" : {
      "regexp" : {
         "name" : "HTTP.*"
      }
   }
}
EOT},
                operationId => 'PostDistributionSearch',
                parameters => [
                {
                    in => 'query',
                    name => 'query',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    }
                },
                {
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    }
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/distribution/_search/scroll
        '/v1/distribution/_search/scroll' =>
        {
            'delete' =>
            {
                description => qq{Clear a [scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/paginate-search-results.html#clear-scroll)},
                operationId => 'DeleteDistributionSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                oneOf => [
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                type => 'string',
                                            },
                                        },
                                    },
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                items =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'array',
                                            },
                                        },
                                    },
                                ],
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    type => 'object',
                                    properties =>
                                    {
                                        # TODO: Need to find out what is returned upon clearing a scroll
                                        removed =>
                                        {
                                            type => 'boolean',
                                        }
                                    }
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            get => 
            {
                description => qq{Returns the result set for the scroll search.},
                operationId => 'GetDistributionSearchScroll',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the [scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                    in => 'query',
                    name => 'scroll_id',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the author search.},
                operationId => 'PostDistributionSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/scroll',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/download_url/{module}
        '/v1/download_url/{module}' =>
        {
            get => 
            {
                description => qq{Retrieves a download URL for a given module.\nThe `/download_url` endpoint exists specifically for the `cpanm` client. It takes a module name with an optional version (or range of versions) and an optional `dev` flag (for development releases) and returns a `download_url` as well as some other helpful info.\n\nObviously anyone can use this endpoint, but we'll only consider changes to this endpoint after considering how `cpanm` might be affected.},
                example => 'curl https://fastapi.metacpan.org/v1/download_url/HTTP::Message',
                operationId => 'GetDownloadURL',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/download_url",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves a download URL for a given module.\nThe `/download_url` endpoint exists specifically for the `cpanm` client. It takes a module name with an optional version (or range of versions) and an optional `dev` flag (for development releases) and returns a `download_url` as well as some other helpful info.\n\nObviously anyone can use this endpoint, but we'll only consider changes to this endpoint after considering how `cpanm` might be affected.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/download_url/HTTP::Message',
                operationId => 'PostDownloadURL',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/download_url",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/favorite
        '/v1/favorite' =>
        {
            get => 
            {
                description => 'Retrieves favorites information details.',
                example => 'curl https://fastapi.metacpan.org/v1/favorite?q=HTTP&size=10',
                operationId => 'GetFavorite',
                parameters => [
                {
                    example => '/v1/favorite?q=distribution:HTTP-Message',
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves favorites information details.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/favorite -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "query" : {
      "regexp" : {
         "release" : "HTTP.*"
      }
   }
}
EOT},
                operationId => 'PostFavorite',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        example => '{"q": "distribution:HTTP-Message"}',
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Favorite.pm#L13>
        # NOTE: /v1/favorite/{user}/{distribution}
        '/v1/favorite/{user}/{distribution}' =>
        {
            get => 
            {
                description => 'Retrieves favorites information details for a specific distribution.',
                operationId => 'GetFavoriteByUserModule',
                example => 'curl https://fastapi.metacpan.org/v1/favorite/q_15sjOkRminDY93g9DuZQ/DBI',
                parameters => [
                {
                    in => 'path',
                    name => 'user',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorite",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves favorites information details for a specific distribution.',
                operationId => 'PostFavoriteByUserModule',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/favorite/q_15sjOkRminDY93g9DuZQ/DBI',
                parameters => [
                {
                    in => 'path',
                    name => 'user',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorite",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Favorite.pm#L56C34-L56C54>
        # NOTE: /v1/favorite/agg_by_distributions
        '/v1/favorite/agg_by_distributions' =>
        {
            get => 
            {
                description => 'Retrieves favorites agregate by distributions.',
                operationId => 'GetFavoriteAggregateDistribution',
                example => 'curl https://fastapi.metacpan.org/v1/favorite/agg_by_distributions?distribution=HTTP-Message&distribution=DBI',
                parameters => [
                {
                    description => "Specifies the distribution to get the favorites.",
                    example => 'Nice-Try',
                    in => 'query',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies the user to get the favorites.",
                    example => 'AhTh1sISr3eA11yW3e1rd',
                    in => 'query',
                    name => 'user',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        favorites =>
                                        {
                                            example => 'Nice:;Try',
                                            module =>
                                            {
                                                type => 'integer',
                                            },
                                            type => 'object',
                                        },
                                        myfavorites =>
                                        {
                                            module =>
                                            {
                                                type => 'integer',
                                            },
                                            type => 'object',
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves favorites agregate by distributions using JSON parameters.',
                operationId => 'PostFavoriteAggregateDistribution',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/favorite/agg_by_distributions -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "distribution" : [
      "HTTP-Message",
      "DBI"
   ]
}
EOT},
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    distribution =>
                                    {
                                        description => "Specifies the distribution to get the favorites.",
                                        example => 'Nice-Try',
                                        type => 'string',
                                        required => \1,
                                    },
                                    user =>
                                    {
                                        description => "Specifies the user to get the favorites.",
                                        example => 'AhTh1sISr3eA11yW3e1rd',
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        favorites =>
                                        {
                                            example => 'Nice:;Try',
                                            module =>
                                            {
                                                type => 'integer',
                                            },
                                            type => 'object',
                                        },
                                        myfavorites =>
                                        {
                                            module =>
                                            {
                                                type => 'integer',
                                            },
                                            type => 'object',
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Favorite.pm#L29>
        # NOTE: /v1/favorite/by_user/{user}
        '/v1/favorite/by_user/{user}' =>
        {
            get => 
            {
                description => 'Retrieves user favorites information details.',
                operationId => 'GetFavoriteByUser',
                example => 'curl https://fastapi.metacpan.org/v1/favorite/by_user/q_15sjOkRminDY93g9DuZQ',
                # XXX There is presumably an optional 'size' parmeter, but it is not working. When specifying 5, it returns 3. When specifying 10, it returns 7. POSTing it as JSON does not work.
                parameters => [
                {
                    in => 'path',
                    name => 'user',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorites",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves user favorites information details.',
                operationId => 'PostFavoriteByUser',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/favorite/by_user/q_15sjOkRminDY93g9DuZQ',
                # XXX There is presumably an optional 'size' parmeter, but it is not working. When specifying 5, it returns 3. When specifying 10, it returns 7. POSTing it as JSON does not work.
                parameters => [
                {
                    in => 'path',
                    name => 'user',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorites",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Favorite.pm#L51C25-L51C36leaderboard>
        # NOTE: /v1/favorite/leaderboard
        '/v1/favorite/leaderboard' =>
        {
            get => 
            {
                description => 'Retrieves top favorite distributions (leaderboard).',
                operationId => 'GetFavoriteLeaderboard',
                example => 'curl https://fastapi.metacpan.org/v1/favorite/leaderboard',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        leaderboard =>
                                        {
                                            items =>
                                            {
                                                properties =>
                                                {
                                                    doc_count =>
                                                    {
                                                        type => 'integer',
                                                    },
                                                    key =>
                                                    {
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                        total =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves top favorite distributions (leaderboard).',
                operationId => 'PostFavoriteLeaderboard',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/favorite/leaderboard',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        leaderboard =>
                                        {
                                            items =>
                                            {
                                                properties =>
                                                {
                                                    doc_count =>
                                                    {
                                                        type => 'integer',
                                                    },
                                                    key =>
                                                    {
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                        total =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/favorite/recent
        '/v1/favorite/recent' =>
        {
            get => 
            {
                description => 'Retrieves list of recent favorite distributions.',
                example => 'curl https://fastapi.metacpan.org/v1/favorite/recent?page=10&size=10',
                operationId => 'GetFavoriteRecent',
                parameters => [
                {
                    description => "Specifies the page offset starting from 1.",
                    in => 'query',
                    name => 'page',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies the size of the result page.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorites",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves list of recent favorite distributions.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/favorite/recent -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "page" : 10,
   "size" : 10
}
EOT},
                operationId => 'PostFavoriteRecent',
                parameters => [
                {
                    description => "Specifies the page offset starting from 1.",
                    in => 'query',
                    name => 'page',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies the size of the result page.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorites",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Favorite.pm#L35C35-L35C56>
        # NOTE: /v1/favorite/users_by_distribution/{distribution}
        '/v1/favorite/users_by_distribution/{distribution}' =>
        {
            get => 
            {
                description => 'Retrieves list of users who favorited a distribution.',
                operationId => 'GetFavoriteUsers',
                example => 'curl https://fastapi.metacpan.org/v1/favorite/users_by_distribution/HTTP-Message',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorites",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves list of users who favorited a distribution.',
                operationId => 'PostFavoriteUsers',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/favorite/users_by_distribution/HTTP-Message',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorites",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        users =>
                                        {
                                            items =>
                                            {
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/favorite/_mapping
        '/v1/favorite/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [favorite object](https://explorer.metacpan.org/?url=/favorite/_mapping).},
                operationId => 'GetFavoriteMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorite_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [favorite object](https://explorer.metacpan.org/?url=/favorite/_mapping).},
                operationId => 'PostFavoriteMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/favorite_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/favorite/_search
        '/v1/favorite/_search' =>
        {
            get => 
            {
                description => qq{Returns the result set for the favorite search.},
                example => 'curl https://fastapi.metacpan.org/v1/favorite/_search?from=40&q=HTTP&size=20',
                operationId => 'GetFavoriteSearch',
                parameters => [
                {
                    description => "Specifies the [search query](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches).",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the maximum number of [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result elements.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the favorite search.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/favorite/_search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "distribution" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostFavoriteSearch',
                parameters => [
                {
                    in => 'query',
                    name => 'query',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/favorite/_search/scroll
        '/v1/favorite/_search/scroll' =>
        {
            'delete' =>
            {
                description => qq{Clear a [scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/paginate-search-results.html#clear-scroll)},
                operationId => 'DeleteFavoriteSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                oneOf => [
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                type => 'string',
                                            },
                                        },
                                    },
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                items =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'array',
                                            },
                                        },
                                    },
                                ],
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    type => 'object',
                                    properties =>
                                    {
                                        # TODO: Need to find out what is returned upon clearing a scroll
                                        removed =>
                                        {
                                            type => 'boolean',
                                        }
                                    }
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            get => 
            {
                description => qq{Returns the result set for the favorite search.},
                operationId => 'GetFavoriteSearchScroll',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the [scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                    in => 'query',
                    name => 'scroll_id',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the favorite search.},
                operationId => 'PostFavoriteSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/scroll',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/file
        '/v1/file' =>
        {
            get => 
            {
                description => 'Queries files information details using simple search.',
                example => 'curl https://fastapi.metacpan.org/v1/file?from=40&q=HTTP&size=20',
                operationId => 'GetFile',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Queries files information details using ElasticSearch format.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/file -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "release" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostFile',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/File.pm#L31>
        # NOTE: /v1/file/{author}/{release}/{path}
        '/v1/file/{author}/{release}/{path}' =>
        {
            get => 
            {
                description => 'Retrieves a file information details specified by its release and file path.',
                operationId => 'GetFileByAuthorReleaseFilePath',
                example => 'curl https://fastapi.metacpan.org/v1/file/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm',
                parameters => [
                {
                    description => 'The author or Pause ID is an all uppercase ID, such as OALDERS',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'A distribution name.',
                    example => 'HTTP-Message-6.36',
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/file",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a file information details specified by its release and file path.',
                operationId => 'PostFileByAuthorReleaseFilePath',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/file/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm',
                parameters => [
                {
                    description => 'The author or Pause ID is an all uppercase ID, such as OALDERS',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'A distribution name.',
                    example => 'HTTP-Message-6.36',
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/file",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/File.pm#L50>
        # NOTE: /v1/file/dir/{path}
        '/v1/file/dir/{path}' =>
        {
            get => 
            {
                description => 'Retrieves a specific release directory content.',
                example => 'curl https://fastapi.metacpan.org/v1/file/dir/OALDERS/HTTP-Message-6.36/lib/HTTP',
                operationId => 'GetFilePathDirectoryContent',
                parameters => [
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        dir =>
                                        {
                                            items =>
                                            {
                                                '$ref' => "#/components/schemas/file_preview",
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves a specific release directory content.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/file/dir/OALDERS/HTTP-Message-6.36/lib/HTTP',
                operationId => 'PostFilePathDirectoryContent',
                parameters => [
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        dir =>
                                        {
                                            items =>
                                            {
                                                '$ref' => "#/components/schemas/file_preview",
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/file/_mapping
        '/v1/file/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [file object](https://explorer.metacpan.org/?url=/file/_mapping).},
                operationId => 'GetFileMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/file_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [file object](https://explorer.metacpan.org/?url=/file/_mapping).},
                operationId => 'PostFileMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/file_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/file/_search
        '/v1/file/_search' =>
        {
            get => 
            {
                description => qq{Returns the result set for the file search.},
                example => 'curl https://fastapi.metacpan.org/v1/file/_search?from=40&q=HTTP&size=20',
                operationId => 'GetFileSearch',
                parameters => [
                {
                    description => "Specifies the [search query](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches).",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the maximum number of [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result elements.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the file search.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/file/_search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "path" : ".*HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostFileSearch',
                parameters => [
                {
                    in => 'query',
                    name => 'query',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/file/_search/scroll
        '/v1/file/_search/scroll' =>
        {
            'delete' =>
            {
                description => qq{Clear a [scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/paginate-search-results.html#clear-scroll)},
                operationId => 'DeleteFileSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                oneOf => [
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                type => 'string',
                                            },
                                        },
                                    },
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                items =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'array',
                                            },
                                        },
                                    },
                                ],
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    type => 'object',
                                    properties =>
                                    {
                                        # TODO: Need to find out what is returned upon clearing a scroll
                                        removed =>
                                        {
                                            type => 'boolean',
                                        }
                                    }
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            get => 
            {
                description => qq{Returns the result set for the file search.},
                operationId => 'GetFileSearchScroll',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the [scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                    in => 'query',
                    name => 'scroll_id',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the file search.},
                operationId => 'PostFileSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/scroll',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/login/index
        '/v1/login/index' =>
        {
            get => 
            {
                description => 'Returns a login HTML page.',
                example => 'curl https://fastapi.metacpan.org/v1/login/index',
                operationId => 'GetLoginPage',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/html' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Returns a login HTML page.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/login/index',
                operationId => 'PostLoginPage',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/html' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/mirror
        '/v1/mirror' =>
        {
            get => 
            {
                description => qq{Returns a `mirrors` object containing a list of `mirror` objects. Currently, the API only returns one mirror, because CPAN now uses CDN instead of mirrors.},
                example => 'curl https://fastapi.metacpan.org/v1/mirror',
                operationId => 'GetMirror',
                parameters => [
                {
                    description => "Specifies an optional keyword to find the matching mirrors.",
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/mirrors",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns a `mirrors` object containing a list of `mirror` objects. Currently, the API only returns one mirror, because CPAN now uses CDN instead of mirrors.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/mirror',
                operationId => 'PostMirror',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" =>
                                    {
                                        description => "Specifies an optional keyword to find the matching mirrors.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/mirrors",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Mirror.pm#L12>
        # NOTE: /v1/mirror/search
        '/v1/mirror/search' =>
        {
            get => 
            {
                description => qq{Returns a `mirrors` object containing a list of `mirror` objects. Currently, the API only returns one mirror, because CPAN now uses CDN instead of mirrors.},
                example => 'curl https://fastapi.metacpan.org/v1/mirror/search?from=0&q=CPAN&size=20',
                operationId => 'GetMirrorSearch',
                parameters => [
                {
                    description => "Specifies an optional keyword to find the matching mirrors.",
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/mirrors",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns a `mirrors` object containing a list of `mirror` objects. Currently, the API only returns one mirror, because CPAN now uses CDN instead of mirrors.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/mirror/search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 0,
   "query" : {
      "regexp" : {
         "path" : ".*HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostMirrorSearch',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" =>
                                    {
                                        description => "Specifies an optional keyword to find the matching mirrors.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/mirrors",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/module
        '/v1/module' =>
        {
            get => 
            {
                description => 'Queries modules information details using simple search.',
                example => 'curl https://fastapi.metacpan.org/v1/module?from=40&q=HTTP&size=20',
                operationId => 'GetModule',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Queries modules information details using advanced ElasticSearch.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/module -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "name" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostModule',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/module/{module}
        '/v1/module/{module}' =>
        {
            get => 
            {
                description => qq{Returns the corresponding `file` of the latest version of the `module`. Considering that HTTP-Message-6.37 is the latest release, the result of [/module/HTTP::Message](https://fastapi.metacpan.org/v1/module/HTTP::Message) is the same as [/file/OALDERS/HTTP-Message-6.37/lib/HTTP/Message.pm](https://fastapi.metacpan.org/v1/file/OALDERS/HTTP-Message-6.37/lib/HTTP/Message.pm).},
                example => 'curl https://fastapi.metacpan.org/v1/module/HTTP::Message',
                operationId => 'GetModuleFile',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/file",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the corresponding `file` of the latest version of the `module`. Considering that HTTP-Message-6.37 is the latest release, the result of [/module/HTTP::Message](https://fastapi.metacpan.org/v1/module/HTTP::Message) is the same as [/file/OALDERS/HTTP-Message-6.37/lib/HTTP/Message.pm](https://fastapi.metacpan.org/v1/file/OALDERS/HTTP-Message-6.37/lib/HTTP/Message.pm).},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/module/HTTP::Message',
                operationId => 'PostModuleFile',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/file",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/module/_mapping
        '/v1/module/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [module object](https://explorer.metacpan.org/?url=/module/_mapping).},
                operationId => 'GetModuleMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/module_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [module object](https://explorer.metacpan.org/?url=/module/_mapping).},
                operationId => 'PostModuleMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/module_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/module/_search
        '/v1/module/_search' =>
        {
            get => 
            {
                description => qq{Returns the result set for the module search.},
                example => 'curl https://fastapi.metacpan.org/v1/module/_search?from=40&q=HTTP&size=20',
                operationId => 'GetModuleSearch',
                parameters => [
                {
                    description => "Specifies the [search query](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches).",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the maximum number of [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result elements.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the module search.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/module/_search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "path" : ".*HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostModuleSearch',
                parameters => [
                {
                    in => 'query',
                    name => 'query',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/module/_search/scroll
        '/v1/module/_search/scroll' =>
        {
            'delete' =>
            {
                description => qq{Clear a [scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/paginate-search-results.html#clear-scroll)},
                operationId => 'DeleteModuleSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                oneOf => [
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                type => 'string',
                                            },
                                        },
                                    },
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                items =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'array',
                                            },
                                        },
                                    },
                                ],
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    type => 'object',
                                    properties =>
                                    {
                                        # TODO: Need to find out what is returned upon clearing a scroll
                                        removed =>
                                        {
                                            type => 'boolean',
                                        }
                                    }
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            get => 
            {
                description => qq{Returns the result set for the module search.},
                operationId => 'GetModuleSearchScroll',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the [scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                    in => 'query',
                    name => 'scroll_id',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the module search.},
                operationId => 'PostModuleSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/scroll',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/package
        '/v1/package' =>
        {
            get => 
            {
                description => 'Queries packages information details using simple search.',
                example => 'curl https://fastapi.metacpan.org/v1/package?from=40&q=HTTP&size=20',
                operationId => 'GetPackage',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Queries packages information details using advanced ElasticSearch.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/package -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "module_name" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostPackage',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Package.pm#L10C31-L10C56>
        # NOTE: /v1/package/modules/{distribution}
        '/v1/package/modules/{distribution}' =>
        {
            get => 
            {
                description => 'Retrieves the list of a distribution packages.',
                example => 'curl https://fastapi.metacpan.org/v1/package/modules/HTTP-Message',
                operationId => 'GetPackageDistributionList',
                parameters => [
                {
                    description => 'The name of the distribution to get its modules.',
                    example => 'HTTP-Message',
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    property =>
                                    {
                                        modules =>
                                        {
                                            items =>
                                            {
                                                example => 'HTTP::Message',
                                                maxLength => 2048,
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves the list of a distribution packages.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/package/modules/HTTP-Message',
                operationId => 'PostPackageDistributionList',
                parameters => [
                {
                    description => 'The name of the distribution to get its modules.',
                    example => 'HTTP-Message',
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    property =>
                                    {
                                        modules =>
                                        {
                                            items =>
                                            {
                                                example => 'HTTP::Message',
                                                maxLength => 2048,
                                                type => 'string',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/package/{module}
        '/v1/package/{module}' =>
        {
            get => 
            {
                description => qq{Retrieves the latest release and package information for the specified `module`.},
                example => 'curl https://fastapi.metacpan.org/v1/package/HTTP::Message',
                operationId => 'GetModulePackage',
                parameters => [
                {
                    description => 'The package name of the module to get its information.',
                    example => 'HTTP::Message',
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/package",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves the latest release and package information for the specified `module`.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/package/HTTP::Message',
                operationId => 'PostModulePackage',
                parameters => [
                {
                    description => 'The package name of the module to get its information.',
                    example => 'HTTP::Message',
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/package",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/permission
        '/v1/permission' =>
        {
            get => 
            {
                description => 'Queries permissions information details using simple search.',
                example => 'curl https://fastapi.metacpan.org/v1/permission?from=40&q=HTTP&size=20',
                operationId => 'GetPermission',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Queries permissions information details using advanced ElasticSearch.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/permission -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "module_name" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostPermission',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/permission/by_author/{author}
        '/v1/permission/by_author/{author}' =>
        {
            get => 
            {
                description => 'Retrieves permission information details for the specified author.',
                example => 'curl https://fastapi.metacpan.org/v1/permission/by_author/OALDERS?from=40&q=HTTP&size=20',
                operationId => 'GetPermissionByAuthor',
                parameters => [
                {
                    description => "This is the user's pause ID",
                    example => 'OALDERS',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permissions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves permission information details for the specified author.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/permission/by_author/OALDERS -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "module_name" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostPermissionByAuthor',
                parameters => [
                {
                    description => "This is the user's pause ID",
                    example => 'OALDERS',
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permissions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Permission.pm#L20>
        # NOTE: /v1/permission/by_module
        '/v1/permission/by_module' =>
        {
            get => 
            {
                description => 'Retrieves permission information details for the specified modules.',
                operationId => 'GetPermissionByModuleQueryString',
                example => 'curl https://fastapi.metacpan.org/v1/permission/by_module?module=HTTP%3A%3AMessage&module=Nice%3A%3ATry',
                parameters => [
                {
                    description => "This is the module package name",
                    example => 'DBD::DBM::Statement',
                    in => 'query',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permissions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves permission information details for the specified modules.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/permission/by_module -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "module" : [
      "HTTP::Message",
      "Nice::Try"
   ]
}
EOT},
                operationId => 'PostPermissionByModuleJSON',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    module => 
                                    {
                                        description => "This is the module package name",
                                        example => 'DBD::DBM::Statement',
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permissions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Permission.pm#L15>
        # NOTE: /v1/permission/by_module/{module}
        '/v1/permission/by_module/{module}' =>
        {
            get => 
            {
                description => 'Retrieves permission information details for the specified module.',
                example => 'curl https://fastapi.metacpan.org/v1/permission/by_module/HTTP::Message',
                operationId => 'GetPermissionByModule',
                parameters => [
                {
                    description => "This is the module package name",
                    example => 'HTTP::Message',
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permissions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves permission information details for the specified module.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/permission/by_module/HTTP::Message',
                operationId => 'PostPermissionByModule',
                parameters => [
                {
                    description => "This is the module package name",
                    example => 'HTTP::Message',
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permissions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/permission/{module}
        '/v1/permission/{module}' =>
        {
            get => 
            {
                description => qq{Returns the corresponding `permission` for the specified `module`.},
                example => 'curl https://fastapi.metacpan.org/v1/permission/HTTP::Message',
                operationId => 'GetModulePermission',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permission",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the corresponding `permission` for the specified `module`.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/permission/HTTP::Message',
                operationId => 'PostModulePermission',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/permission",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/pod_render
        '/v1/pod_render' =>
        {
            get => 
            {
                description => qq{Takes some POD data and check for errors. It returns the POD provided in formatted plan text.},
                example => 'curl https://fastapi.metacpan.org/v1/pod_render?pod=%3Dencoding+utf-8%0A%0A%3Dhead1+Hello+World%0A%0ASomething+here%0A%0A%3Doops%0A%0A%3Dcut%0A',
                operationId => 'GetRenderPOD',
                parameters => [
                {
                    description => 'The POD data to format',
                    example => qq{=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n},
                    in => 'query',
                    name => 'pod',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    in => 'query',
                    name => 'show_errors',
                    required => \0,
                    schema =>
                    {
                        type => 'boolean',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                    example => qq{Hello World\n    Something here\n\nPOD ERRORS\n    Hey! The above document had some coding errors, which are explained below:\n\n    Around line 7:\n        Unknown directive: =oops\n},
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Takes some POD data and check for errors. It returns the POD provided in formatted plan text.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/pod_render?pod=%3Dencoding+utf-8%0A%0A%3Dhead1+Hello+World%0A%0ASomething+here%0A%0A%3Doops%0A%0A%3Dcut%0A',
                operationId => 'PostRenderPOD',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    pod =>
                                    {
                                        type => 'string',
                                        description => 'The POD data to format',
                                        example => q{=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n},
                                    },
                                    show_errors =>
                                    {
                                        type => 'boolean',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/pod/{module}
        '/v1/pod/{module}' =>
        {
            get => 
            {
                description => qq{Returns the POD of the given module. You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP::Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown},
                example => 'curl https://fastapi.metacpan.org/v1/pod/HTTP::Message?content-type=text/plain',
                operationId => 'GetModulePOD',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'query',
                    name => 'show_errors',
                    required => \0,
                    schema =>
                    {
                        type => 'boolean',
                    },
                },
                {
                    in => 'query',
                    name => 'url_prefix',
                    required => \0,
                    # XXX /pod/author/release/path?url_prefix -> Not sure what the valid values are
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                {
                    description => qq{You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP-Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown},
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                    enum => [qw( text/html text/plain text/x-markdown text/x-pod )],
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/html' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-pod' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-markdown' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            # Accepts POST method, but with a query string, not with a JSON payload
            post => 
            {
                description => qq{Returns the POD of the given module. You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP::Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown. POST method is possible, but still with a query string. JSON payload are not recognised.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/pod/HTTP::Message?content-type=text/plain',
                operationId => 'PostModulePOD',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'query',
                    name => 'show_errors',
                    required => \0,
                    schema =>
                    {
                        type => 'boolean',
                    },
                },
                {
                    in => 'query',
                    name => 'url_prefix',
                    required => \0,
                    # XXX /pod/author/release/path?url_prefix -> Not sure what the valid values are
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                {
                    description => qq{You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP-Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown},
                    in => 'query',
                    name => 'content-type',
                    schema =>
                    {
                        type => 'string',
                    },
                    enum => [qw( text/html text/plain text/x-markdown text/x-pod )],
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/html' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-pod' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-markdown' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Pod.pm#L12>
        # NOTE: /v1/pod/{author}/{release}/{path}
        '/v1/pod/{author}/{release}/{path}' =>
        {
            get => 
            {
                description => qq{Returns the POD of the given module in the specified release. You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP-Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown},
                example => 'curl https://fastapi.metacpan.org/v1/pod/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm?content-type=text/x-markdown',
                operationId => 'GetModuleReleasePod',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'query',
                    name => 'show_errors',
                    required => \0,
                    schema =>
                    {
                        type => 'boolean',
                    },
                },
                {
                    in => 'query',
                    name => 'url_prefix',
                    required => \0,
                    # XXX /pod/author/release/path?url_prefix -> Not sure what the valid values are
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                {
                    description => qq{You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP-Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown},
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                    enum => [qw( text/html text/plain text/x-markdown text/x-pod )],
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/html' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-pod' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-markdown' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            # Accepts POST method, but with a query string, not with a JSON payload
            post => 
            {
                description => qq{Returns the POD of the given module in the specified release. You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP-Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/pod/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm?content-type=text/x-markdown',
                operationId => 'PostModuleReleasePod',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'query',
                    name => 'show_errors',
                    required => \0,
                    schema =>
                    {
                        type => 'boolean',
                    },
                },
                {
                    in => 'query',
                    name => 'url_prefix',
                    required => \0,
                    # XXX /pod/author/release/path?url_prefix -> Not sure what the valid values are
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                },
                {
                    description => qq{You can change the output format by either passing a `content-type` query parameter (e.g. [/pod/HTTP-Message?content-type=text/plain](https://fastapi.metacpan.org/v1/pod/HTTP-Message?content-type=text/plain) or by adding an `Accept` header to the HTTP request. Valid content types are:\n\n* text/html (default)\n* text/plain\n* text/x-pod\n* text/x-markdown},
                    in => 'query',
                    name => 'content-type',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                    enum => [qw( text/html text/plain text/x-markdown text/x-pod )],
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/html' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-pod' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                            'text/x-markdown' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/rating
        '/v1/rating' =>
        {
            get => 
            {
                description => 'Queries ratings information details using simple search.',
                example => 'curl https://fastapi.metacpan.org/v1/rating?from=40&q=HTTP&size=20',
                operationId => 'GetRating',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Queries ratings information details using advanced ElasticSearch.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/rating -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "distribution" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostRating',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Rating.pm#L12>
        # NOTE: /v1/rating/by_distributions
        '/v1/rating/by_distributions' =>
        {
            get => 
            {
                description => 'Retrieves rating informations details for the specified distributions.',
                operationId => 'GetRatingByDistribution',
                example => 'curl https://fastapi.metacpan.org/v1/rating/by_distributions?distribution=HTTP-Tiny',
                parameters => [
                {
                    in => 'query',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/distributions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Retrieves rating informations details for the specified distributions.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/rating/by_distributions -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "distribution" : "HTTP-Tiny"
}},
                operationId => 'PostRatingByDistribution',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    distribution =>
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                        example => 'HTTP-Message',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/distributions",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/rating/_mapping
        '/v1/rating/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [rating object](https://explorer.metacpan.org/?url=/rating/_mapping).},
                operationId => 'GetRatingMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/rating_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [rating object](https://explorer.metacpan.org/?url=/rating/_mapping).},
                operationId => 'PostRatingMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/rating_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/rating/_search
        '/v1/rating/_search' =>
        {
            get => 
            {
                description => qq{Returns the result set for the rating search.},
                example => 'curl https://fastapi.metacpan.org/v1/rating/_search?from=40&q=HTTP&size=20',
                operationId => 'GetRatingSearch',
                parameters => [
                {
                    description => "Specifies the [search query](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches).",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the maximum number of [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result elements.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the rating search.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/rating/_search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "distribution" : ".*HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostRatingSearch',
                parameters => [
                {
                    in => 'query',
                    name => 'query',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/rating/_search/scroll
        '/v1/rating/_search/scroll' =>
        {
            'delete' =>
            {
                description => qq{Clear a [scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/paginate-search-results.html#clear-scroll)},
                operationId => 'DeleteRatingSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                oneOf => [
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                type => 'string',
                                            },
                                        },
                                    },
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                items =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'array',
                                            },
                                        },
                                    },
                                ],
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    type => 'object',
                                    properties =>
                                    {
                                        # TODO: Need to find out what is returned upon clearing a scroll
                                        removed =>
                                        {
                                            type => 'boolean',
                                        }
                                    }
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            get => 
            {
                description => qq{Returns the result set for the rating search.},
                operationId => 'GetRatingSearchScroll',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the [scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                    in => 'query',
                    name => 'scroll_id',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the rating search.},
                operationId => 'PostRatingSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/scroll',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release
        '/v1/release' =>
        {
            get => 
            {
                description => 'Queries releases information details using simple search.',
                example => 'curl https://fastapi.metacpan.org/v1/release?from=40&q=HTTP&size=20',
                operationId => 'GetRelease',
                parameters => [
                {
                    in => 'query',
                    name => 'q',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'The offset starting from 0 within the total data.',
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => 'The size of each page, i.e. how many results are returned per page. This usually defaults to 10.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Queries releases information details using advanced ElasticSearch.',
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/release -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "distribution" : "HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostRelease',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    "q" => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                    from => 
                                    {
                                        type => 'integer',
                                    },
                                    size => 
                                    {
                                        type => 'integer',
                                    },
                                    fields => 
                                    {
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L22>
        # NOTE: /v1/release/{distribution}
        '/v1/release/{distribution}' =>
        {
            get => 
            {
                description => qq{Retrieves the latest distribution release information details.\nThe `/release` endpoint accepts either the name of a `distribution` (e.g. [/release/HTTP-Message](https://fastapi.metacpan.org/v1/release/HTTP-Message)), which returns the most recent release of the distribution.},
                example => 'curl https://fastapi.metacpan.org/v1/release/HTTP-Message',
                operationId => 'GetReleaseDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/release",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves the latest distribution release information details.\nThe `/release` endpoint accepts either the name of a `distribution` (e.g. [/release/HTTP-Message](https://fastapi.metacpan.org/v1/release/HTTP-Message)), which returns the most recent release of the distribution.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/HTTP-Message',
                operationId => 'PostReleaseDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    'join' =>
                                    {
                                        description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/release",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L29>
        # NOTE: /v1/release/{author}/{release}
        '/v1/release/{author}/{release}' =>
        {
            get => 
            {
                description => qq{Retrieves a distribution release information details.\nThis `/release` endpoint accepts  the name of an `author` and the name of the `release` (e.g. [/release/DOY/OALDERS/HTTP-Message-6.37](https://fastapi.metacpan.org/v1/release/DOY/OALDERS/HTTP-Message-6.37)), which returns the most recent release of the distribution.},
                operationId => 'GetAuthorReleaseDistribution',
                example => 'curl https://fastapi.metacpan.org/v1/release/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        release =>
                                        {
                                            schema =>
                                            {
                                                '$ref' => "#/components/schemas/release",
                                            },
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                        total =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves a distribution release information details.\nThis `/release` endpoint accepts  the name of an `author` and the name of the `release` (e.g. [/release/DOY/OALDERS/HTTP-Message-6.37](https://fastapi.metacpan.org/v1/release/DOY/OALDERS/HTTP-Message-6.37)), which returns the most recent release of the distribution.},
                operationId => 'PostAuthorReleaseDistribution',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    'join' =>
                                    {
                                        description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                                        maxLength => 2048,
                                        type => 'string'
                                    }
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        release =>
                                        {
                                            schema =>
                                            {
                                                '$ref' => "#/components/schemas/release",
                                            },
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                        total =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L80>
        # NOTE: /v1/release/all_by_author/{author}
        '/v1/release/all_by_author/{author}' =>
        {
            get => 
            {
                description => qq{Get all releases by the specified author},
                operationId => 'GetAllReleasesByAuthor',
                example => 'curl https://fastapi.metacpan.org/v1/release/all_by_author/OALDERS?page=2&page_size=100',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies the page offset starting from 1.",
                    in => 'query',
                    name => 'page',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies the page size, i.e. the number of elements returned in one page.",
                    in => 'query',
                    name => 'page_size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Get all releases by the specified author},
                operationId => 'PostAllReleasesByAuthor',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/all_by_author/OALDERS?page=2&page_size=100',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    page =>
                                    {
                                        description => "Specifies the page offset starting from 1.",
                                        type => 'integer'
                                    },
                                    page_size =>
                                    {
                                        description => "Specifies the page size, i.e. the number of elements returned in one page.",
                                        type => 'integer'
                                    }
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release/by_author/{author}
        '/v1/release/by_author/{author}' =>
        {
            get => 
            {
                description => qq{Get releases by a specified author.},
                example => 'curl https://fastapi.metacpan.org/v1/release/by_author/OALDERS',
                operationId => 'GetReleaseByAuthor',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies the page size, i.e. the number of elements returned in one page.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies the page offset starting from 1.",
                    in => 'query',
                    name => 'page',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Get releases by a specified author.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/by_author/OALDERS',
                operationId => 'PostReleaseByAuthor',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    size =>
                                    {
                                        description => "Specifies the page size, i.e. the number of elements returned in one page.",
                                        type => 'integer'
                                    },
                                    page =>
                                    {
                                        description => "Specifies the page offset starting from 1.",
                                        type => 'integer'
                                    }
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L37>
        # NOTE: /v1/release/contributors/{author}/{release}
        '/v1/release/contributors/{author}/{release}' =>
        {
            get => 
            {
                description => qq{Retrieves the list of contributors for the specified release.},
                example => 'curl https://fastapi.metacpan.org/v1/release/contributors/OALDERS/HTTP-Message-6.36',
                operationId => 'GetReleaseDistributionContributors',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        contributors =>
                                        {
                                            items =>
                                            {
                                                properties =>
                                                {
                                                    email =>
                                                    {
                                                        items =>
                                                        {
                                                            maxLength => 2048,
                                                            type => 'string',
                                                        },
                                                        type => 'array',
                                                    },
                                                    gravatar_url =>
                                                    {
                                                        description => "Contributor profile picture",
                                                        maxLength => 2048,
                                                        type => 'string',
                                                    },
                                                    name =>
                                                    {
                                                        description => "Contributor's name",
                                                        maxLength => 2048,
                                                        type => 'string',
                                                    },
                                                    pause_id =>
                                                    {
                                                        description => "Contributor's CPAN ID",
                                                        maxLength => 2048,
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves the list of contributors for the specified release.},
                operationId => 'PostReleaseDistributionContributors',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/contributors/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    'join' =>
                                    {
                                        description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        contributors =>
                                        {
                                            items =>
                                            {
                                                properties =>
                                                {
                                                    email =>
                                                    {
                                                        items =>
                                                        {
                                                            maxLength => 2048,
                                                            type => 'string',
                                                        },
                                                        type => 'array',
                                                    },
                                                    gravatar_url =>
                                                    {
                                                        description => "Contributor profile picture",
                                                        maxLength => 2048,
                                                        type => 'string',
                                                    },
                                                    name =>
                                                    {
                                                        description => "Contributor's name",
                                                        maxLength => 2048,
                                                        type => 'string',
                                                    },
                                                    pause_id =>
                                                    {
                                                        description => "Contributor's CPAN ID",
                                                        maxLength => 2048,
                                                        type => 'string',
                                                    },
                                                },
                                                type => 'object',
                                            },
                                            type => 'array',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release/files_by_category/{author}/{release}
        '/v1/release/files_by_category/{author}/{release}' =>
        {
            get => 
            {
                description => qq{Retrieves the list of release key files by category},
                operationId => 'GetReleaseKeyFilesByCategory',
                example => 'curl https://fastapi.metacpan.org/v1/release/files_by_category/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'query',
                    name => 'category',
                    description => 'An optional category can be specified to refine the result. Valid vlues include `changelog`, `contributing`, `dist`, `license`, `other`',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/files_categories',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves the list of release key files by category},
                operationId => 'PostReleaseKeyFilesByCategory',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/files_by_category/OALDERS/HTTP-Message-6.36',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    category =>
                                    {
                                        description => 'An optional category can be specified to refine the result. Valid vlues include `changelog`, `contributing`, `dist`, `license`, `other`',
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/files_categories',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release/interesting_files/{author}/{release}
        '/v1/release/interesting_files/{author}/{release}' =>
        {
            get => 
            {
                description => qq{Retrieves the list of interesting files for the specified release.},
                example => 'curl https://fastapi.metacpan.org/v1/release/interesting_files/OALDERS/HTTP-Message-6.36',
                operationId => 'GetReleaseInterestingFiles',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'query',
                    name => 'category',
                    description => 'An optional category can be specified to refine the result. Valid vlues include `changelog`, `contributing`, `dist`, `license`, `other`',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/files_interesting',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves the list of interesting files for the specified release.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/interesting_files/OALDERS/HTTP-Message-6.36',
                operationId => 'PostReleaseInterestingFiles',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    category =>
                                    {
                                        description => 'An optional category can be specified to refine the result. Valid vlues include `changelog`, `contributing`, `dist`, `license`, `other`',
                                        maxLength => 2048,
                                        type => 'string',
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/files_interesting',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L75>
        # NOTE: /v1/release/latest_by_author/{author}
        '/v1/release/latest_by_author/{author}' =>
        {
            get => 
            {
                description => qq{Get latest releases by the specified author},
                example => 'curl https://fastapi.metacpan.org/v1/release/latest_by_author/OALDERS',
                operationId => 'GetLatestReleaseByAuthor',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Get latest releases by the specified author},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/release/latest_by_author/OALDERS},
                operationId => 'PostLatestReleaseByAuthor',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L68>
        # NOTE: /v1/release/latest_by_distribution/{distribution}
        '/v1/release/latest_by_distribution/{distribution}' =>
        {
            get => 
            {
                description => qq{Get latest releases for a specified distribution.},
                example => 'curl https://fastapi.metacpan.org/v1/release/latest_by_distribution/HTTP-Message',
                operationId => 'GetLatestReleaseByDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        release =>
                                        {
                                            schema =>
                                            {
                                                '$ref' => '#/components/schemas/release',
                                            }
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                        total =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Get latest releases for a specified distribution.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/latest_by_distribution/HTTP-Message',
                operationId => 'PostLatestReleaseByDistribution',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        release =>
                                        {
                                            schema =>
                                            {
                                                '$ref' => '#/components/schemas/release',
                                            }
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                        total =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release/modules/{author}/{release}
        '/v1/release/modules/{author}/{release}' =>
        {
            get => 
            {
                description => qq{Retrieves the list of modules in the specified release},
                example => 'curl https://fastapi.metacpan.org/v1/release/modules/OALDERS/HTTP-Message-6.36',
                operationId => 'GetReleaseModules',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                    in => 'query',
                    name => 'join',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/files',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Retrieves the list of modules in the specified release},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/modules/OALDERS/HTTP-Message-6.36',
                operationId => 'PostReleaseModules',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    'join' =>
                                    {
                                        description => "Specifies which object to [join](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#joins) in the result.",
                                        maxLength => 2048,
                                        type => 'string'
                                    },
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/files',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L56>
        # NOTE: /v1/release/recent
        '/v1/release/recent' =>
        {
            get => 
            {
                description => qq{Get recent releases},
                example => 'curl https://fastapi.metacpan.org/v1/release/recent',
                operationId => 'GetReleaseRecent',
                parameters => [
                {
                    description => "Specifies the page offset starting from 1.",
                    in => 'query',
                    name => 'page',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                },
                {
                    description => "Specifies the page size, i.e. the number of elements returned in one page.",
                    in => 'query',
                    name => 'page_size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/release_recents',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Get recent releases},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/recent',
                operationId => 'PostReleaseRecent',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    page =>
                                    {
                                        description => "Specifies the page offset starting from 1.",
                                        type => 'integer'
                                    },
                                    page_size =>
                                    {
                                        description => "Specifies the page size, i.e. the number of elements returned in one page.",
                                        type => 'integer'
                                    }
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/release_recents',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L106>
        # NOTE: /v1/release/top_uploaders
        '/v1/release/top_uploaders' =>
        {
            get => 
            {
                description => qq{Get top release uploaders},
                example => 'curl https://fastapi.metacpan.org/v1/release/top_uploaders',
                operationId => 'GetTopReleaseUploaders',
                parameters => [
                {
                    description => "Specifies the result range. Valid values are `all`, `weekly`, `monthly` or `yearly`. It defaults to `weekly`",
                    in => 'query',
                    name => 'range',
                    required => \0,
                    schema =>
                    {
                        type => 'string'
                    },
                },
                {
                    description => "Specifies the page size, i.e. the number of elements returned in one page.",
                    in => 'query',
                    name => 'page_size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        count =>
                                        {
                                            items =>
                                            {
                                                additionalProperties =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'object',
                                            },
                                            # TODO: /v1/release/top_uploaders: Not sure this is the number of distributions. Need to be double checked
                                            description => 'Array of pause IDs to the number of distributions',
                                            example => '"NOBUNAGA" : 5',
                                            type => 'array',
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Get top release uploaders},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/top_uploaders',
                operationId => 'PostTopReleaseUploaders',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    range =>
                                    {
                                        description => "Specifies the result range. Valid values are `all`, `weekly`, `monthly` or `yearly`. It defaults to `weekly`",
                                        type => 'string'
                                    }
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        count =>
                                        {
                                            items =>
                                            {
                                                additionalProperties =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'object',
                                            },
                                            # TODO: /v1/release/top_uploaders: Not sure this is the number of distributions. Need to be double checked
                                            description => 'Array of pause IDs to the number of distributions',
                                            example => '"NOBUNAGA" : 5',
                                            type => 'array',
                                        },
                                        took =>
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Release.pm#L87>
        # NOTE: /v1/release/versions/{distribution}
        '/v1/release/versions/{distribution}' =>
        {
            get => 
            {
                description => qq{Get all releases by versions for the specified distribution},
                example => 'curl https://fastapi.metacpan.org/v1/release/versions/HTTP-Message',
                operationId => 'GetAllReleasesByVersion',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies the version(s) to return as a comma-sepated value.",
                    example => 'v0.30.5,v0.31.0',
                    in => 'query',
                    name => 'versions',
                    required => \0,
                    schema =>
                    {
                        type => 'string'
                    },
                },
                {
                    description => "Specifies whether the result should be returned in plain mode.",
                    in => 'query',
                    name => 'plain',
                    required => \0,
                    schema =>
                    {
                        type => 'boolean'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            },
                            'text/plain' =>
                            {
                                description => 'Lines of version and download URL spearated by a space are returned when the option `plain` is enabled.',
                                example => "6.44	https://cpan.metacpan.org/authors/id/O/OA/OALDERS/HTTP-Message-6.44.tar.gz\n6.43	https://cpan.metacpan.org/authors/id/S/SI/SIMBABQUE/HTTP-Message-6.43.tar.gz",
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Get all releases by versions for the specified distribution},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/release/versions/HTTP-Message',
                operationId => 'PostAllReleasesByVersion',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    versions =>
                                    {
                                        description => "Specifies the version(s) to return as a comma-sepated value.",
                                        example => 'v0.30.5,v0.31.0',
                                        type => 'string'
                                    },
                                    plain =>
                                    {
                                        description => "Specifies whether the result should be returned in plain mode.",
                                        type => 'boolean'
                                    }
                                },
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => '#/components/schemas/releases',
                                }
                            },
                            'text/plain' =>
                            {
                                description => 'Lines of version and download URL spearated by a space are returned when the option `plain` is enabled.',
                                example => "6.44	https://cpan.metacpan.org/authors/id/O/OA/OALDERS/HTTP-Message-6.44.tar.gz\n6.43	https://cpan.metacpan.org/authors/id/S/SI/SIMBABQUE/HTTP-Message-6.43.tar.gz",
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release/_mapping
        '/v1/release/_mapping' =>
        {
            get => 
            {
                description => qq{Returns the available fields for the [release object](https://explorer.metacpan.org/?url=/release/_mapping).},
                operationId => 'GetReleaseMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/release_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the available fields for the [release object](https://explorer.metacpan.org/?url=/release/_mapping).},
                operationId => 'PostReleaseMapping',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/release_mapping",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release/_search
        '/v1/release/_search' =>
        {
            get => 
            {
                description => qq{Returns the result set for the release search.},
                example => 'curl https://fastapi.metacpan.org/v1/release/_search?from=40&q=HTTP&size=20',
                operationId => 'GetReleaseSearch',
                parameters => [
                {
                    description => "Specifies the [search query](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches).",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the maximum number of [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result elements.",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the release search.},
                example => qq{curl -XPOST https://fastapi.metacpan.org/v1/release/_search -H 'Content-Type: application/json; charset=utf-8' --data-binary \@- <<EOT
{
   "from" : 40,
   "query" : {
      "regexp" : {
         "name" : ".*HTTP.*"
      }
   },
   "size" : 20
}
EOT},
                operationId => 'PostReleaseSearch',
                parameters => [
                {
                    in => 'query',
                    name => 'query',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => "Specifies the elements to sort the [search](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches) result.",
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/elastic_search',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/release/_search/scroll
        '/v1/release/_search/scroll' =>
        {
            'delete' =>
            {
                description => qq{Clear a [scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/paginate-search-results.html#clear-scroll)},
                operationId => 'DeleteReleaseSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                oneOf => [
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                type => 'string',
                                            },
                                        },
                                    },
                                    {
                                        properties => 
                                        {
                                            scroll_id =>
                                            {
                                                items =>
                                                {
                                                    type => 'string',
                                                },
                                                type => 'array',
                                            },
                                        },
                                    },
                                ],
                            }
                        }
                    },
                    required => \1,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    type => 'object',
                                    properties =>
                                    {
                                        # TODO: Need to find out what is returned upon clearing a scroll
                                        removed =>
                                        {
                                            type => 'boolean',
                                        }
                                    }
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            get => 
            {
                description => qq{Returns the result set for the release search.},
                operationId => 'GetReleaseSearchScroll',
                parameters => [
                {
                    description => "Specifies the time to live of the [scroll search](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html#scroll-search-context).",
                    in => 'query',
                    name => 'scroll',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies the [scroll ID](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).",
                    in => 'query',
                    name => 'scroll_id',
                    required => \1,
                    schema =>
                    {
                        type => 'string',
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns the result set for the release search.},
                operationId => 'PostReleaseSearchScroll',
                parameters => [],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                '$ref' => '#/components/schemas/scroll',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/scroll_result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/ReverseDependencies.pm#L14>
        # NOTE: /v1/reverse_dependencies/dist/{distribution}
        '/v1/reverse_dependencies/dist/{distribution}' =>
        {
            get => 
            {
                description => qq{Returns a list of all the modules who depend on the specified distribution.`.},
                example => 'curl https://fastapi.metacpan.org/v1/reverse_dependencies/dist/HTTP-Message',
                operationId => 'GetReverseDependencyDist',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'Specifies the page offset starting from 1.',
                    in => 'query',
                    name => 'page',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => 'Specifies the number of result per page to be returned. Usually one would use `size` only.',
                    in => 'query',
                    name => 'page_size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => 'Specifies the maximum total number of result to be returned.',
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => 'Specifies how the result is sorted.',
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/reverse_dependencies",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns a list of all the modules who depend on the specified distribution.`.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/reverse_dependencies/dist/HTTP-Message',
                operationId => 'PostReverseDependencyDist',
                parameters => [
                {
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    page =>
                                    {
                                        description => 'Specifies the page offset starting from 1.',
                                        type => 'integer',
                                    },
                                    page_size =>
                                    {
                                        description => 'Specifies the number of result per page to be returned. Usually one would use `size` only.',
                                        type => 'integer',
                                    },
                                    size =>
                                    {
                                        description => 'Specifies the maximum total number of result to be returned.',
                                        type => 'integer',
                                    },
                                    sort =>
                                    {
                                        description => 'Specifies how the result is sorted.',
                                        type => 'string',
                                    },
                                },
                                required => [],
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/reverse_dependencies",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/ReverseDependencies.pm#L23>
        # NOTE: /v1/reverse_dependencies/module/{module}
        '/v1/reverse_dependencies/module/{module}' =>
        {
            get => 
            {
                description => qq{Returns a list of all the modules who depend on the specified module.},
                example => 'curl https://fastapi.metacpan.org/v1/reverse_dependencies/module/HTTP::Message',
                operationId => 'GetReverseDependencyModule',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => 'Specifies the page offset starting from 1.',
                    in => 'query',
                    name => 'page',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => 'Specifies the number of result per page to be returned.',
                    in => 'query',
                    name => 'page_size',
                    required => \0,
                    schema =>
                    {
                        type => 'integer',
                    },
                },
                {
                    description => 'Specifies how the result is sorted.',
                    in => 'query',
                    name => 'sort',
                    required => \0,
                    schema =>
                    {
                        type => 'string',
                    },
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/reverse_dependencies",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Returns a list of all the modules who depend on the specified module.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/reverse_dependencies/module/HTTP::Message',
                operationId => 'PostReverseDependencyModule',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/json' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => 
                                {
                                    page =>
                                    {
                                        description => 'Specifies the page offset starting from 1.',
                                        type => 'integer',
                                    },
                                    page_size =>
                                    {
                                        description => 'Specifies the number of result per page to be returned.',
                                        type => 'integer',
                                    },
                                    sort =>
                                    {
                                        description => 'Specifies how the result is sorted.',
                                        type => 'string',
                                    },
                                },
                                required => [],
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/reverse_dependencies",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/search
        '/v1/search' =>
        {
            get => 
            {
                description => qq{Returns result set based on the search query.},
                operationId => 'GetSearchResult',
                parameters => [
                {
                    description => "Specifies the search keywords to be queried.",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/search/autocomplete
        '/v1/search/autocomplete' =>
        {
            get => 
            {
                description => qq{Returns result set based on the autocomplete search query.},
                example => 'https://fastapi.metacpan.org/search/autocomplete?q=HTTP',
                operationId => 'GetSearchAutocompleteResult',
                parameters => [
                {
                    description => "Specifies the search keyword to be queried.",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/search/autocomplete/suggest
        '/v1/search/autocomplete/suggest' =>
        {
            get => 
            {
                description => qq{Returns suggested result set based on the autocomplete search query.},
                operationId => 'GetSearchAutocompleteSuggestResult',
                parameters => [
                {
                    description => "Specifies the search keyword to be queried.",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set",
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/search/first
        '/v1/search/first' =>
        {
            get => 
            {
                description => qq{Perform API search and return the first result (I'm Feeling Lucky)},
                operationId => 'GetSearchFirstResult',
                parameters => [
                {
                    description => "Specifies the search keywords to be queried.",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        path =>
                                        {
                                            type => 'string',
                                            description => "Relative path to module with full name",
                                        },
                                        authorized =>
                                        {
                                            type => 'boolean',
                                        },
                                        description =>
                                        {
                                            type => 'string',
                                            description => "Module description",
                                        },
                                        id =>
                                        {
                                            type => 'string',
                                        },
                                        distribution =>
                                        {
                                            type => 'string',
                                            description => "Name of the distribution the module is contained in",
                                        },
                                        author =>
                                        {
                                            type => 'string',
                                            description => "Module author ID",
                                        },
                                        release =>
                                        {
                                            type => 'string',
                                            description => "Package name with version",
                                        },
                                        status =>
                                        {
                                            type => 'string',
                                        },
                                        'abstract.analyzed' =>
                                        {
                                            type => 'string',
                                            description => "The module's abstract as analyzed from POD",
                                        },
                                        dist_fav_count =>
                                        {
                                            type => 'integer',
                                            description => "Number of times favorited",
                                        },
                                        date =>
                                        {
                                            type => 'string',
                                            description => "date module was indexed",
                                            format => 'date-time',
                                        },
                                        documentation =>
                                        {
                                            type => 'string',
                                        },
                                        pod_lines =>
                                        {
                                            type => 'array',
                                        },
                                        items =>
                                        {
                                            type => 'integer',
                                        },
                                        indexed =>
                                        {
                                            type => 'boolean',
                                            description => "Is the module indexed by PAUSE",
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/db7c3a90925ec85e6ae6a9f6dd64677305feac8d/lib/MetaCPAN/Document/File/Set.pm#L436>
        # NOTE: /v1/search/history/module/{module}/{path}
        '/v1/search/history/module/{module}/{path}' =>
        {
            get => 
            {
                description => qq{Find the history of a given module.},
                example => 'curl https://fastapi.metacpan.org/v1/search/history/module/HTTP::Message/lib/HTTP/Message.pm',
                operationId => 'GetModuleHistory',
                parameters => [
                {
                    description => "Specifies the module name.",
                    in => 'path',
                    name => 'module',
                    required => \1,
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set"
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Find the history of a given module.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/search/history/module/HTTP::Message/lib/HTTP/Message.pm',
                operationId => 'PostModuleHistory',
                parameters => [
                {
                    description => "Specifies the module name.",
                    in => 'path',
                    name => 'module',
                    required => \1,
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set"
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/db7c3a90925ec85e6ae6a9f6dd64677305feac8d/lib/MetaCPAN/Document/File/Set.pm#L436>
        # NOTE: /v1/search/history/file/{distribution}/{path}
        '/v1/search/history/file/{distribution}/{path}' =>
        {
            get => 
            {
                description => qq{Find the history of a given distribution file.},
                example => 'curl https://fastapi.metacpan.org/v1/search/history/file/HTTP-Message/lib/HTTP/Message.pm',
                operationId => 'GetFileHistory',
                parameters => [
                {
                    description => "Specifies the distribution name.",
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set"
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Find the history of a given distribution file.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/search/history/file/HTTP-Message/lib/HTTP/Message.pm',
                operationId => 'PostFileHistory',
                parameters => [
                {
                    description => "Specifies the distribution name.",
                    in => 'path',
                    name => 'distribution',
                    required => \1,
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set"
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/db7c3a90925ec85e6ae6a9f6dd64677305feac8d/lib/MetaCPAN/Document/File/Set.pm#L436>
        # NOTE: /v1/search/history/module/{module}/{path}
        '/v1/search/history/documentation/{module}/{path}' =>
        {
            get => 
            {
                description => qq{Find the history of a given module documentation.},
                example => 'curl https://fastapi.metacpan.org/v1/search/history/documentation/HTTP::Message/lib/HTTP/Message.pm',
                operationId => 'GetDocumentationHistory',
                parameters => [
                {
                    description => "Specifies the module name.",
                    in => 'path',
                    name => 'module',
                    required => \1,
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set"
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => qq{Find the history of a given module documentation.},
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/search/history/documentation/HTTP::Message/lib/HTTP/Message.pm',
                operationId => 'PostDocumentationHistory',
                parameters => [
                {
                    description => "Specifies the module name.",
                    in => 'path',
                    name => 'module',
                    required => \1,
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/result_set"
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # NOTE: /v1/search/web
        '/v1/search/web' =>
        {
            get => 
            {
                description => qq{Perform API search in the same fashion as the Web UI},
                example => 'curl https://fastapi.metacpan.org/v1/search/web?q=HTTP&from=0&size=10&collapsed=1',
                operationId => 'GetSearchWebResult',
                parameters => [
                {
                    description => "The query search term. If the search term contains a term with the tags `dist:` or `module:` results will be in expanded form, otherwise collapsed form.\n\nSee also `collapsed`",
                    in => 'query',
                    name => 'q',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    description => "The offset to use in the result set",
                    in => 'query',
                    name => 'from',
                    required => \0,
                    schema =>
                    {
                        default => 0,
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Number of results per page",
                    in => 'query',
                    name => 'size',
                    required => \0,
                    schema =>
                    {
                        default => 20,
                        type => 'integer',
                    },
                    style => 'simple',
                },
                {
                    description => "Force a collapsed even when searching for a particular distribution or module name.",
                    in => 'query',
                    name => 'collapsed',
                    required => \0,
                    schema =>
                    {
                        type => 'boolean',
                    },
                    style => 'simple',
                },
                {
                    description => "Specifies which fields in the response should be provided.",
                    in => 'query',
                    name => 'fields',
                    required => \0,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string'
                    },
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object',
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'application/json' =>
                            {
                                schema =>
                                {
                                    properties =>
                                    {
                                        collapsed => 
                                        {
                                            type => 'boolean',
                                        },
                                        results =>
                                        {
                                            items => 
                                            {
                                                schema =>
                                                {
                                                    '$ref' => "#/components/schemas/result_set",
                                                },
                                            },
                                            type => 'array',
                                        },
                                        took => 
                                        {
                                            type => 'integer',
                                        },
                                        total => 
                                        {
                                            type => 'integer',
                                        },
                                    },
                                    type => 'object',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Source.pm#L17>
        # NOTE: /v1/source/{author}/{release}/{path}
        '/v1/source/{author}/{release}/{path}' =>
        {
            get => 
            {
                description => 'Returns the source code of the given module path within the specified release.',
                operationId => 'GetSourceReleasePath',
                example => 'curl https://fastapi.metacpan.org/v1/source/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Returns the source code of the given module path within the specified release.',
                operationId => 'PostSourceReleasePath',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/source/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm',
                parameters => [
                {
                    in => 'path',
                    name => 'author',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'release',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                },
                {
                    in => 'path',
                    name => 'path',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            },
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
        # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Server/Controller/Source.pm#L61>
        # NOTE: /v1/source/{module}
        '/v1/source/{module}' =>
        {
            get => 
            {
                description => 'Returns the full source of the latest, authorized version of the given `module`.',
                example => 'curl https://fastapi.metacpan.org/v1/source/HTTP::Message',
                operationId => 'GetModuleSource',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
            post => 
            {
                description => 'Returns the full source of the latest, authorized version of the given `module`.',
                example => 'curl -XPOST https://fastapi.metacpan.org/v1/source/HTTP::Message',
                operationId => 'PostModuleSource',
                parameters => [
                {
                    in => 'path',
                    name => 'module',
                    required => \1,
                    schema =>
                    {
                        maxLength => 2048,
                        type => 'string',
                    },
                    style => 'simple',
                }],
                requestBody =>
                {
                    content =>
                    {
                        'application/x-www-form-urlencoded' =>
                        {
                            encoding => {},
                            schema =>
                            {
                                additionalProperties => \0,
                                properties => {},
                                type => 'object'
                            }
                        }
                    },
                    required => \0,
                },
                responses =>
                {
                    200 =>
                    {
                        content =>
                        {
                            'text/plain' =>
                            {
                                schema =>
                                {
                                    format => 'binary',
                                    type => 'string',
                                }
                            }
                        },
                        description => 'Successful response.',
                    },
                    default =>
                    {
                        content =>
                        {
                            "application/json" =>
                            {
                                schema =>
                                {
                                    '$ref' => "#/components/schemas/error",
                                }
                            }
                        },
                        description => "Error response.",
                    }
                }
            },
        },
    },
    security => [],
    servers => [
        { url => 'https://fastapi.metacpan.org' },
    ],
}
