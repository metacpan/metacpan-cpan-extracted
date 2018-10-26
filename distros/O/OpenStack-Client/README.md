# NAME

OpenStack::Client - A cute little client to OpenStack services

# SYNOPSIS

    #
    # First, connect to an API endpoint via the Keystone
    # authorization service
    #
    use OpenStack::Client::Auth ();

    my $endpoint = 'http://openstack.foo.bar:5000/v2.0';

    my $auth = OpenStack::Client::Auth->new($endpoint,
        'tenant'   => $ENV{'OS_TENANT_NAME'},
        'username' => $ENV{'OS_USERNAME'},
        'password' => $ENV{'OS_PASSWORD'}
    );

    my $glance = $auth->service('image',
        'region' => $ENV{'OS_REGION_NAME'}
    );

    my @images = $glance->all('/v2/images', 'images');

    #
    # Or, connect directly to an API endpoint by URI
    #
    use OpenStack::Client ();

    my $endpoint = 'http://glance.foo.bar:9292';

    my $glance = OpenStack::Client->new($endpoint,
        'token' => {
            'id' => 'foo'
        }
    );

    my @images = $glance->all('/v2/images', 'images');

# DESCRIPTION

`OpenStack::Client` is a no-frills OpenStack API client which provides generic
access to OpenStack APIs with minimal remote service discovery facilities; with
a minimal client, the key understanding of the remote services are primarily
predicated on an understanding of the authoritative OpenStack API documentation:

    http://developer.openstack.org/api-ref.html

