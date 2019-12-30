# NAME mysqlhi

Easy way to connect to MySQL/MariaDB via command line.

# Installation

    $ perl Makefile.PL
    $ make
    $ sudo make install
    $ make clean

# Usage

- 1. Create a config file

    Create a file in your home directory named `$HOME/mysqlhi.conf`:

        [dbname]
        host=hostname
        password=y0Urp@s$
        port=3306

- 2. From command line

        $ mysqlhi dbname

- 3. From your Perl code

        use MySQL::Hi;
        use DBI;

        my $hi = MySQL::Hi->new();
        my $dbh = DBI->connect( $hi->get_dsn( 'dbname' ), \%attr);
