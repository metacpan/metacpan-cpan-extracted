# NAME

Mojolicious::Plugin::WriteExcel - write Excel spreadsheets from Mojolicious

# SYNOPSIS

    # Mojolicious
    $self->plugin('write_excel');

    # Mojolicious::Lite
    plugin 'write_excel';

    # Render a spreadsheet
    get '/example.xls' => sub {
      shift->render(
        handler => 'xls',
        result  => [[qw(foo bar baz)], [qw(lol wut bbq)], [qw(kick ass module)],],
      );
    };

# DESCRIPTION

[Mojolicious::Plugin::WriteExcel](https://metacpan.org/pod/Mojolicious::Plugin::WriteExcel) is a plugin for writing Excel
spreadsheets.

This plugin converts the `result` element in the stash to an Excel
spreadsheet.  If the stash also has a `heading` element, the renderer
will also write headings in bold type for the columns in the
spreadsheet.

`heading` is an arrayref, while `result` is an array of arrayrefs.

Optionally, a `settings` parameter can be provided to set additional
attributes in the Excel spreadsheet.  Currently 'column\_width' is the
only working attribute.  `settings` is a hashref.  Column widths
could be set by passing the settings to `render`:

    get '/colwidth.xls' => sub {
      shift->render(
        handler  => 'xls',
        result   => [['small'], ['medium'], ['large']],
        settings => {column_width => {'A:A' => 10, 'B:B' => 25, 'C:D' => 40}},
      );
    };
    settings => {column_width => {'A:A' => 10, 'B:B' => 25, 'C:D' => 40}}

# METHODS

[Mojolicious::Plugin::WriteExcel](https://metacpan.org/pod/Mojolicious::Plugin::WriteExcel) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## `xls_renderer`

    $app->renderer->add_handler(xls => \&xls_renderer);

Internal sub talking to [Spreadsheet::WriteExcel::Simple](https://metacpan.org/pod/Spreadsheet::WriteExcel::Simple) to render
spreadsheets.

## `register`

    $plugin->register;

Register renderer in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# AUTHOR

Zak B. Elep <zakame@cpan.org>

# ACKNOWLEDGEMENTS

Thanks to Graham Barr and his [MojoX::Renderer::YAML](https://metacpan.org/pod/MojoX::Renderer::YAML) module, and
Sebastian Riedel's core [Mojolicious::Plugin::EpRenderer](https://metacpan.org/pod/Mojolicious::Plugin::EpRenderer) for showing
how to write renderers for [Mojolicious](https://metacpan.org/pod/Mojolicious)!

Inspiration for this renderer came from this mailing list thread:
[http://www.mail-archive.com/plug@lists.linux.org.ph/msg21881.html](http://www.mail-archive.com/plug@lists.linux.org.ph/msg21881.html)

# LICENSE

Copyright 2013 Zak B. Elep

This library is free software; yu can redistribute it and/or modify it
under the same terms as Perl itself.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Spreadsheet::WriteExcel::Simple](https://metacpan.org/pod/Spreadsheet::WriteExcel::Simple), [http://mojolicious.org](http://mojolicious.org).
