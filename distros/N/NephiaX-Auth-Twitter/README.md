# NAME

NephiaX::Auth::Twitter - Twitter Authorizer

# DESCRIPTION

An web application that powered by Nephia.

# SYNOPSIS

    use Plack::Builder;
    use NephiaX::Auth::Twitter;
    builder {
        mount '/auth' => NephiaX::Auth::Twitter->run(
            consumer_key    => 'your consumer key',
            consumer_secret => 'your consumer secret',
            handler => sub {
                my ($c, $twitter_id) = @_;
                ### You have to imprement logic that stores twitter_id into your db and/or cookie.
                [302, [Location => '/userarea/somepage'], []];
            },
        );
        mount '/' => Your::App->run;
    };

# AUTHOR

ytnobody <ytnobody@gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Nephia](http://search.cpan.org/perldoc?Nephia)
