# NAME

Starch::Plugin::TimeoutStore - Throw an exception if store access surpass a timeout.

# SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::TimeoutStore'],
        store => {
            class => '::Memory',
            timeout => 0.1, # 1/10th of a second
        },
        ...,
    );

# DESCRIPTION

This plugin causes all calls to `set`, `get`, and `remove` to throw
an exception if they surpass a timeout period.

The timeout is implemented using [Sys::SigAction](https://metacpan.org/pod/Sys::SigAction).

Note that some stores implement timeouts themselves and their native
may be better than this naive implementation.

The whole point of detecting timeouts is so that you can still serve
a web page even if the underlying store backend is failing, so
using this plugin with [Starch::Plugin::LogStoreExceptions](https://metacpan.org/pod/Starch::Plugin::LogStoreExceptions) is
probably a good idea.

# OPTIONAL STORE ARGUMENTS

These arguments are added to classes which consume the
[Starch::Store](https://metacpan.org/pod/Starch::Store) role.

## timeout

How many seconds to timeout.  Fractional seconds may be passed, but
may not be supported on all systems (see ["ABSTRACT" in Sys::SigAction](https://metacpan.org/pod/Sys::SigAction#ABSTRACT)).
Set to `0` to disable timeout checking.  Defaults to `0`.

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
