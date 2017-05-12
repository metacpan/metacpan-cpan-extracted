# NAME

Plack::Middleware::Scope::Container - per-request container 

# SYNOPSIS

    use Plack::Builder;
    

    builder {
        enable "Plack::Middleware::Scope::Container";
        $app
    };
    

    # in your application
    package MyApp;

    use Scope::Container;

    sub getdb {
        if ( my $dbh = scope_container('db') ) {
            return $dbh;
        } else {
            my $dbh = DBI->connect(...);
            scope_container('db', $dbh)
            return $dbh;
        }
    }

    sub app {
      my $env = shift;
      getdb(); # do connect
      getdb(); # from container
      getdb(); # from container
      return [ '200', [] ["OK"]];
      # disconnect from db at end of request
    }

# DESCRIPTION

Plack::Middleware::Scope::Container and [Scope::Container](http://search.cpan.org/perldoc?Scope::Container) work like mod\_perl's pnotes.
It gives a per-request container to your application.

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[Scope::Container](http://search.cpan.org/perldoc?Scope::Container), [Plack::Middleware::Scope::Session](http://search.cpan.org/perldoc?Plack::Middleware::Scope::Session)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
