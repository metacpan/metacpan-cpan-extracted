[![Build Status](https://travis-ci.org/hitode909/Plack-Middleware-Bootstrap.svg?branch=master)](https://travis-ci.org/hitode909/Plack-Middleware-Bootstrap)
# NAME

Plack::Middleware::Bootstrap - A Plack Middleware to prettify simple HTML with Bootstrap design template

# SYNOPSIS

    use Plack::Builder;

    my $app = sub {
        return [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ "<head><title>Hello!</title></head><body><h1>Hello</h1>\n<p>World!</p></body>" ]
        ];
    };
    builder {
        enable "Bootstrap";
        $app;
    };

And you will get

    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
        <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
        <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
        <!--[if lt IE 9]>
          <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
          <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->
    <title>Hello!</title>
      </head>
      <body>
        <div class="container">
    <h1>Hello</h1>
    <p>World!</p>
        </div>
        <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
        <!-- Include all compiled plugins (below), or include individual files as needed -->
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/js/bootstrap.min.js"></script>
      </body>
    </html>

# DESCRIPTION

Plack::Middleware::Bootstrap pretifies HTML with Bootstrap design template.

Plack::Middleware::Bootstrap provides better design to simple HTML.

For example, You can generate simple HTML document with some tool, and prettify with Plack::Middleware::Bootstrap.

# SEE ALSO

- [http://getbootstrap.com/](http://getbootstrap.com/)
- [Plack::Middleware](https://metacpan.org/pod/Plack::Middleware)
- [Plack::Builder](https://metacpan.org/pod/Plack::Builder)

# LICENSE

Copyright (C) hitode909.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hitode909 <hitode909@gmail.com>
