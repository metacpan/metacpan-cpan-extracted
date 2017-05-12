[![Build Status](https://travis-ci.org/kazeburo/Plack-App-PHPCGI.svg?branch=master)](https://travis-ci.org/kazeburo/Plack-App-PHPCGI)
# NAME

Plack::App::PHPCGI - execute PHP script as CGI

# SYNOPSIS

    use Plack::App::PHPCGI;

    my $app = Plack::App::PHPCGI->new(
        script => '/path/to/test.php'
    );

# DESCRIPTION

Plack::App::WrapCGI supports CGI scripts written in other languages. but WrapCGI cannot execute 
PHP script that does not have shebang line and exec bits.
Plack::App::PHPCGI execute any PHP scripts as CGI with php-cgi command.

# METHODS

- new

        my $app = Plack::App::PHPCGI->new(%args);

    Creates a new PSGI application using the given script. _%args_ has two
    parameters:

    - script

        The path to a PHP program. This is a required parameter.

    - php\_cgi

        An optional parameter. path for php-cgi command

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[Plack::App::WrapCGI](https://metacpan.org/pod/Plack::App::WrapCGI)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
