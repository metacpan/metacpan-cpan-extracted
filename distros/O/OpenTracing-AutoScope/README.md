# Perl - OpenTracing AutoScope

Making life easyier with 'auto-closing guarded scopes', instead of keeping track
manually.

## SYNOPSIS

```perl
MyPackage;

use OpenTracing::AutoScope;

sub foo {
    OpenTracing::AutoScope->start_guarded_span;
    
    ...
    
    return $foo
}
```

## DESCRIPTION

Using the C<start_guarded_span> class method is just a convenience around things
like:

```perl
use OpenTracing::GlobalTracer qw/$TRACER/;

sub foo {
    my $scope = $TRACER->start_active_span( 'MyPackage::foo' => { options };
    
    my $self = shift;
    
    ... # do stuff
    
    $scope->close
    
    return $foo
}
```

## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
