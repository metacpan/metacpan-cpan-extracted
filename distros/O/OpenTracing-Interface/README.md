## COPYRIGHT NOTICE

'OpenTracing API for Perl' is Copyright (C) 2019, Perceptyx Inc, Theo van Hoesel

# OpenTracing API for Perl

This package describes the OpenTracing API for Perl

## Required Reading

In order to understand the Perl platform API, one must first be familiar with
[the OpenTracing project](http://opentracing.io/)
and
[terminology](http://opentracing.io/documentation/pages/spec)
more generally.

## Usage

### Initialize the Tracer Singleton

```perl
use OpenTracing::Implementation qw/YourTracingService/;
```

### Access the Tracer Singleton

```perl
use OpenTracing::GlobalTracer qw/$TRACER/;
```

### Direct control over Tracing instead of using singletons

```perl
use YourImplementation::Tracer;

my $TRACER = YourImplementation::Tracer->new( %options );
```

### Add a new span inside a subroutine

```perl
sub some_work {
    my $opentracing_scope =
        $TRACER->start_active_span( 'some_operation_name' );
    
    ...
    
    $opentracing_scope->close
    
    return ...
}
```

### Inject a SpanContext into an outgoing request:

```perl
my $opentracing_spancontext = $TRACER->get_active_span->get_context;

use HTTP::Headers;
my $http_headers = HTTP::Headers->new( ... );

my $cntx_headers = $TRACER->inject_context(
    OPENTRACING_FORMAT_HTTP_HEADERS => $http_headers,
    $opentracing_spancontext,
);

my $request = HTTP::Request->new(
    GET => 'https://...', $cntx_headers
);
my response = LWP::UserAgent->request( $request );
```

### Extract a SpanContext from an incoming request

```perl
use YourFramework;

get '/some_service' => sub {
    my $http_headers = YourFramework->request->headers;
    
    my $opentracing_context = $TRACER->extract_context(
        OPENTRACING_FORMAT_HTTP_HEADERS => $http_headers
    );
    
    ...
    
}
```

## Description

This package - `OpenTracing::Interface` - describes the API definition for
OpenTransport implementations written in the Perl5 language.

This being Perl, and strongly influenced by TIMTOWDI principals, this package
does not intent to be a base class that tracer implementors need to subclass.
Moreover, the specification is written as POD. Write your own implementation
however you want as long as it adheres to the written POD specification.

A set of L<Role::Tiny> roles are provided, that can be consumed into your own
implementations that will ensure that required methods are present. Those roles
also do type checking ( using `Type::Tiny` and friends )on input params and
returned values. Other than that, those roles do nothing and can be ignored.


## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This library is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.

