# NAME

Plack::Middleware::Debug::GitStatus - Display git status information about the directory from which you run your development server

# SYNOPSIS

    # Assuming your current directory is the relevant git dir:
    builder {
        enable 'Debug', panels => [ qw( Environment Response GitStatus ) ];
        $app;
    };

    # If you need to set a git dir:
    return builder {
        enable 'Debug', panels => [ qw( Environment Response ) ];
        enable 'Debug::GitStatus', git_dir => '/some/path';
        $app;
    };

    # or if you want to specify a url to gitweb/gitalist/etc:
    return builder {
        enable 'Debug', panels => [ qw( Environment Response ) ];
        enable 'Debug::GitStatus', gitweb_url => 'http://example.com/cgi-bin/gitweb?p=my_repo.git;h=%s';
        $app;
    };
    

# DESCRIPTION

This panel gives you quick access to the most relevant git information:

- the currently checked out branch
- git status information
- information about the most recent commit

# CONFIGURATION

There are two optional parameters you can use to configure this panel plugin:

- git\_dir

    The path to your repository in case the current dir of your application is
    outside of this.

- gitweb\_url

    If you want the panel to give you a link to your gitweb, gitolite, etc installation,
    provide the URL here. You need to provide a string that will be used as a format
    string in a call to sprintf, thus the string needs to contain a %s which will be
    supplied with the sha-1 of the most recent commit.

    Example: 'http://localhost/somegitwebtool?hash=%s'

# SEE ALSO

[https://metacpan.org/pod/Plack::Middleware::GitStatus](https://metacpan.org/pod/Plack::Middleware::GitStatus) - Gives you the option to
send a HTTP request to your server that will be answered with git status information.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
[https://github.com/mannih/Plack-Middleware-Debug-GitStatus](https://github.com/mannih/Plack-Middleware-Debug-GitStatus).

# AUTHOR

Manni Heumann, `<cpan@lxxi.org>`

# COPYRIGHT AND LICENSE

Copyright 2014 by Manni Heumann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
