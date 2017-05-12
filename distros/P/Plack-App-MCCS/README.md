# NAME

Plack::App::MCCS - Minify, Compress, Cache-control and Serve static files from Plack applications

# EXTENDS

[Plack::Component](https://metacpan.org/pod/Plack::Component)

# SYNOPSIS

        # in your app.psgi:
        use Plack::Builder;
        use Plack::App::MCCS;

        my $app = sub { ... };

        # be happy with the defaults:
        builder {
                mount '/static' => Plack::App::MCCS->new(root => '/path/to/static_files')->to_app;
                mount '/' => $app;
        };

        # or tweak the app to suit your needs:
        builder {
                mount '/static' => Plack::App::MCCS->new(
                        root => '/path/to/static_files',
                        min_cache_dir => 'min_cache',
                        defaults => {
                                valid_for => 86400,
                                cache_control => ['private'],
                        },
                        types => {
                                '.htc' => {
                                        content_type => 'text/x-component',
                                        valid_for => 360,
                                        cache_control => ['no-cache', 'must-revalidate'],
                                },
                        },
                )->to_app;
                mount '/' => $app;
        };

        # or use the supplied middleware
        builder {
                enable 'Plack::Middleware::MCCS',
                        path => qr{^/static/},
                        root => '/path/to/static_files'; # all other options are supported
                $app;
        };

# DESCRIPTION

`Plack::App::MCCS` is a [Plack](https://metacpan.org/pod/Plack) application that serves static files
from a directory. It will prefer serving precompressed versions of files
if they exist and the client supports it, and also prefer minified versions
of CSS/JS files if they exist.

If [IO::Compress::Gzip](https://metacpan.org/pod/IO::Compress::Gzip) is installed, `MCCS` will also automatically
compress files that do not have a precompressed version and save the compressed
versions to disk (so it only happens once and not on every request to the
same file).

If [CSS::Minifier::XS](https://metacpan.org/pod/CSS::Minifier::XS) and/or [JavaScript::Minifier::XS](https://metacpan.org/pod/JavaScript::Minifier::XS) are installed,
it will also automatically minify CSS/JS files that do not have a preminified
version and save them to disk (once again, will only happen once per file).

This means `MCCS` needs to have write privileges to the static files directory.
It would be better if files are preminified and precompressed, say automatically
in your build process (if such a process exists). However, at some projects
where you don't have an automatic build process, it is not uncommon to
forget to minify/precompress. That's where automatic minification/compression
is useful.

Most importantly, `MCCS` will generate proper Cache Control headers for
every file served, including `Last-Modified`, `Expires`, `Cache-Control`
and even `ETag` (ETags are created automatically, once per file, and saved
to disk for future requests). It will appropriately respond with `304 Not Modified`
for requests with headers `If-Modified-Since` or `If-None-Match` when
these cache validations are fulfilled, without actually having to read the
files' contents again.

`MCCS` is active by default, which means that if there are some things
you _don't_ want it to do, you have to _tell_ it not to. This is on purpose,
because doing these actions is the whole point of `MCCS`.

## WAIT, AREN'T THERE EXISTING PLACK MIDDLEWARES FOR THAT?

Yes and no. A similar functionality can be added to an application by using
the following Plack middlewares:

- [Plack::Middleware::Static](https://metacpan.org/pod/Plack::Middleware::Static) or [Plack::App::File](https://metacpan.org/pod/Plack::App::File) - will serve static files
- [Plack::Middleware::Static::Minifier](https://metacpan.org/pod/Plack::Middleware::Static::Minifier) - will minify CSS/JS
- [Plack::Middleware::Precompressed](https://metacpan.org/pod/Plack::Middleware::Precompressed) - will serve precompressed .gz files
- [Plack::Middleware::Deflater](https://metacpan.org/pod/Plack::Middleware::Deflater) - will compress representations with gzip/deflate algorithms
- [Plack::Middleware::ETag](https://metacpan.org/pod/Plack::Middleware::ETag) - will create ETags for files
- [Plack::Middleware::ConditionalGET](https://metacpan.org/pod/Plack::Middleware::ConditionalGET) - will handle `If-None-Match` and `If-Modified-Since`
- [Plack::Middleware::Header](https://metacpan.org/pod/Plack::Middleware::Header) - will allow you to add cache control headers manually

So why wouldn't I just use these middlewares? Here are my reasons:

- `Static::Minifier` will not minify to disk, but will minify on every
request, even to the same file (unless you provide it with a cache, which
is not that better). This pointlessly increases the load on the server.
- `Precompressed` is nice, but it relies on appending `.gz` to every
request and sending it to the app. If the app returns `404 Not Found`, it sends the request again
without the `.gz` part. This might pollute your logs and I guess two requests
to get one file is not better than one request. You can circumvent that with regex matching, but that
isn't very comfortable.
- `Deflater` will not compress to disk, but do that on every request.
So once again, this is a big load on the server for no real reason. It also
has a long standing bug where deflate responses fail on Firefox, which is
annoying.
- `ETag` will calculate the ETag again on every request.
- `ConditionalGET` does not prevent the requested file to be opened
for reading even if `304 Not Modified` is to be returned (since that check is performed later).
I'm not sure if it affects performance in anyway, probably not.
- No possible combination of any of the aformentioned middlewares
seems to return proper (and configurable) Cache Control headers, so you
need to do that manually, possibly with [Plack::Middleware::Header](https://metacpan.org/pod/Plack::Middleware::Header),
which is not just annoying if different file types have different cache
settings, but doesn't even seem to work.
- I don't really wanna use so many middlewares just for this functionality.

`Plack::App::MCCS` attempts to perform all of this faster and better. Read
the next section for more info.

## HOW DOES MCCS HANDLE REQUESTS?

When a request is handed to `Plack::App::MCCS`, the following process
is performed:

- 1. Discovery:

    `MCCS` will try to find the requested path in the root directory. If the
    path is not found, `404 Not Found` is returned. If the path exists but
    is a directory, `403 Forbidden` is returned (directory listings might be
    supported in the future).

- 2. Examination:

    `MCCS` will try to find the content type of the file, either by its extension
    (relying on [Plack::MIME](https://metacpan.org/pod/Plack::MIME) for that), or by a specific setting provided
    to the app by the user (will take precedence). If not found (or file has
    no extension), `text/plain` is assumed (which means you should give your
    files proper extensions if possible).

    `MCCS` will also determine for how long to allow browsers/proxy caches/whatever
    caches to cache the file. By default, it will set a representation as valid
    for 86400 seconds (i.e. one day). However, this can be changed in two ways:
    either by setting a different default when creating an instance of the
    application (see more info at the `new()` method's documentation below),
    or by setting a specific value for certain file types. Also, `MCCS`
    by default sets the `public` option for the `Cache-Control` header,
    meaning caches are allowed to save responses even when authentication is
    performed. You can change that the same way.

- 3. Minification

    If the content type is `text/css` or `application/javascript`, `MCCS`
    will try to find a preminified version of it on disk (directly, not with
    a second request). If found, this version will be marked for serving.
    If not found, and [CSS::Minifier::XS](https://metacpan.org/pod/CSS::Minifier::XS) or [JavaScript::Minifier:XS](https://metacpan.org/pod/JavaScript::Minifier:XS) are
    installed, `MCCS` will minify the file, save the minified version to disk,
    and mark it as the version to serve. Future requests to the same file will
    see the minified version and not minify again.

    `MCCS` searches for files that end with `.min.css` and `.min.js`, and
    that's how it creates them too. So if a request comes to `style.css`,
    `MCCS` will look for `style.min.css`, possibly creating it if not found.
    The request path remains the same (`style.css`) though, even internally.
    If a request comes to `style.min.css` (which you don't really want when
    using `MCCS`), the app will not attempt to minify it again (so you won't
    get things like `style.min.min.css`).

    If `min_cache_dir` is specified, it will do all its searching and storing of
    generated minified files within `root`/`$min_cache_dir` and ignore minified
    files outside that directory.

- 4. Compression

    If the client supports gzip encoding (deflate to be added in the future, probably),
    as noted with the `Accept-Encoding` header, `MCCS` will try to find a precompressed
    version of the file on disk. If found, this version is marked for serving.
    If not found, and [IO::Compress::Gzip](https://metacpan.org/pod/IO::Compress::Gzip) is installed, `MCCS` will compress
    the file, save the gzipped version to disk, and mark it as the version to
    serve. Future requests to the same file will see the compressed version and
    not compress again.

    `MCCS` searches for files that end with `.gz`, and that's how it creates
    them too. So if a request comes to `style.css` (and it was minified in
    the previous step), `MCCS` will look for `style.min.css.gz`, possibly
    creating it if not found. The request path remains the same (`style.css`) though,
    even internally.

- 5. Cache Validation

    If the client provided the `If-Modified-Since` header, `MCCS`
    will determine if the file we're serving has been modified after the supplied
    date, and return `304 Not Modified` immediately if not.

    Unless the file has the 'no-store' cache control option, and if the client
    provided the `If-None-Match` header, `MCCS` will look for
    a file that has the same name as the file we're going to serve, plus an
    `.etag` suffix, such as `style.min.css.gz.etag` for example. If found,
    the contents of this file is read and compared with the provided ETag. If
    the two values are equal, `MCCS` will immediately return `304 Not Modified`.

- 6. ETagging

    If an `.etag` file wasn't found in the previous step (and the file we're
    serving doesn't have the 'no-store' cache control option), `MCCS` will create
    one from the file's inode, last modification date and size. Future requests
    to the same file will see this ETag file, so it is not created again.

- 7. Headers and Cache-Control

    `MCCS` now sets headers, especially cache control headers, as appropriate:

    `Content-Encoding` is set to `gzip` if a compressed version is returned.

    `Content-Length` is set with the size of the file in bytes.

    `Content-Type` is set with the type of the file (if a text file, charset string is appended,
    e.g. `text/css; charset=UTF-8`).

    `Last-Modified` is set with the last modification date of the file in HTTP date format.

    `Expires` is set with the date in which the file will expire (determined in
    stage 2), in HTTP date format.

    `Cache-Control` is set with the number of seconds the representation is valid for
    (unless caching of the file is not allowed) and other options (determined in stage 2).

    `Etag` is set with the ETag value (if exists).

    `Vary` is set with `Accept-Encoding`.

- 8. Serving

    The file handle is returned to the Plack handler/server for serving.

## HOW DO WEB CACHES WORK ANYWAY?

If you need more information on how caches work and cache control headers,
read [this great article](http://www.mnot.net/cache_docs/).

# CLASS METHODS

## new( %opts )

Creates a new instance of this module. `%opts` _must_ have the following keys:

**root** - the path to the root directory where static files reside.

`%opts` _may_ have the following keys:

**encoding** - the character set to append to content-type headers when text
files are returned. Defaults to UTF-8.

**defaults** - a hash-ref with some global defaults, the following options
are supported:

- **valid\_for**: the default number of seconds caches are allowed to save a response.
- **cache\_control**: takes an array-ref of options for the `Cache-Control`
header (all except for `max-age`, which is automatically calculated from
the resource's `valid_for` setting).
- **minify**: give this option a false value (0, empty string, `undef`)
if you don't want `MCCS` to automatically minify CSS/JS files (it will still
look for preminified versions though).
- **compress**: like `minify`, give this option a false value if
you don't want `MCCS` to automatically compress files (it will still look
for precompressed versions).
- **etag**: as above, give this option a false value if you don't want
`MCCS` to automatically create and save ETags. Note that this will mean
`MCCS` will NOT handle ETags at all (so if the client sends the `If-None-Match`
header, `MCCS` will ignore it).

**min\_cache\_dir** - For unminified files, by default minified files are generated
in the same directory as the original file. If this attribute is specified they
are instead generated within `root`/`$min_cache_dir`, and minified files
outside that directory are ignored, unless requested directly. This can make it
easier to filter out generated files when validating a deployment.

Giving `minify`, `compress` and `etag` false values is useful during
development, when you don't want your project to be "polluted" with all
those .gz, .min and .etag files.

**types** - a hash-ref with file extensions that may be served (keys must
begin with a dot, so give '.css' and not 'css'). Every extension takes
a hash-ref that might have **valid\_for** and **cache\_control** as with the
`defaults` option, but also **content\_type** with the content type to return
for files with this extension (useful when [Plack::MIME](https://metacpan.org/pod/Plack::MIME) doesn't know the
content type of a file).

If you don't want something to be cached, you need to give the **valid\_for**
option (either in `defaults` or for a specific file type) a value of either
zero, or preferably any number lower than zero, which will cause `MCCS`
to set an `Expires` header way in the past. You should also pass the **cache\_control**
option `no_store` and probably `no_cache`. When `MCCS` encounteres the
`no_store` option, it does not automatically add the `max-age` option
to the `Cache-Control` header.

# OBJECT METHODS

## call( \\%env )

[Plack](https://metacpan.org/pod/Plack) automatically calls this method to handle a request. This is where
the magic (or disaster) happens.

# CAVEATS AND THINGS TO CONSIDER

- You can't tell `MCCS` to not minify/compress a specific file
type yet but only disable minification/compression altogether (in the
`defaults` setting for the `new()` method).
- Directory listings are not supported yet (not sure if they will be).
- Deflate compression is not supported yet (just gzip).
- Caching middlewares such as [Plack::Middleware::Cache](https://metacpan.org/pod/Plack::Middleware::Cache) and [Plack::Middleware::Cached](https://metacpan.org/pod/Plack::Middleware::Cached)
don't rely on Cache-Control headers (or so I understand) for
their expiration values, which makes them less useful for applications that
rely on `MCCS`. You'll probably be better off with an external cache
like [Varnish](https://www.varnish-cache.org/) if you want a cache on your application server. Even without
a server cache, your application should still appear faster for users due to
browser caching (and also server load should be decreased).
- `Range` requests are not supported. See [Plack::App::File::Range](https://metacpan.org/pod/Plack::App::File::Range) if you need that.
- The app is mounted on a directory and can't be set to only serve
requests that match a certain regex. Use the [middleware](https://metacpan.org/pod/Plack::Middleware::MCCS) for that.

# DIAGNOSTICS

This module doesn't throw any exceptions, instead returning HTTP errors
for the client and possibly issuing some `warn`s. The following list should
help you to determine some potential problems with `MCCS`:

- `"failed gzipping %s: %s"`

    This warning is issued when [IO::Compress::Gzip](https://metacpan.org/pod/IO::Compress::Gzip) fails to gzip a file.
    When it happens, `MCCS` will simply not return a gzipped representation.

- `"Can't open ETag file %s.etag for reading"`

    This warning is issued when `MCCS` can't read an ETag file, probably because
    it does not have enough permissions. The request will still be fulfilled,
    but it won't have the `ETag` header.

- `"Can't open ETag file %s.etag for writing"`

    Same as before, but when `MCCS` can't write an ETag file.

- `403 Forbidden` is returned for files that exist

    If a request for a certain file results in a `403 Forbidden` error, it
    probably means `MCCS` has no read permissions for that file.

# CONFIGURATION AND ENVIRONMENT

`Plack::App::MCCS` requires no configuration files or environment variables.

# DEPENDENCIES

`Plack::App::MCCS` **depends** on the following CPAN modules:

- [parent](https://metacpan.org/pod/parent)
- [Cwd](https://metacpan.org/pod/Cwd)
- [Fcntl](https://metacpan.org/pod/Fcntl)
- [File::Spec::Unix](https://metacpan.org/pod/File::Spec::Unix)
- [Getopt::Long](https://metacpan.org/pod/Getopt::Long)
- [HTTP::Date](https://metacpan.org/pod/HTTP::Date)
- [Module::Load::Conditional](https://metacpan.org/pod/Module::Load::Conditional)
- [Plack](https://metacpan.org/pod/Plack) (obviously)

`Plack::App::MCCS` will use the following modules if they exist, in order
to minify/compress files (if they are not installed, `MCCS` will not be
able to minify/compress on its own):

- [CSS::Minifier::XS](https://metacpan.org/pod/CSS::Minifier::XS)
- [JavaScript::Minifier::XS](https://metacpan.org/pod/JavaScript::Minifier::XS)
- [IO::Compress::Gzip](https://metacpan.org/pod/IO::Compress::Gzip)

# INCOMPATIBILITIES WITH OTHER MODULES

None reported.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
`bug-Plack-App-MCCS@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-App-MCCS](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-App-MCCS).

# SEE ALSO

[Plack::Middleware::MCCS](https://metacpan.org/pod/Plack::Middleware::MCCS), [Plack::Middleware::Static](https://metacpan.org/pod/Plack::Middleware::Static), [Plack::App::File](https://metacpan.org/pod/Plack::App::File), [Plack::Builder](https://metacpan.org/pod/Plack::Builder).

# AUTHOR

Ido Perlmuter <ido@ido50.net>

# ACKNOWLEDGMENTS

Some of this module's code is based on [Plack::App::File](https://metacpan.org/pod/Plack::App::File) by Tatsuhiko Miyagawa
and [Plack::Middleware::ETag](https://metacpan.org/pod/Plack::Middleware::ETag) by Franck Cuny.

Christian Walde contributed new features and fixes for the 1.0.0 release.

# LICENSE AND COPYRIGHT

Copyright (c) 2011-2016, Ido Perlmuter `ido@ido50.net`.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See [perlartistic](https://metacpan.org/pod/perlartistic)
and [perlgpl](https://metacpan.org/pod/perlgpl).

The full text of the license can be found in the
LICENSE file included with this module.

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
