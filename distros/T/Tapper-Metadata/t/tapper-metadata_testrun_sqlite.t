#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use FindBin '$Bin';

# create an empty file
require File::Temp;
my $or_fh   = File::Temp->new( EXLOCK => 0 );
my $s_fname = $or_fh->filename;

ok( $s_fname, "get temporary filename for sqlite db: $s_fname" );

# get database handle
require DBI;
my $or_dbh = DBI->connect("dbi:SQLite:dbname=$s_fname",q##,q##);

is( ref( $or_dbh ), 'DBI::db', "get database handle to sqlite database: $s_fname", );

# get database create files
my @a_database_files;
{
    no warnings 'once';

    require File::Find;
    File::Find::find(sub{
        if ( -f $File::Find::name ) {
            push @a_database_files, $File::Find::name;
        }
    },"$Bin/../sql/SQLite");
}

ok( @a_database_files, "get sql files for database creation form: $Bin" );

# execute sql files
eval {
    for my $s_sql_file ( sort @a_database_files ) {
        my $s_sql = do { local( @ARGV, $/ ) = $s_sql_file ; <> };
        for my $s_statement ( split /;\n+/, $s_sql ) {
            $or_dbh->do( $s_statement );
        }
    }
};
ok( !$@, 'execute database creation statements' );

require Tapper::Metadata::Testrun;
my $or_meta = Tapper::Metadata::Testrun->new({
    dbh    => $or_dbh,
    debug  => $ENV{TAPPER_METADATA_TEST_DEBUG},
});

is( ref( $or_meta ), 'Tapper::Metadata::Testrun', 'Tapper-Metadata-Object created' );

my $s_error = $or_meta->add_single_metadata({
    TESTRUN        => 1,
    machine_name   => '192.168.1.106',
    metadata_date  => '1970-09-25 12:00:00',
});

is( $s_error, undef, 'add a single metadatapoint' );

my @a_error = $or_meta->add_multi_metadata([
    {
        TESTRUN        => 1,
        machine_name   => '192.168.1.107',
        metadata_date  => '1970-09-25 12:00:03',
    },{
        TESTRUN        => 2,
        machine_name   => 'unknown',
        metadata_date  => '1970-09-25 12:00:18',
    },{
        TESTRUN        => 2,
        metadata_date  => '1970-09-25 12:00:33',
    },{
        TESTRUN        => 2,
        machine_name   => '192.168.1.108',
        metadata_date  => '1970-09-25 12:00:34',
    },
]);

is_deeply( \@a_error, [], 'add multiple metadatapoints' );

my ( $or_st, undef ) = $or_meta->search({
    select      => [
        'metadata_date',
        'machine_name',
    ],
    where       => [
        {
            operator    => '=',
            column      => 'TESTRUN',
            values      => 2,
        },
    ],
    limit       => 2,
    order_by    => [
        {
            column      => 'metadata_date',
            direction   => 'ASC',
            numeric     => 0,
        },
    ],
});

is( ref( $or_st )                       , 'DBI::st', 'search for metadata point: return value DBI Statement Handle'  , );
is( scalar(@{$or_st->fetchall_arrayref}), 2        , 'search for metadata point: number of found rows'               , );

my $ar_meta = $or_meta->search_array({
    select      => [
        'metadata_date',
        'machine_name',
    ],
    where       => [
        {
            operator    => '=',
            column      => 'TESTRUN',
            values      => 2,
        },
    ],
    limit       => 2,
    order_by    => [
        {
            column      => 'metadata_date',
            direction   => 'ASC',
            numeric     => 0,
        },
    ],
});

cmp_deeply(
    $ar_meta,
    [
        {
            machine_name   => 'unknown',
            metadata_date  => '1970-09-25 12:00:18',
        },{
            machine_name   => undef,
            metadata_date  => '1970-09-25 12:00:33',
        }
    ],
    'search for benchmark values: return of array reference',
);

my $hr_meta = $or_meta->search_hash({
    keys        => [
        'TESTRUN',
        'metadata_date',
    ],
    select      => [
        'metadata_date',
        'machine_name',
    ],
    where       => [
        {
            operator    => '=',
            column      => 'TESTRUN',
            values      => 2,
        },
    ],
    order_by    => [
        {
            column      => 'metadata_date',
            direction   => 'ASC',
            numeric     => 0,
        },
    ],
});

cmp_deeply(
    $hr_meta,
    {
        2 => {
            '1970-09-25 12:00:18' => {
                machine_name   => 'unknown',
                TESTRUN        => 2,
                metadata_date  => '1970-09-25 12:00:18',
            },
            '1970-09-25 12:00:33' => {
                machine_name   => undef,
                TESTRUN        => 2,
                metadata_date  => '1970-09-25 12:00:33',
            },
            '1970-09-25 12:00:34' => {
                machine_name   => '192.168.1.108',
                TESTRUN        => 2,
                metadata_date  => '1970-09-25 12:00:34',
            }
        },
    },
    'search for metadata points: return of hash reference',
);

done_testing();