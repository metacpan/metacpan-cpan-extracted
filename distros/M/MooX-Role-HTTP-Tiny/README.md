# NAME

MooX::Role::HTTP::Tiny - [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) as a role for clients that use HTTP

# SYNOPSIS

```perl
    package My::Client;
    use Moo;
    with 'MooX::Role::HTTP::Tiny';
    use JSON 'encode_json';

    # implent a call to the API of a webservice
    sub call {
        my $self = shift;
        my ($method, $path, $args) = @_;
        my $uri = $self->base_uri->clone;
        $uri->path($uri->path =~ m{ / $}x ? $uri->path . $path : $path)
            if $path;

        my $params;
        if (uc($method) eq 'GET') {
            my $query = $self->ua->www_form_urlencode($args);
            $uri->query($query);
        }
        else {
            $params = $args ? { content => encode_json($args) } : undef;
        }

        my $response = $self->ua->request(uc($method), $uri, $params);
        if (not $response->{success}) {
            die(sprintf("ERROR: %s: %s\n", $response->{reason}, $response->{content}));
        }
        return $response;
    }
    1;

    package My::API;
    use Moo;
    use Types::Standard qw( InstanceOf );
    has client => (
        is       => 'ro',
        isa      => InstanceOf ['My::Client']
        required => 1,
    );
    sub fetch_stuff {
        my $self = shift;
        return $self->client->call(@_);
    }
    1;

    package main;
    use My::Client;
    use My::API;
    my $client = My::Client->new(
        base_uri => ' https://fastapi.metacpan.org/v1/release/_search'
    );
    my $api = My::API->new(client => $client);
    my $response = $api->fetch_stuff(get => '', {q => 'MooX-Role-HTTP-Tiny'});
    print $response->{content};
```

# ATTRIBUTES

- **base\_uri** \[REQUIRED\] The base-uri to the webservice

    The provided uri will be _coerced_ into a [URI](https://metacpan.org/pod/URI) instance.

- **ua** A (lazy build) instance of [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny)

    When none is provided, [Moo](https://metacpan.org/pod/Moo) will instantiate a [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) with the extra
    options provided in the `ua_options` attribute whenever it is first needed.

- **ua\_options** passed through to the constructor of [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) on lazy-build

    These options can only be passed to constructor of [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny), so won't have
    impact when an already instantiated `ua` attribute is provided.

# REQUIRES

The class that consumes this role needs to implement the method `call()` as a
wrapper around `HTTP::Tiny::request` to suit the remote API one is writing the
client for.

# DESCRIPTION

This role provides a basic HTTP useragent (based on [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny)) for classes
that want to implement a client to any webservice that uses the HTTP(S)
transport protocol.

The best known protocols are _XMLRPC_, _XMLRPC_ and _REST_, and can be
implemented through the required `call()` method.

# COPYRIGHT

&copy; MMXXI - Abe Timmerman <abeltje@cpan.org>
