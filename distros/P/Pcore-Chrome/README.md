# NAME

Pcore::Chrome

# SYNOPSIS

    use Pcore::Chrome;

    my $chrome = Pcore::Chrome->new(
        host      => '127.0.0.1',     # chrome --remote-debugging-address
        port      => 9222,            # chrome --remote-debugging-port
        bin       => undef,           # chrome binary path
        timeout   => 3,               # chrome startup timeout
        headless  => 1,               # run chrome in headless mode
        useragent => undef,           # redefine User-Agent
    );

# DESCRIPTION

# ATTRIBUTES

# METHODS

# SEE ALSO

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by zdm.
