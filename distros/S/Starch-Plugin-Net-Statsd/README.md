# NAME

Starch::Plugin::Net::Statsd - Record store timing information to statsd.

# SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::Net::Statsd'],
    );

# DESCRIPTION

This plugin will record get, set, and remove store timings to statsd
using [Net::Statsd](https://metacpan.org/pod/Net::Statsd).

By default, for example, if you are using [Starch::Store::Memory](https://metacpan.org/pod/Starch::Store::Memory), stats
like this will be recorded:

    starch.Memory.set
    starch.Memory.get-hit
    starch.Memory.get-miss
    starch.Memory.remove
    starch.Memory.set-error
    starch.Memory.get-error
    starch.Memory.remove-error

Note that stats will not be collected for [Starch::Store::Layered](https://metacpan.org/pod/Starch::Store::Layered), as
data about it isn't really useful as its just a proxy store.

Since this plugin detects exceptions and records the `*-error` stats for
them you should, if you are using it, put the [Starch::Plugin::LogStoreExceptions](https://metacpan.org/pod/Starch::Plugin::LogStoreExceptions)
plugin after this plugin in the plugins list.  If you don't then exceptions
will be turned into log messages before this store gets to see them.

# MANAGER OPTIONAL ARGUMENTS

## statsd\_host

Setting this will cause the `$Net::Statsd::HOST` variable to be
localized to it before the timing information is recorded.

## statsd\_port

Setting this will cause the `$Net::Statsd::PORT` variable to be
localized to it before the timing information is recorded.

## statsd\_root\_path

The path to store all of the Starch timing stats in, defaults to
`starch`.

## statsd\_sample\_rate

The sample rate to use, defaults to `1`.  See ["ABOUT SAMPLING" in Net::Statsd](https://metacpan.org/pod/Net::Statsd#ABOUT-SAMPLING).

# STORE OPTIONAL ARGUMENTS

## statsd\_path

The path prefix which will be appended to the ["statsd\_root\_path"](#statsd_root_path).
Defaults to ["short\_store\_class\_name" in Starch::Store](https://metacpan.org/pod/Starch::Store#short_store_class_name), but normalized to
be a valid graphite path.

## statsd\_full\_path

This is the full path, `statsd_root_path.statsd_path`.  This can be
set to override ["statsd\_root\_path"](#statsd_root_path) and ["statsd\_path"](#statsd_path).

# SUPPORT

Please submit bugs and feature requests to the
Starch-Plugin-Net-Statsd GitHub issue tracker:

[https://github.com/bluefeet/Starch-Plugin-Net-Statsd/issues](https://github.com/bluefeet/Starch-Plugin-Net-Statsd/issues)

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
