[![Build Status](https://travis-ci.org/tokuhirom/Module-Spy.svg?branch=master)](https://travis-ci.org/tokuhirom/Module-Spy)
# NAME

Module::Spy - Spy for Perl5

# SYNOPSIS

Spy for class method.

    use Module::Spy;

    my $spy = spy_on('LWP::UserAgent', 'request');
    $spy->and_returns(HTTP::Response->new(200));

    my $res = LWP::UserAgent->new()->get('http://mixi.jp/');

Spy for object method

    use Module::Spy;

    my $ua = LWP::UserAgent->new();
    my $spy = spy_on($ua, 'request')->and_returns(HTTP::Response->new(200));

    my $res = $ua->get('http://mixi.jp/');

    ok $spy->called;

# DESCRIPTION

Module::Spy is spy library for Perl5.

# FUNCTIONS

- `my $spy = spy_on($class|$object, $method)`

    Create new spy. Returns new Module::Spy::Class or Module::Spy::Object instance.

# Module::Spy::(Class|Object) methods

- `$spy->called() :Bool`
- `$spy->and_called() :Bool`

    Returns true value if the method was called. False otherwise.

- `$spy->returns($value) : Module::Spy::Base`
- `$spy->and_returns($value) : Module::Spy::Base`

    Stub the method's return value as `$value`.

    Returns `<$spy`> itself for method chaining.

- `$spy->and_call_through() : Module::Spy::Base`

    Do not stub the method's return value, calls original implementation.

    Returns `<$spy`> itself for method chaining.

- `$spy->calls_any() : Bool`

    Returns false if the spy has not been called at all, and then true once at least one call happens.

- `$spy->calls_count() : Int`

    Returns the number of times the spy was called

- `$spy->calls_all() : ArrayRef`

    Returns arguments passed all calls

- `$spy->calls_most_recent() : ArrayRef`

    Returns arguments for the most recent call

- `$spy->calls_first() : ArrayRef`

    Returns arguments for the first call

- `$spy->calls_reset()`

    Clears all tracking for a spy

# SEE ALSO

The interface was inspired from Jasmine library [http://jasmine.github.io/](http://jasmine.github.io/).

# LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>
