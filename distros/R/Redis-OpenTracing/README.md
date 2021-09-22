# Redis::OpenTracing

Wrap Redis inside OpenTracing

## Synopsis

```perl
package My::Awesome::Module;

use strict;
use warnings;

use Redis;
use Redis::OpenTracing;

my $redis = Redis::OpenTracing->new(
    redis => Redis->new( ... )
);

my $value = $redis->get 'my-key';

1;
```

## Description

The example above will use the default Redis server (from `$ENV{REDIS_SERVER}`) and the Global Tracer (from `$ENV{OPENTRACING_IMPLEMENTATION}`.
It will create span with the name `Redis::GET`, enriched with package / subroutine name and line number for easy debugging.

## Author

Theo van Hoesel <tvanhoesel@perceptyx.com>

## Copyright and License

'Redis::OpenTracing' is Copyright (C) 2021, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
This library is distributed in the hope that it will be useful, but it is provided "as is" and without any express or implied warranties.
For details, see the full text of the license in the file LICENSE.
