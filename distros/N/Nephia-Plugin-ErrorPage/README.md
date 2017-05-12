# NAME

Nephia::Plugin::ErrorPage - Error Page DSL for Nephia

# SYNOPSIS

    package MyApp;
    use Nephia plugins => [
        'ErrorPage',
        'View::MicroTemplate' => {...},
    ];
    

    app {
        return res_404() unless param('id');
        ...;
    };



# DESCRIPTION

Nephia::Plugin::ErrorPage provides error page response DSLs.

# CONFIGURE

In this plugin, default design for error page is so cheapy.

You can customize it with config.

For example. Look at following.

    use Plack::Builder;
    use MyApp;
    

    my $app = MyApp->run(
        ErrorPage => {
            template => 'error.html',
        },
    );
    

    builder {
        ...
        $app;
    };



# DSL

## res\_error($code, $message)

Returns [Nephia::Response](http://search.cpan.org/perldoc?Nephia::Response) object that contains specified response-code and response-message.

You may omission response-message.

    app {
        res_error(403);
    };
    # or 
    app {
        res_error(403, 'some error message');
    };

## res\_404()

Returns [Nephia::Response](http://search.cpan.org/perldoc?Nephia::Response) object that is 404 response.

    app {
        res_404();
    };

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
