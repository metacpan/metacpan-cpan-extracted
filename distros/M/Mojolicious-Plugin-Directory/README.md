# NAME

Mojolicious::Plugin::Directory - Serve static files from document root with directory index

# SYNOPSIS

    # simple usage
    use Mojolicious::Lite;
    plugin( 'Directory', root => "/path/to/htdocs" )->start;

    # with handler
    use Text::Markdown qw{ markdown };
    use Path::Class;
    use Encode qw{ decode_utf8 };
    plugin('Directory', root => "/path/to/htdocs", handler => sub {
        my ($c, $path) = @_;
        if ( -f $path && $path =~ /\.(md|mkdn)$/ ) {
            my $text = file($path)->slurp;
            my $html = markdown( decode_utf8($text) );
            $c->render( inline => $html );
        }
    })->start;

    or

    > perl -Mojo -E 'a->plugin("Directory", root => "/path/to/htdocs")->start' daemon

# DESCRIPTION

[Mojolicious::Plugin::Directory](https://metacpan.org/pod/Mojolicious::Plugin::Directory) is a static file server directory index a la Apache's mod\_autoindex.

# METHODS

[Mojolicious::Plugin::Directory](https://metacpan.org/pod/Mojolicious::Plugin::Directory) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin).

# OPTIONS

[Mojolicious::Plugin::Directory](https://metacpan.org/pod/Mojolicious::Plugin::Directory) supports the following options.

## `root`

    # Mojolicious::Lite
    plugin Directory => { root => "/path/to/htdocs" };

Document root directory. Defaults to the current directory.

If root is a file, serve only root file.

## `auto_index`

    # Mojolicious::Lite
    plugin Directory => { auto_index => 0 };

Automatically generate index page for directory, default true.

## `dir_index`

    # Mojolicious::Lite
    plugin Directory => { dir_index => [qw/index.html index.htm/] };

Like a Apache's DirectoryIndex directive.

## `dir_page`

    # Mojolicious::Lite
    plugin Directory => { dir_page => $template_str };

a HTML template of index page

## `handler`

    # Mojolicious::Lite
    use Text::Markdown qw{ markdown };
    use Path::Class;
    use Encode qw{ decode_utf8 };
    plugin Directory => {
        handler => sub {
            my ($c, $path) = @_;
            if ($path =~ /\.(md|mkdn)$/) {
                my $text = file($path)->slurp;
                my $html = markdown( decode_utf8($text) );
                $c->render( inline => $html );
            }
        }
    };

CODEREF for handle a request file.

If not rendered in CODEREF, serve as static file.

## `json`

    # Mojolicious::Lite
    # /dir (Accept: application/json)
    # /dir?format=json
    plugin Directory => { json => 1 };

Enable json response.

# AUTHOR

hayajo <hayajo@cpan.org>

# CONTRIBUTORS

Many thanks to the contributors for their work.

- ChinaXing

# SEE ALSO

[Plack::App::Directory](https://metacpan.org/pod/Plack::App::Directory)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
