package t::lib::FakeMongoDB;

use strict;
use warnings;
use boolean ();
use Test::MockObject;

my $server = {
    'ok'        => 1,
    'version'   => '2.2.0',
    'uptime'    => 1738371,
    'process'   => 'mongod',
    'network'   => {
        'bytesIn'       => 43218,
        'bytesOut'      => 9235789924,
        'numRequests'   => 548
    },
    'mem'       => {
        'bits'              => 64,
        'mapped'            => 1056,
        'mappedWithJournal' => 2112,
        'note'              => 'not all mem info support on this platform',
        'supported'         => boolean::false
    },
    'writeBacksQueued'  => boolean::true,
};

my $database = {
    'db' => {
        'avgObjSize'        => 643.318918918919,
        'collections'       => 8,
        'flags'             => 1,
        'dataSize'          => 476056,
        'db'                => 'sampledb',
        'fileSize'          => 201326592,
        'indexSize'         => 81760,
        'indexes'           => 6,
        'nsSizeMB'          => 16,
        'numExtents'        => 11,
        'objects'           => 740,
        'ok'                => 1,
        'storageSize'       => 585728,
    },
    'models' => {
        'avgObjSize'        => 1459.75,
        'count'             => 16,
        'flags'             => 1,
        'indexSizes'        => {
            '_id_'  => 8176,
        },
        'lastExtentSize'    => 24576,
        'nindexes'          => 1,
        'ns'                => 'sampledb.models',
        'numExtents'        => 1,
        'ok'                => 1,
        'paddingFactor'     => 1,
        'size'              => 23356,
        'storageSize'       => 24576,
        'totalIndexSize'    => 8176,
    },
    'sessions' => {
        'avgObjSize'        => 1074.67768595041,
        'count'             => 363,
        'flags'             => 1,
        'indexSizes'        => {
            '_id_'  => 24528,
        },
        'lastExtentSize'    => 327680,
        'nindexes'          => 1,
        'ns'                => 'sampledb.sessions',
        'numExtents'        => 3,
        'ok'                => 1,
        'paddingFactor'     => 1,
        'size'              => 390108,
        'storageSize'       => 430080,
        'totalIndexSize'    => 24528,
    }
};

# Faked items: mongo, client, database, cursor, collection
my ($mdb, $cli, $dbh, $cur, $col);

sub run {
    unless (defined $cli) {
        ($mdb, $cli, $dbh, $cur, $col) = map { Test::MockObject->new } 1..5;

        Test::MockObject->fake_module('MongoDB',              new => sub { $mdb });
        Test::MockObject->fake_module('MongoDB::MongoClient', new => sub { $cli });
        Test::MockObject->fake_module('MongoDB::Database',    new => sub { $dbh });
        Test::MockObject->fake_module('MongoDB::Cursor',      new => sub { $cur });
        Test::MockObject->fake_module('MongoDB::Collection',  new => sub { $col });

        $mdb->mock('VERSION'            => sub { '0.502' });
        $cli->mock('get_database'       => sub { $dbh });
        $dbh->mock('collection_names'   => sub { (qw(models sessions)) });
        $dbh->mock('run_command'  => sub {
            my ($self, $args) = @_;
            exists $args->{dbStats}
                ? $database->{db}
                : (exists $args->{collStats} && exists $database->{$args->{collStats}})
                    ? $database->{$args->{collStats}}
                    : exists $args->{serverStatus}
                        ? $server
                        : {};
        });
    }
    $cli;
}

1; # End of t::lib::FakeMongoDB
