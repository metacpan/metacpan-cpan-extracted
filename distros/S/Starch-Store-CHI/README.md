# NAME

Starch::Store::CHI - Starch storage backend using CHI.

# SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::CHI',
            chi => {
                driver => 'File',
                root_dir => '/path/to/root',
            },
        },
        ...,
    );

# DESCRIPTION

This [Starch](https://metacpan.org/pod/Starch) store uses [CHI](https://metacpan.org/pod/CHI) to set and get state data.

# EXCEPTIONS

By default [CHI](https://metacpan.org/pod/CHI) will catch errors and log them using [Log::Any](https://metacpan.org/pod/Log::Any)
and keep on going as if nothing went wrong.  In Starch, stores are
expected to loudly throw exceptions, so it is suggested that you
specify these arguments to your CHI driver:

    on_get_error => 'die',
    on_set_error => 'die',

And then, if you still want the errors logged, you can use
[Starch::Plugin::LogStoreExceptions](https://metacpan.org/pod/Starch::Plugin::LogStoreExceptions).  This is especially
important if you are using the [Starch::Plugin::TimeoutStore](https://metacpan.org/pod/Starch::Plugin::TimeoutStore)
plugin which will throw an exception when the timeout is exceeded
which then CHI will catch and log by default, which is not what
you want.

# PERFORMANCE

When using CHI there are various choices you need to make:

- Which backend to use?  If data persistence is not an issue, or
you're using CHI as your outer store in [Starch::Store::Layered](https://metacpan.org/pod/Starch::Store::Layered)
then Memcached or Redis are common solutions which have high
performance.
- Which serializer to use?  Nowadays [Sereal](https://metacpan.org/pod/Sereal) is the serialization
performance heavyweight, with [JSON::XS](https://metacpan.org/pod/JSON::XS) coming up a close second.
- Which driver to use?  Some backends have more than one driver, and
some drivers perform better than others.  The most common example of
this is Memcached which has three drivers which can be used with
CHI.

Make sure you ask these questions when you implement CHI for
Starch, and take the time to answer them well.  It can make a big
difference.

# REQUIRED ARGUMENTS

## chi

This must be set to either hash ref arguments for [CHI](https://metacpan.org/pod/CHI) or a
pre-built CHI object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
[method proxy](https://metacpan.org/pod/Starch#METHOD-PROXIES)
is a good way to link your existing [CHI](https://metacpan.org/pod/CHI) object constructor
in with Starch so that starch doesn't build its own.

# METHODS

## set

Set ["set" in Starch::Store](https://metacpan.org/pod/Starch::Store#set).

## get

Set ["get" in Starch::Store](https://metacpan.org/pod/Starch::Store#get).

## remove

Set ["remove" in Starch::Store](https://metacpan.org/pod/Starch::Store#remove).

# SUPPORT

Please submit bugs and feature requests to the
Starch-Store-CHI GitHub issue tracker:

[https://github.com/bluefeet/Starch-Store-CHI/issues](https://github.com/bluefeet/Starch-Store-CHI/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
