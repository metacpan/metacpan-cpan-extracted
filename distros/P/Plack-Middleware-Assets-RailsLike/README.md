# NAME

Plack::Middleware::Assets::RailsLike - Bundle and minify JavaScript and CSS files

# SYNOPSIS

    use strict;
    use warnings;
    use MyApp;
    use Plack::Builder;

    my $app = MyApp->new->to_app;
    builder {
        enable 'Assets::RailsLike', root => './htdocs';
        $app;
    };

# WARNING

__This module is under development and considered BETA quality.__

# DESCRIPTION

Plack::Middleware::Assets::RailsLike is a middleware to bundle and minify
JavaScript and CSS (included Sass and LESS) files like Ruby on Rails Asset
Pipeline.

At first, you create a manifest file. The Manifest file is a list of JavaScript
and CSS files you want to bundle. You can also use Sass and LESS as css files.
The Manifest syntax is same as Rails Asset Pipeline, but only support
`require` command.

    > vim ./htdocs/assets/main-page.js
    > cat ./htdocs/assets/main-page.js
    //= require jquery
    //= require myapp



Next, write URLs of manifest file to your html. This middleware supports
versioning. So you can add version string in between its file basename and
suffix.

    <- $basename-$version.$suffix ->
    <script type="text/javascript" src="/assets/main-page-v2013060701.js">

If manifest files were requested, bundle files in manifest file and serve it or
serve bundled data from cache. In this case, find jquery.js and myapp.js from
search path (default search path is `$root`/assets). This middleware return
HTTP response with `Cache-Control`, `Expires` and `Etag`. `Cache-Control`
and `Expires` are computed from the `expires` option. `Etag` is computed
from bundled content.

# CONFIGURATIONS

- root

    Document root to find manifest files to serve.

    Default value is current directory('.').

- path

    The URL pattern (regular expression) for matching.

    Default value is `qr{^/assets}`.

- search\_path

    Paths to find javascript and css files.

    Default value is `[qw($root/assets)]`.

- minify

    Minify javascript and css files if true.

    Default value is `1`.

- cache

    Store concatenated data in memory by default using [Cache::MemoryCache](http://search.cpan.org/perldoc?Cache::MemoryCache). The
    `cache` option must be a object implemented `get` and `set` methods. For
    example, [Cache::Memcached::Fast](http://search.cpan.org/perldoc?Cache::Memcached::Fast). If `$ENV{PLACK_ENV} eq "development"` and
    you didn't pass a cache object, cache is disabled.

    Default is a [Cache::MemoryCache](http://search.cpan.org/perldoc?Cache::MemoryCache) Object.

        Cache::MemoryCache->new({
            namespace           => "Plack::Middleware::Assets::RailsLike",
            default_expires_in  => $expires
            auto_purge_interval => '1 day',
            auto_purge_on_set   => 1,
            auto_purge_on_get   => 1
        })

- expires

    Expiration of the cache and Cache-Control, Expires headers in HTTP response.
    The format of This option is same as default\_expires\_in option of
    [Cache::Cache](http://search.cpan.org/perldoc?Cache::Cache). See [Cache::Cache](http://search.cpan.org/perldoc?Cache::Cache) for more details.

    Default is `'3 days'`.

# PRECOMPILE

This distribution includes [assets-railslike-precompiler.pl](http://search.cpan.org/perldoc?assets-railslike-precompiler.pl). This script can
pre-compile manifest files. See perldoc [assets-railslike-precompiler.pl](http://search.cpan.org/perldoc?assets-railslike-precompiler.pl) for
more details.

I strongly recommend using pre-compiled files with
[Plack::Middleware::Static](http://search.cpan.org/perldoc?Plack::Middleware::Static) in the production environment.

# MOTIVATION

I want a middleware has futures below.

    1. Concat JavaScript and CSS
    2. Minify contents
    3. Cache a compiled data
    4. Version string in filename
    5. Support Sass and LESS files
    6. Less configuration
    7. Pre-compile

[Plack::Middleware::StaticShared](http://search.cpan.org/perldoc?Plack::Middleware::StaticShared) is good choice for me. But it needs to write
definitions for each resource types. And its URL format is a bit strange.

# SEE ALSO

[Plack::Middleware::StaticShared](http://search.cpan.org/perldoc?Plack::Middleware::StaticShared)

[Plack::Middleware::Assets](http://search.cpan.org/perldoc?Plack::Middleware::Assets)

[Plack::App::MCCS](http://search.cpan.org/perldoc?Plack::App::MCCS)

[Plack::Middleware::Static::Combine](http://search.cpan.org/perldoc?Plack::Middleware::Static::Combine)

[Plack::Middleware::Static::Minifier](http://search.cpan.org/perldoc?Plack::Middleware::Static::Minifier)

[Plack::Middleware::Compile](http://search.cpan.org/perldoc?Plack::Middleware::Compile)

[Plack::Middleware::JSConcat](http://search.cpan.org/perldoc?Plack::Middleware::JSConcat)

[Catalyst::Plugin::Assets](http://search.cpan.org/perldoc?Catalyst::Plugin::Assets)

# DEPENDENCIES

[Plack](http://search.cpan.org/perldoc?Plack)

[Cache::Cache](http://search.cpan.org/perldoc?Cache::Cache)

[File::Slurp](http://search.cpan.org/perldoc?File::Slurp)

[JavaScript::Minifier::XS](http://search.cpan.org/perldoc?JavaScript::Minifier::XS)

[CSS::Minifier::XS](http://search.cpan.org/perldoc?CSS::Minifier::XS)

[Digest::SHA1](http://search.cpan.org/perldoc?Digest::SHA1)

[HTTP::Date](http://search.cpan.org/perldoc?HTTP::Date)

[Text::Sass](http://search.cpan.org/perldoc?Text::Sass)

[CSS::LESSp](http://search.cpan.org/perldoc?CSS::LESSp)

# LICENSE

Copyright (C) 2013 Yoshihiro Sasaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yoshihiro Sasaki <ysasaki@cpan.org>
