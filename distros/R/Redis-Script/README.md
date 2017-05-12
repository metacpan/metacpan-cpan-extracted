[![Build Status](https://travis-ci.org/shogo82148/p5-Redis-Script.svg?branch=master)](https://travis-ci.org/shogo82148/p5-Redis-Script)
# NAME

Redis::Script - wrapper class for Redis' script

# SYNOPSIS

    # OO-interface
    use Redis;
    use Redis::Script;
    my $script = Redis::Script->new(script => "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}");
    my ($key1, $key2, $arg1, $arg2) = $script->eval(Redis->new, ['key1', 'key2'], ['arg1', 'arg2']);
    
    # Functional
    use Redis::Script qw/redis_eval/;
    my ($key1, $key2, $arg1, $arg2) = redis_eval(Redis->new, "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}", ['key1', 'key2'], ['arg1', 'arg2']);

# DESCRIPTION

Redis::Script is wrapper class for Redis' script.

# FUNCTIONS

## `$script->eval($redis:Redis, $keys:ArrayRef, $args:ArrayRef)`

`eval` executes the script by `EVALSHA` command.
If `EVALSHA` reports "No matching script", use `EVAL` instead of `EVALSHA`.
Redis will cache the script of `EVAL` command, so `EVALSHA` will succeed next time.

If `use_evalsha` option is false, `eval` does not use `EVALSHA` command.

## `$script->exists($redis:Redis)`

`exists` reports if `$redis` caches the script.

## `$script->load($redis:Redis)`

Load a script into the scripts cache, without executing it.

# SEE ALSO

- [Redis.pm](https://metacpan.org/pod/Redis)
- [Redis::Fast](https://metacpan.org/pod/Redis::Fast)
- [Description of EVAL](http://redis.io/commands/eval#bandwidth-and-evalsha)

# LICENSE

Copyright (C) Ichinose Shogo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ichinose Shogo <shogo82148@gmail.com>
