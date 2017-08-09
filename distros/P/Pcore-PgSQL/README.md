# NAME

Pcore::PgSQL

# SYNOPSIS

# DESCRIPTION

    docker create --name pgsql -v pgsql:/var/local/pcore-pgsql/data/ -v /var/run/postgresql/:/var/run/postgresql/ -p 5432:5432/tcp softvisio/pcore-pgsql

    # how to connect with standard client:
    psql -U postgres
    psql -h /var/run/postgresql -U postgres

    # connect via TCP
    my $dbh = P->handle('pgsql://username:password@host:port?db=dbname');

    # connect via unix socket
    my $dbh = P->handle('pgsql://username:password@/var/run/postgresql?db=dbname');

# SEE ALSO

# AUTHOR

zdm <zdm@cpan.org>

# CONTRIBUTORS

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.
