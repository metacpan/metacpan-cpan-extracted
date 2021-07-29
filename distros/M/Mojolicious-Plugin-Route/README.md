# NAME

Mojolicious::Plugin::Route - Plugin to loader files of routes.

# SYNOPSIS

    package MyApp::Route::Bar;
    use Mojo::Base 'MojoX::Route';

    sub under {
        my ($self, $r) = @_;

        $r->under('/bar');
    }

    1;

    package MyApp::Route::Bar::Foo;
    use Mojo::Base 'MojoX::Route';

    sub route {
        my ($self, $bar) = @_;

        $bar->get('/foo'); # GET /bar/foo
    }

    1;


# DESCRIPTION

Mojolicious::Plugin::Route - Allows you to create routes through files that will be automatically loaded.

# METHODS

## route

    package MyApp::Route::Foo;
    use Mojo::Base 'MojoX::Route';

    sub route {
        my ($self, $r) = @_;

        # will create route /foo
        $r->get('/foo' => sub ($c) {...});
    }

    1;

Method route only creates routes, but the reference not is saved.

## any

    package MyApp::Route::Baz;
    use Mojo::Base 'MojoX::Route';

    sub any {
        my ($self, $r) = @_;

        $r->any('/baz' => sub ($c) {...});
    }

    1;

    package MyApp::Route::Baz::Child;
    use Mojo::Base 'MojoX::Route';

    sub route {
        # receive reference of parent that is MyApp::Route::Baz
        my ($self, $baz) = @_;

        # will create route /baz/child
        $baz->get('/child' => sub ($c) {...});
    }

    1;

Reference of the method any will be saved to be used in the files with the same namespace, not to be saved you need return undef.

## under

    package MyApp::Route::Bar;
    use Mojo::Base 'MojoX::Route';

    sub under {
        my ($self, $r) = @_;

        $r->under('/bar' => sub ($c) {...});
    }

    1;

    package MyApp::Route::Bar::Child;
    use Mojo::Base 'MojoX::Route';

    sub route {
        # receive reference of parent that is MyApp::Route::Bar
        my ($self, $bar) = @_;

        # will create route /bar/child
        $bar->get('/child' => sub ($c) {...});
    }

    1;

Similar to method any, the reference of the method under will be saved to be used in the files with the same namespace, not to be saved you need return undef.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Routes::Route](https://metacpan.org/pod/Mojolicious::Routes::Route),
[Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), (https://mojolicio.us).

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
