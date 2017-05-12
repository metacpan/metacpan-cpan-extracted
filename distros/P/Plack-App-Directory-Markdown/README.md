# NAME

Plack::App::Directory::Markdown - Serve translated HTML from markdown files from document root with directory index

# SYNOPSIS

    # app.psgi
    use Plack::App::Directory::Markdown;
    my $app = Plack::App::Directory::Markdown->new->to_app;

    # app.psgi(with options)
    use Plack::App::Directory::Markdown;
    my $app = Plack::App::Directory::Markdown->new({
      root           => '/path/to/markdown_files',
      title          => 'page title',
      tx_path        => '/path/to/xslate_templates',
      markdown_class => 'Text::Markdown',
    })->to_app;

# DESCRIPTION

This is a PSGI application for documentation with markdown.

# CONFIGURATION

- root

    Document root directory. Defaults to the current directory.

- title

    Page title. Defaults to 'Markdown'.

- tx\_path

    Text::Xslate's template directory. You can override default template with 'index.tx' and 'md.tx'.

- markdown\_class

    Specify Markdown module. 'Text::Markdown' as default.
    The module should have 'markdown' sub routine exportable.

- callback

    Code reference for filtering HTML.

        my $app = Plack::App::Directory::Markdown->new({
          root     => '/path/to/markdown_files',
          callback => sub {
              my ($content_ref, $env, $dir) = @_;

              ${$content_ref} =~ s!foo!bar!g;
          },
        })->to_app;

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
