# NAME 

STF::Dispatcher::PSGI - Pluggable STF Dispatcher Interface

# SYNOPSIS

    # in your stf.psgi
    use STF::Dispatcher::PSGI;

    my $object = ...;
    STF::Dispatcher::PSGI->new( impl => $object )->to_app;

# DESCRIPTION

STF::Dispatcher::PSGI implements the basic STF Protocol (http://stf-storage.github.com) dispatcher component. It does not know how to actually store or retrieve data, so you must implement that portion yourself. 

The reason this exists is mainly to allow you to testing systems that interact with STF servers. For example, setting up the main STF implementation is quite a pain if all you want to do is to test your application, but with this module, you can easily create a dummy STF dispatcher.

For example, you can use STF::Dispatcher::Impl::Hash (which stores all data in a has in memory) for your tests:

    # in your stf.psgi
    use STF::Dispatcher::PSGI;
    use STF::Dispatcher::Impl::Hash;

    my $object = STF::Dispatcher::Impl::Hash->new();
    STF::Dispatcher::PSGI->new( impl => $object )->to_app;

And then you can do something like below in your application test to start a dummy STF server with Plack:

    use Plack::Runner;
    use Test::TCP;

    my $guard = Test::TCP->new(sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options('-p' => $port);
        $runner->run( do "stf.psgi" );
    });

    my $stf_uri = sprintf "http://127.0.0.1:%d", $guard->port;
    $ua->get( "$stf_uri/path/to/myobject.png" );

Of course, this is not only useful for testing, but it allows you to create a STF clone with a completely different backend without having to reimplement the entire STF protocol.

# METHODS

## $self = $class->( impl => $object \[, %args \] )

Creates a new instance of STF::Dispatcher::PSGI. __impl__ must be the imeplementation object ([see below](#THE "IMPLEMENTATION" OBJECT)).

Other arguments may include:

- nosniff\_header : Bool

    Automatically adds X-Content-Type-Options: nosniff to the response.

    By default nosniff\_header is enabled.

## $psgi\_app = $self->to\_app()

Creates a PSGI app.

# THE "IMPLEMENTATION" OBJECT

As described elsewhere, this module by itself DOES NOT work as a real STF server. This module will parse the request and extract the required data from that request, but has no idea how to actually use it. You must therefore provide it with an "implementation".

The simplest implementation is provided with this distribution: STF::Dispatcher::Impl::Hash. This implementation simply puts all the objects in an in-memory hash. See [STF](http://search.cpan.org/perldoc?STF) for a heavy duty example.

You can choose to create your own STF implementation. In that case, you need to implement list of methods described later.

In these methods, you may choose to throw an exception instead of returning a response. For example, in [STF](http://search.cpan.org/perldoc?STF), we use X-Reproxy-URL to serve the objects. This means we cannot just return the fetched object. In that case, we throw an exception that [Plack::Middleware::HTTPExceptions](http://search.cpan.org/perldoc?Plack::Middleware::HTTPExceptions) can handle (our to\_app method automatically enables Plack::Middleware::HTTPExceptions).

See the documentation for that module for details.

# LIST OF REQUIRED METHODS IN THE IMPLEMENTATION

## $object = $impl->create\_bucket(%args)

Used to create a bucket.

The implementation's get\_bucket method will receive the following named parameters:

- __request__ => $object

    Plack::Request for this request

- __bucket\_name__ => $string

    The name of the bucket

## $object = $impl->get\_bucket(%args)

Used to retrieve a bucket. If there are no buckets that match the request, you should return undef.

The implementation's get\_bucket method will receive the following named parameters:

- __request__ => $object

    Plack::Request for this request

- __bucket\_name__ => $string

    The name of the bucket

## $object = $impl->get\_object(%args)

Used to retrieve an object. If there are no object that matcht the request, you should return undef.

Note that this method will be called for both GET and HEAD requests.

The implementation's get\_object method will receive the following named parameters:

- __request__ => $object

    Plack::Request for this request

- __bucket__ => $object

    The bucket returned by get\_bucket().

- __object\_name__ => $string

    The name of the object.

- __force\_master__ => $bool

    Set to true if X-STF-Force-MasterDB header was sent

## $impl->delete\_bucket(%args)

- __request__ => $object

    Plack::Request for this request

- __bucket__ => $object

    The bucket returned by get\_bucket().

- __recursive__ => $bool

    Set to true if the X-STF-Recursive-Delete header was specified

## $impl->create\_object(%args)

- __request__ => $object

    Plack::Request for this request

- __bucket__ => $object

    The bucket returned by get\_bucket().

- __object\_name__ => $string

    The name of the object.

- __consistency__ => $int

    The minimum consistency (number of replicas that must be created by the end of create\_object call.

- __size__ => $int

    The size of the object

- __suffix__ => $string

    The suffix to be used for the object. defaults to ".dat"

- __input__ => $handle

    The input handle to read the data from

- __replicas__ => $int

    Number of replicas that the system should keep in the end.

## $impl->modify\_object(%args)

- __replicas__ => $int

    Number of replicas that the system should keep in the end.

- __request__ => $object

    Plack::Request for this request

- __bucket__ => $object

    The bucket returned by get\_bucket().

- __object\_name__ => $string

    The name of the object.

## $impl->delete\_object(%args)

- __request__ => $object

    Plack::Request for this request

- __bucket__ => $object

    The bucket returned by get\_bucket().

- __object\_name__ => $string

    The name of the object.

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

# COPYRIGHT AND LICENSE

Copyright (C) 2011 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.
