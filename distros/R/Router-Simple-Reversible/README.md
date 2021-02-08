# NAME

Router::Simple::Reversible - Router::Simple equipped with reverse routing

# SYNOPSIS

    use Router::Simple::Reversible;

    my $router = Router::Simple::Reversible->new;

    # Same as Router::Simple
    $router->connect('/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'});

    $router->path_for({ controller => 'Blog', action => 'monthly' }, { year => 2015, month => 10 });
    # => '/blog/2015/10'

# DESCRIPTION

Router::Simple::Reversible inherits [Router::Simple](https://metacpan.org/pod/Router%3A%3ASimple)
and provides `path_for` method which produces a string from
routing destination and path parameters given.

# LICENSE

Copyright (C) motemen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

motemen <motemen@gmail.com>