Authorization, authentication, and access to OpenStack services such as the
OpenStack Compute and Networking APIs is made convenient by
[OpenStack::Client::Auth](https://metacpan.org/pod/OpenStack::Client::Auth).  Further, some small handling of response body data
such as obtaining the full resultset of a paginated response is handled for
convenience.

Ordinarily, a client can be obtained conveniently by using the `services()`
method on a [OpenStack::Client::Auth](https://metacpan.org/pod/OpenStack::Client::Auth) object.

# INSTANTIATION

- `OpenStack::Client->new(_$endpoint_, _%opts_)`

    Create a new `OpenStack::Client` object connected to the specified
    _$endpoint_.  The following values may be specified in _%opts_:

    - **token**

        A token obtained from a [OpenStack::Client::Auth](https://metacpan.org/pod/OpenStack::Client::Auth) object.

# INSTANCE METHODS

These methods are useful for identifying key attributes of an OpenStack service
endpoint client.

- `$client->endpoint()`

    Return the absolute HTTP URI to the endpoint this client provides access to.

- `$client->token()`

    If a token object was specified when creating `$client`, then return it.

# PERFORMING REMOTE CALLS

- `$client->call(_$args_)`

    Perform a call to the service endpoint using named arguments in the hash.  The
    following arguments are required:

    - `method` - Request method
    - `path` - Resource path

    The following arguments are optional:

    - `headers` - Request headers

        Headers are case _insensitive_; if duplicate header values are declared under
        different cases, it is undefined which headers shall take precedence.  The
        following headers are sent by default:

        - Accept

            Defaults to `application/json, text/plain`.

        - Accept-Encoding

            Defaults to `identity, gzip, deflate, compress`.

        - Content-Type

            Defaults to `application/json`, although some API calls (e.g., a PATCH)
            expect a different type; the the case of an image update, the expected
            type is `application/openstack-images-v2.1-json-patch` or some version
            thereof.

        Except for `X-Auth-Token`, any additional token will be added to the request.

    - `body` - Request body

        This may be a scalar reference to a data structure to be encoded to JSON, or a
        CODE reference to a subroutine which, when called, will return a chunk of data
        to be supplied to the API endpoint; the stream is ended when the supplied
        subroutine returns an empty string or undef.

    - `handler` - Response body handler function

        When specified, this function will be called with two arguments; the first
        argument is a scalar value containing a chunk of data in the response body, and
        the second is a scalar reference to a [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object representing the
        current response.  This is useful for retrieving very large resources without
        having to store the entire response body in memory at once for parsing.

    All forms of this method may return the following:

    - For **application/json**: A decoded JSON object
    - For other response types: The unmodified response body

    In exceptional conditions (such as when the service returns a 4xx or 5xx HTTP
    response), the client will die with the raw text response from the HTTP
    service, indicating the nature of the service-side failure to service the
    current call.

- `$client->call(_$method_, _$path_, _$body_)`

    Perform a call to the service endpoint using the HTTP method _$method_,
    accessing the resource _$path_ (relative to the absolute endpoint URI),
    passing an arbitrary value in _$body_.

- `$client->call(_$method_, _$headers_, _$path_, _$body_)`

    Perform a call to the service endpoint using the HTTP method _$method_,
    accessing the resource _$path_ (relative to the absolute endpoint URI),
    specifying the headers in _$headers_, passing an arbitrary value in _$body_.

# EXAMPLES

The following shows how one may update image metadata using the PATCH method
supported by version 2 of the Image API.  `@image_updates` is an array of hash
references of the structure defined by the PATCH RFC (6902) governing
"JavaScript Object Notation (JSON) Patch"; i.e., operations consisting of
`add`, `replace`, or `delete`.

    my $headers = {
        'Content-Type' => 'application/openstack-images-v2.1-json-patch'
    };

    my $response = $glance->call({
        'method'  => 'PATCH',
        'headers' => $headers,
        'path'    => qq[/v2/images/$image->{id}],
        'body'    => \@image_updates
    );

# FETCHING REMOTE RESOURCES

- `$client->get(_$path_, _%opts_)`

    Issue an HTTP GET request for resource _$path_.  The keys and values
    specified in _%opts_ will be URL encoded and appended to _$path_ when forming
    the request.  Response bodies are decoded as per `$client->call()`.

- `$client->each(_$path_, _$opts_, _$callback_)`
- `$client->each(_$path_, _$callback_)`

    Issue an HTTP GET request for the resource _$path_, while passing each
    decoded response object to _$callback_ in a single argument.  _$opts_ is taken
    to be a HASH reference containing zero or more key-value pairs to be URL encoded
    as parameters to each GET request made.

- `$client->every(_$path_, _$attribute_, _$opts_, _$callback_)`
- `$client->every(_$path_, _$attribute_, _$callback_)`

    Perform a series of HTTP GET request for the resource _$path_, decoding the
    result set and passing each value within each physical JSON response object's
    attribute named _$attribute_, to the callback _$callback_ as a single
    argument.  _$opts_ is taken to be a HASH reference containing zero or more
    key-value pairs to be URL encoded as parameters to each GET request made.

- `$client->all(_$path_, _$attribute_, _$opts_)`
- `$client->all(_$path_, _$attribute_)`

    Perform a series of HTTP GET requests for the resource _$path_, decoding the
    result set and returning a list of all items found within each response body's
    attribute named _$attribute_.  _$opts_ is taken to be a HASH reference
    containing zero or more key-value pairs to be URL encoded as parameters to each
    GET request made.

# CREATING AND UPDATING REMOTE RESOURCES

- `$client->put(_$path_, _$body_)`

    Issue an HTTP PUT request to the resource at _$path_, in the form of a JSON
    encoding of the contents of _$body_.

- `$client->post(_$path_, _$body_)`

    Issue an HTTP POST request to the resource at _$path_, in the form of a
    JSON encoding of the contents of _$body_.

# DELETING REMOTE RESOURCES

- `$client->delete(_$path_)`

    Issue an HTTP DELETE request of the resource at _$path_.

# SEE ALSO

- [OpenStack::Client::Auth](https://metacpan.org/pod/OpenStack::Client::Auth)

    The OpenStack Keystone authentication and authorization interface

# AUTHOR

Written by Alexandra Hrefna Hilmisdóttir <xan@cpanel.net>

# CONTRIBUTORS

- Brett Estrade <brett@cpanel.net>

# COPYRIGHT

Copyright (c) 2018 cPanel, L.L.C.  Released under the terms of the MIT license.
See LICENSE for further details.
