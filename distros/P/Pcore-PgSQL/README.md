# NAME

Pcore::PgSQL

# SYNOPSIS

# DESCRIPTION

    docker create --name pgsql -v pgsql:/var/local/pcore-pgsql/data/ -v /tmp/pgsql.sock/:/tmp/pgsql.sock/ -p 5432:5432/tcp softvisio/pcore-pgsql

    # how to connect with standard client:
    psql -U postgres
    psql -h /tmp/pgsql.sock -U postgres

    # connect via TCP
    my $dbh = P->handle('pgsql://username:password@host:port?db=dbname');

    # connect via unix socket
    my $dbh = P->handle('pgsql://username:password@/tmp/pgsql.sock?db=dbname');

# SEE ALSO

# AUTHOR

zdm <zdm@cpan.org>

# CONTRIBUTORS

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.
