# NAME mysqlhi

Easy way to connect to MySQL/MariaDB via command line.

# Installation

    $ perl Makefile.PL
    $ make
    $ sudo make install
    $ make clean

# Debian

It may be better to install debian packages before installing
`MySQL::HI` and `mysqlhi` script:

     root@[boxname]:~# apt install libconfig-simple-perl \
      libfile-homedir-perl \
      libtest-warn-perl \
      libtest-deep-perl \
      cpanminus
      
     root@[boxname]:~# cpanm MySQL::Hi

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
