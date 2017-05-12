# NAME

Plack::Middleware::GitStatus - Provide Git status via HTTP

# SYNOPSIS

    use Plack::Builder;

    builder {

        enable "Plack::Middleware::GitStatus", (
            path  => '/git-status', git_dir => '/path/to/repository'
        ) if $ENV{PLACK_ENV} eq 'staging';

        $app;
    };

    % curl http://server:port/git-status
    CurrentBranch: feature/something-interesting
    Commit: a7c24106ac453c10f1a460f52e95767803076dde
    Author: y_uuki
    Date: Tue Feb 12 06:06:41 2013
    Message: Hello World

# DESCRIPTION

Plack::Middleware::GitStatus provides Git status such as current branch and last commit via HTTP.
On a remote server such as staging environment, it is sometimes troublesome to check a current branch and last commit information of a working web application.
Plack::Middleware::GitStatus add URI location displaying the information to your Plack application.

# CONFIGURATIONS

- path

        path => '/git-status',

    location that displays git status

- git\_dir

        git_dir => '/path/to/repository'

    git direcotry path like '/path/to/deploy\_dir/current'

# AUTHOR

Yuuki Tsubouchi <yuuki {at} cpan.org>

# SEE ALSO

[Plack::Middleware::ServerStatus::Lite](http://search.cpan.org/perldoc?Plack::Middleware::ServerStatus::Lite)

[Plack::Middleware::GitBlame](https://github.com/shumphrey/Plack-Middleware-GitBlame)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
