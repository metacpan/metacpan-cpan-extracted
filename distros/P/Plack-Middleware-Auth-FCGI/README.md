Plack::Middleware::Auth::FCGI
=============================

Authentication middleware that query remote FastCGI server

## SYNOPSIS

    use Plack::Builder;

    my $app   = sub {
      my $env = shift;
      # FastCGI auth response headers are stored in $env->{fcgiauth-<header>}
      # in lower case. Example if FastCGI auth server populates 'Auth-User' header:
      my $user = $env->{fcgiauth-auth-user};
      #...
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello $user" ] ];
    };
    
    # Optionally ($fcgiResponse is the PSGI response of remote FCGI auth server)
    #sub on_reject {
    #    my($self,$env,$fcgiResponse) = @_;
    #    my $statusCode = $fcgiResponse->{status};
    #    ...
    #}
    
    builder
    {
      enable "Auth::FCGI",
        host => '127.0.0.1',
        port => '9090',
        # Optional parameters to give to remote FCGI server
        #fcgi_auth_params => {
        #  RULES_URL => 'https://my-server/my.json',
        #},
        # Optional rejection subroutine
        #on_reject => \&on_reject;
        ;
      $app;
    };

## DESCRIPTION

Plack::Middleware::Auth::FCGI permits to protect an application by querying
a remote FastCGI server _(like Nginx auth\_request)_.

It can be used with [Lemonldap::NG](https://lemonldap-ng.org) in a
[SSO-as-a-Service (SSOaaS)](https://lemonldap-ng.org/documentation/2.0/ssoaas)
system.

## INSTALLATION

As usual for Perl packages:

    perl Makefile.PL
    make
    make test
    sudo make install

### Dependencies

* [FCGI::Client](https://metacpan.org/pod/FCGI::Client)

## SEE ALSO

* [Lemonldap::NG](https://lemonldap-ng.org)
* [SSO-as-a-Service (SSOaaS)](https://lemonldap-ng.org/documentation/2.0/ssoaas)

## AUTHOR

[Xavier Guimard](mailto:x.guimard@free.fr)

# COPYRIGHT AND LICENSE

Copyright (C) 2018 by Xavier Guimard &lt;x.guimard@free.fr&gt;

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.2 or,
at your option, any later version of Perl 5 you may have available.
