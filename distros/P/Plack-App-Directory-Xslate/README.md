# NAME

    Plack::App::Directory::Xslate - Serve static files and Text::Xslate template files from document root with directory index

# SYNOPSIS

     # app.psgi
     use Plack::App::Directory::Xslate;
     my $app = Plack::App::Directory::Xslate->new({
       root => "/path/to/htdocs",
       xslate_opt  => +{ # Text::Xslate->new()
           syntax => 'TTerse',
       },
       xslate_param => +{
           hoge => 'fuga',
       },
       xslate_path => qr{\.tt$},
    })->to_app;

# DESCRIPTION

    This is a static files and Text::Xslate template files server PSGI application with directory index a la Apache's mod_autoindex.

# CONFIGURATION

- root

        Document root directory. Defaults to the current directory.
- xslate\_opt

        Text::Xslate constructor option.
- xslate\_path : Regexp or CodeRef

        Allow Text::Xslate rendering path.
- xslate\_param : HashRef

        Text::Xslate rendering variables.

# AUTHOR

    Kenta Sato E<lt>karupa@cpan.orgE<gt>

# SEE ALSO

[Plack::App::Directory](http://search.cpan.org/perldoc?Plack::App::Directory)
[Plack::App::File](http://search.cpan.org/perldoc?Plack::App::File)
[Plack::App::Xslate](http://search.cpan.org/perldoc?Plack::App::Xslate)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
