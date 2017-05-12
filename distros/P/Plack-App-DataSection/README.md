# NAME

Plack::App::DataSection - psgi application for serving contents in data section

# SYNOPSIS

    # create your module from directory.
    % dir2data_section.pl --dir=dir/ --module=Your::Module

    # generated module is like this.
    package Your::Module;
    use parent qw/Plack::App::DataSection/;
    __DATA__
    @@ index.html
    <html>
    ...

    # app.psgi
    use Your::Module;
    Your::Module->new->to_app;

    # you can get contents in data section
    % curl http://localhost:5000/index.thml

# DESCRIPTION

Plack::App::DataSection is psgi application for serving contents in data section.

Inherit this module and you can easily create psgi application for serving contents in data section.

You can even serve binary contents!



# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
