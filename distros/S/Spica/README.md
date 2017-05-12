# NAME

Spica - the HTTP client for dealing with complex WEB API.

# SYNOPSIS

    my $spica = Spica->new(
        host => 'example.com',
        spec => 'Example::Spec',
    );

    my $iterator = $spica->fetch(client => 'list' => +{key => $value});

# DESCRIPTION

Spica provides an interface to common WEB API many. It is the HTTP Client that combines the flexibility and scalability of a O/R Mapper and Model of Backbone.js. 

# SIMPLEST CASE

create Spica's instance. arguments `host` must be required. fetch returned object is  `Spica::Receiver::Iterator`.

    my $spica = Spica->new(
        host => 'example.com'
    );

    my $iterator = $spica->fetch('/users', +{
        rows => 20,
    });

# THE BASIC USAGE

create specifiction class.
see `Spica::Spec` for docs on defining spec class.

    package Your::API::Spec;
    use Spica::Spec::Declare;

    client {
        name 'example';
        endpoint list => '/users' => [];
        columns qw( id name message );
    };

    1;

in your script.

    use Spica;

    my $spica = Spica->new(
        host => 'example.com',
        spec => 'Your::API::Spec',
    );

    # fetching WEB API.
    my $iterator = $spca->fetch('example', 'list', +{});

    while (my $user = $iterator->next) {
        say $user->name;
    }

# ARCHITECTURE

Spica iclasses are comprised of following distinct components:

## CLIENT

`client` is a class with information about how to receipt of the request parameter data for WEB API.
`client` uses `Spica::Spec::Iterator` the receipt of data and GET request as the initial value, but I can cope with a wide range of API specification by extending in `spec`.

## SPEC

The `spec` is a simple class that describes specifictions of the WEB API.
`spec` is a simple class that describes the specifications of the WEB API. You can extend the `client` by changing the `receiver` class you can specify the HTTP request other than GET request.

    package Your::Spec;
    use Spica::Spec::Declare;

    client {
        name 'example';
        endpoint 'name1', '/path/to', [qw(column1 column2)];
        endpoint 'name2', '/path/to/{replace}, [qw(replace_column column)];
        endpoint 'name3', +{
            method   => 'POST',
            path     => '/path/to',
            requires => [qw(column1 column2)],
        };
        columns qw(
            column1
            column2
        );
    }

    ... and other clients ...

## PARSER

`parser` is a class for to be converted to a format that can be handled in Perl format that the API provides.
You can use an API of its own format if you extend the `Spica::Parser`

    package Your::Parser;
    use parent qw(Spica::Parser);

    use Data::MessagePack;

    sub parser {
        my $self = shift;
        return $self->{parser} ||= Data::MessagePack->new;
    }

    sub parse {
        my ($self, $body) = @_;
        return $self->parser->unpack($body);
    }

    1;

in your script

    my $spica = Spica->new(%args);

    $spica->parser('Your::Parser');

## RECEIVER

`receiver` is a class for easier handling more data received from the WEB API.
`receiver` This contains the `Spica::Receiver::Row` and `Spica::Receiver::Iterator`.

# METHODS

Spica provides a number of methods to all your classes, 



## $spica = Spica->new(%args)

Creates a new Spica instance.

    my $spica = Spica->new(
        host => 'example.com',
        spec => 'Your::Spec',
    );

Arguments can be:

- `scheme`

    This is the URI scheme of WEB API.
    By default, `http` is used.

- `host` :Str

    This is the URI hostname of WEB API.
    This argument is always required.

- `port` :Int

    This is the URI port of WEB API.
    By default, `80` is used.

- `agent` :Str

    This is the Fetcher agent name of Spica.
    By default, `Spica $VERSION` is used.

- `default_param` :HashRef

    You can specify the parameters common to request the WEB API.

- `default_headers` :ArrayRef

    You can specify the headers common to request the WEB API.

- `spec`

    `spec` expecs the name of the class that inherits `Spiac::Spec`.
    By default, `spec` is not used.

- `parser`

    `parser` expects the name of the class that inherits `Spica::Parser`.
    By default, `Spica::Parser::JSON` is used.

- `is_suppress_object_creation`

    Specifies the receiver object creation mode. By default this value is `false`.
    If you specifies this to a `true` value, no row object will be created when
    a receive on WEB API results.

- `no_throw_http_exception`

    Specifies the mode that does not throw the exception of HTTP. 
    by default this value is `false`.

## $iterator = $spica->fetch(@args);

Request to the WEB API, to build the object.
I have the interface of the following three:

### $spica->fetch($client\_name, $endpoint\_name, $param)

It is the access method basic.

Arguments can be:

- `client_name` : Str

    Enter the name of the client that you have defined in `spec`.

- `endpoint_name` : Str

    Enter the name of `endpoint` that is defined in the `client`.

- `param` : HashRef

    Specified in `HashRef` the content and query parameters required to request. I will specify the HashRef empty if there are no parameters.

### $spica->fetch($client\_name, $param)

You can omit the `endpoint_name` of `fetch` If you specify a string of `default` to `name` of <endpoint>.

Arguments can be:

- `client_name` : Str
- `param` : HashRef

### $spica->fetch($path, $param)

You can request by specifying to fetch the <path> If you do not specify the `spec`.

Arguments can be:

- `path` : Str
- `param` : HashRef

# SEE ALSO

# AUTHOR

mizuki\_r <ry.mizuki@gmail.com>

# REPOSITORY

    git clone git@github.com:rymizuki/p5-Spica.git

# LICENCE AND COPYRIGHT

Copyright (c) 2013, the Spica ["AUTHOR"](#AUTHOR). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](http://search.cpan.org/perldoc?perlartistic).
