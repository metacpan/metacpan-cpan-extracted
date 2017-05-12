# NAME

Mojolicious::Plugin::Alias - serve static files from aliased paths

# SYNOPSIS

    # Mojolicious
    $self->plugin('alias', { '/images' => '/foo/bar/dir/images',
                             '/css' => '/here/docs/html/css' } );

    # Mojolicious::Lite
    plugin alias => { '/people/fry/photos' => '/data/foo/frang' };

    # statics embedded in __DATA__
    plugin alias => { '/people' => {classes => ['main']} };

    # multiple paths also possible
    plugin alias => { '/people/leela/photos' =>
        { paths => [
                     '/data/foo/zoop',
                     '/data/bar/public'
                   ] } };

# DESCRIPTION

[Mojolicious::Plugin::Alias](https://metacpan.org/pod/Mojolicious::Plugin::Alias) lets you map specific routes to collections
of static files. While by default a Mojolicious app will serve static files
located in any directory in the `app-`static->paths> array, 
[Mojolicious::Plugin::Alias](https://metacpan.org/pod/Mojolicious::Plugin::Alias) will set up a seperate Mojolicious::Static
object to serve files according to the specified prefix in the URL path.

When developing with the stand-alone webserver, this module allows you to
mimic server paths that might be used in your templates.

# CONFIGURATION

When installing the plugin, pass a reference to a hash of aliases (server
paths). The keys of the hash are URL path prefixes and must start with a '/'
( leading slash). The values of the hash can be either directory paths (a
single string) or hash references that will initialize [Mojolicious::Static](https://metacpan.org/pod/Mojolicious::Static)
objects - they must have either `paths` or `classes` keys, with array reference
values.

# AUTHOR

Dotan Dimet, `dotan@corky.net`.

# COPYRIGHT

Copyright (C) 2010,2014, Dotan Dimet.

# LICENSE

Artistic 2.0

&#x3d;=head1 SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicious.org](http://mojolicious.org).
