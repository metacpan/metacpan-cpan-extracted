# NAME

Sub::Retry - retry $n times

# SYNOPSIS

    use Sub::Retry;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    my $res = retry 3, 1, sub {
        my $n = shift;
        $ua->post('http://example.com/api/foo/bar');
    };

# DESCRIPTION

Sub::Retry provides the function named 'retry'.

# FUNCTIONS

- retry($n\_times, $delay, \\&code \[, \\&retry\_if\])

    This function calls `\&code`. If the code throws exception, this function retry `$n_times` after `$delay` seconds.

    Return value of this function is the return value of `\&code`. This function cares [wantarray](http://search.cpan.org/perldoc?wantarray).

    You can also customize the retry condition. In that case `\&retry_if` specify CodeRef. The CodeRef arguments is return value the same. (Default: retry condition is throws exception)

        use Sub::Retry;
        use Cache::Memcached::Fast;

        my $cache = Cache::Memcached::Fast->new(...);
        my $res = retry 3, 1, sub {
            $cache->get('foo');
        }, sub {
            my $res = shift;
            defined $res ? 0 : 1;
        };

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF GMAIL COM>

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
