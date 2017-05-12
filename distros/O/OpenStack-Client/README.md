# NAME

OpenStack::Client - A cute little client to OpenStack services

# SYNOPSIS

    #
    # First, connect to an API endpoint via the Keystone authorization service
    #
    use OpenStack::Client::Auth ();

    my $auth = OpenStack::Client::Auth->new('http://openstack.foo.bar:5000/v2.0',
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

    my $glance = OpenStack::Client->new('http://glance.foo.bar:9292',
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

- `$client->call(_$method_, _$path_, _$body_)`

    Perform a call to the service endpoint using the HTTP method _$method_,
    accessing the resource _$path_ (relative to the absolute endpoint URI), passing
    an arbitrary value in _$body_ that is to be encoded to JSON as a request
    body.  This method may return the following:

    - For **application/json**: A decoded JSON object
    - For other response types: The unmodified response body

    In exceptional conditions (such as when the service returns a 4xx or 5xx HTTP
    response), the client will `die()` with the raw text response from the HTTP
    service, indicating the nature of the service-side failure to service the
    current call.

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

Written by Alexandra Hrefna Hilmisdóttir &lt;xan@cpanel.net>

# COPYRIGHT

Copyright (c) 2015 cPanel, Inc.  Released under the terms of the MIT license.
See LICENSE for further details.
