# NAME

Pcore::Redis

# SYNOPSIS

    docker create --name redis -v redis:/var/local/pcore-redis/data/ -p 6379:6379/tcp softvisio/pcore-redis

    docker create --name redis -v redis:/var/local/pcore-redis/data/ -v /tmp/redis.sock/:/tmp/redis.sock/ -p 6379:6379/tcp softvisio/pcore-redis

    # connect via TCP
    my $h = P->handle('redis://password@host:port?db=dbindex');

    # connect via unix socket
    my $h = P->handle('redis://password@/tmp/redis.sock/redis-6379.sock?db=dbindex');

# DESCRIPTION

# SEE ALSO

# AUTHOR

zdm <zdm@cpan.org>

# CONTRIBUTORS

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.
