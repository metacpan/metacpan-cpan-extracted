# StoredHash - Load and Persist Perl hashes in a easy way.

## Features

- Load an entry as a (Perl) hash from a database
- Store New Hash (insert) to a database
- Store updated Hash (update) to a database
- Load collection / set of entries

The usage is currently mainly limited to relational database (Perl DBI) scope,
but some thought was put into design to keep doors open to other
persistent storage backends (LDAP, ARS, DBM, Storable ...).
There are now experimental backends for ARS and LDAP as well.

# Prerequisites

- Perl DBI / Database interface (search CPAN for DBI)
- DBD::* driver(s) for the database(s) you plan to use with Perl DBI

For easy ramp-up you can use serverless SQLite (search CPAN for DBD::SQLite).
In Ubuntu you'd do Perl DBD::SQLite installation the easy way:

   apt-get install libdbd-sqlite3-perl

ActiveState Perl distributions (at least > 5.8.8) ship with both
Perl DBI and DBD::SQLite (just in case you use the reputable ActiveState Perl).

# Installation

Installation is based on the standard CPAN Module install flow with following steps (after download of package):

  tar zxvf StoredHash-NN.tar.gz
  cd  StoredHash-NN
  perl Makefile.PL
  make
  make test
  make install

Please skim through "Prerequisites" section to see if you are missing anything.
Also note that modules, that some of the optional or advanced parts of StoredHash is using are not marked as "hard" dependencies (although the optional/advanced parts depend on these). Also for these optional/advanced modules do "lazy loading" of dependies in runtime to keep testing and installation easy. If you did not underrstand some of the above, do not worry but read on.

To learn more about the use of module API methods, do (after installation):

  perldoc StoredHash

# Windows Installation Notes

On Windows you should get "make" going by:
- downloading Microsoft nmake.exe (substitute make  => nmake above)
- using Cygwin or Mingw make

Unpackaging tar.gz on Win can be done by
- WinZip, 7-zip
- Cygwin (GNU) tar

## Author

Olli Hollmen - olli.hollmen@gmail.com

## License

Perl License

## Missing / TODO

- The module is currently not very tolerant of "Spaces in fieldname", i.e.
it does no quoting on those cases.
- Field quoting might also be nice for protecting against fieldnames that happen to be DB backend reserved names (function names, other keywords). However most
developers have already been protecting themselves against these.

- Actual Testing on various database backends has been limited.
The databases that have had the most testing and production use are: MySQL,SQLite,MSSQL. Please contribute feedback on your experiences with various DB backends.

- The initial implementation of pulling (numeric) ID from a table-associated
sequence (i.e. Oracle and postgres style) has not been properly tested
(some of it has been mocked up in code).
Luckily the sequence feature has not been "published" to be available (neither documented). If you happen to have use for sequence based ID allocation, let me know.

- Have more examples in pod (possibly distribute large SYNOPSIS section or StoredHash::Tutorial to demonstrate examples).

