# Pg::BulkLoad

Load Comma and Tab Delimited files into Postgres, skipping bad records.

# Synopsis

    Shell> split -l 50000 -a 3 -d mydata.csv load
    Shell> myloadscript.pl load*

    === myloadscript.pl ===

    use Pg::BulkCopy;

    my %args = (
           dbname => 'pgbulkcopy',
           dbhost => 'localhost',
           dbuser => 'postgres',
           dbpass => 'postgres',
           errorfile => '/tmp/pgbulk.error',
           errorlimit => 500,
           );

    my $pgc = Pg::BulkLoad->new(  %args );

    .... # your code to read file names and possibly manipulate files contents prior to load.

    while ( @filelist ) {
        $pgc->load( $file, $_, 'csv' );
    }

## load ($file, $table, $format )

Attempts to load your data. Takes 3 parameters: 

- $file

    the file you're trying to load.

- $table

    the table to load to.

- $format

    either text or csv

## Reason

The Postgres 'COPY FROM' lacks a mechanism for skipping bad records. Sometimes we need to ingest 'dirty' data and make the best of it.

## Method and Performance

Pg::BulkLoad attempts to load your file via the COPY FROM command if it fails it removes the error for the bad line from its working copy, then attempts to load all of the records previous to the error, and then tries to load the remaining data after the failure. 

If your data is clean the COPY FROM command is pretty fast, however if there are a lot of bad records, for each failure Pg::BuklLoad has to rewrite the input file. If your data has a lot of bad records small batches are recommended, for clean data performance will be better with a larger batch size. The split program will quickly split larger files, but you can split them in Perl if you prefer. To keep this program simpler I've left chunking larger files up to the user. Pg::BulkLoad does load data into memory which will create a practical maximum file.

## Limitation of COPY

Since Pg::Bulkload passes all of the work to copy it is subject to the limitation that the source file must be readable via the file system to the postgres server (usually the postgres user). To avoid permissions problems Pg::Bulkload copies the file to /tmp for loading (leaving the original preserved if it has to evict records). Pg::BulkLoad needs to be run locally to the server, this means that your host for connection will almost always be localhost.

## Other Considerations

The internal error counting is for the life of an instance not per data file. If you have 100 source files an error limit of 500 and there are 1000 errors in your source you will likely get about half the data loaded before this module quits. You should be prepared to deal with the consequences of a partial load.

## History

My first CPAN module was Pg::BulkCopy, because I had this problem. I found something better that was written in C, so I deprecated my original module which needed a rewrite. Sometimes the utility I switched to doesn't want to compile, so I got tired of that, still had my original problem of getting a lot of data from an external source that has a certain amount of errors, and is creative in finding new ways get bad records past my preprocessor. Pg::BulkCopy wanted to be an import/export utility, Pg::BulkLoad only deals with the core issue of getting the good data loaded.

# Testing

To properly test it you'll need to export DB\_TESTING to a true value in your environment before running tests. When this variable isn't set the tests mock a database for a few of the simpler tests and skip the rest.
