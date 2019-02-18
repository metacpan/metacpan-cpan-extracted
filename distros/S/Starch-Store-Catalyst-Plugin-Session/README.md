# NAME

Starch::Store::Catalyst::Plugin::Session - Starch storage backend using
Catalyst::Plugin::Session stores.

# SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::Catalyst::Plugin::Session',
            store_class => '::File',
            session_config => {
                storage => '/tmp/session',
            },
        },
    );

# DESCRIPTION

This [Starch](https://metacpan.org/pod/Starch) store uses [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session) stores
to set and get state data.

The reason this module exists is to make the migration from
the Catalyst session plugin to Starch as painless as possible.

# REQUIRED ARGUMENTS

## store\_class

The full class name for the [Catalyst::Plugin::Session::Store](https://metacpan.org/pod/Catalyst::Plugin::Session::Store) you
wish to use.

If the store class starts with `::` then it will be considered
relative to `Catalyst::Plugin::Session::Store`.  For example, if
you set this to `::File` then it will be internally translated to
`Catalyst::Plugin::Session::Store::File`.

# OPTIONAL ARGUMENTS

## session\_config

The configuration of the session plugin.

# ATTRIBUTES

## store

This is the [Catalyst::Plugin::Session::Store](https://metacpan.org/pod/Catalyst::Plugin::Session::Store) object built from the
["store\_class"](#store_class) and with a fake Catalyst superclass to make everything
work.

# METHODS

## set

See ["set" in Starch::Store](https://metacpan.org/pod/Starch::Store#set).  Calls `store_session_data` on ["store"](#store).

## get

See ["get" in Starch::Store](https://metacpan.org/pod/Starch::Store#get).  Calls `get_session_data` on ["store"](#store).

## remove

See ["remove" in Starch::Store](https://metacpan.org/pod/Starch::Store#remove).  Calls `delete_session_data` on ["store"](#store).

# SUPPORT

Please submit bugs and feature requests to the
Starch-Store-Catalyst-Plugin-Session GitHub issue tracker:

[https://github.com/bluefeet/Starch-Store-Calatlyst-Plugin-Session/issues](https://github.com/bluefeet/Starch-Store-Calatlyst-Plugin-Session/issues)

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
