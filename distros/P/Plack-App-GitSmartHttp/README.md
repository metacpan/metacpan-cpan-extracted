[![Build Status](https://travis-ci.org/dragon3/Plack-App-GitSmartHttp.svg?branch=master)](https://travis-ci.org/dragon3/Plack-App-GitSmartHttp) [![Coverage Status](https://img.shields.io/coveralls/dragon3/Plack-App-GitSmartHttp/master.svg)](https://coveralls.io/r/dragon3/Plack-App-GitSmartHttp?branch=master)
# NAME

    Plack::App::GitSmartHttp - Git Smart HTTP Server PSGI(Plack) Implementation

# SYNOPSIS

    use Plack::App::GitSmartHttp;

    Plack::App::GitSmartHttp->new(
        root          => '/var/git/repos',
        git_path      => '/usr/bin/git',
        upload_pack   => 1,
        received_pack => 1
    )->to_app;

# DESCRIPTION

    Plack::App::GitSmartHttp is Git Smart HTTP Server PSGI(Plack) Implementation.

# AUTHOR

    Ryuzo Yamamoto E<lt>ryuzo.yamamoto@gmail.comE<gt>

# SEE ALSO

    Smart HTTP Transport : <http://progit.org/2010/03/04/smart-http.html>
    Grack : <https://github.com/schacon/grack>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
