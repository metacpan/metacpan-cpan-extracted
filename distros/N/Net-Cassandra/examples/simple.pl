#!/home/acme/perl-5.10.0/bin//perl
use strict;
use warnings;
use lib 'lib';
use Net::Cassandra;
use Perl6::Say;

my $cassandra = Net::Cassandra->new( hostname => 'localhost' );
my $client = $cassandra->client;

my $key1      = '123';
my $key2      = '456';
my $timestamp = time;

#  void insert(1:required string keyspace,
#              2:required string key,
#              3:required ColumnPath column_path,
#              4:required binary value,
#              5:required i64 timestamp,
#              6:required ConsistencyLevel consistency_level=0)
#       throws (1: InvalidRequestException ire, 2: UnavailableException ue),
eval {
    $client->insert(
        'Keyspace1',
        $key1,
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        'Leon Brocard',
        $timestamp,
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
};
die $@->why if $@;

eval {
    $client->insert(
        'Keyspace1',
        $key1,
        Net::Cassandra::Backend::ColumnPath->new(
            {   column_family => 'Super1',
                super_column  => 'Fred',
                column        => 'name'
            }
        ),
        'Leon Brocard',
        $timestamp,
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
};
die $@->why if $@;

#  void batch_insert(1:required string keyspace,
#                    2:required string key,
#                    3:required map<string, list<ColumnOrSuperColumn>> cfmap,
#                    4:required ConsistencyLevel consistency_level=0)
#       throws (1: InvalidRequestException ire, 2: UnavailableException ue),
eval {
    $client->batch_insert(
        'Keyspace1',
        $key2,
        {   'Standard1' => [
                Net::Cassandra::Backend::ColumnOrSuperColumn->new(
                    {   column => Net::Cassandra::Backend::Column->new(
                            {   name      => 'name',
                                value     => 'Leon Brocard',
                                timestamp => $timestamp,
                            }
                        )
                    }
                )
            ],
        },
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
};
die $@->why if $@;

eval {
    $client->batch_insert(
        'Keyspace1',
        $key2,
        {   'Super1' => [
                Net::Cassandra::Backend::ColumnOrSuperColumn->new(
                    {   super_column =>
                            Net::Cassandra::Backend::SuperColumn->new(
                            {   name    => 'Fred',
                                columns => [
                                    Net::Cassandra::Backend::Column->new(
                                        {   name      => 'name',
                                            value     => 'Leon Brocard',
                                            timestamp => $timestamp,
                                        }
                                    )
                                ]
                            }
                            )
                    }
                )
            ],
        },
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
};
die $@->why if $@;

#  ColumnOrSuperColumn get(1:required string keyspace,
#                          2:required string key,
#                          3:required ColumnPath column_path,
#                          4:required ConsistencyLevel consistency_level=1)
#                      throws (1: InvalidRequestException ire, 2: NotFoundException nfe, 3: UnavailableException ue),
eval {
    my $what = $client->get(
        'Keyspace1',
        $key1,
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    my $value     = $what->column->value;
    my $timestamp = $what->column->timestamp;
    warn "$key1 / $value / $timestamp";
};
die $@->why if $@;

eval {
    my $what = $client->get(
        'Keyspace1',
        $key2,
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    my $value     = $what->column->value;
    my $timestamp = $what->column->timestamp;
    warn "$key2 / $value / $timestamp";
};
die $@->why if $@;

eval {
    my $what = $client->get(
        'Keyspace1',
        $key1,
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Super1', super_column => 'Fred', column => 'name' }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    my $value     = $what->column->value;
    my $timestamp = $what->column->timestamp;
    warn "$key1 / $value / $timestamp";
};
die $@->why if $@;

eval {
    my $what = $client->get(
        'Keyspace1',
        $key2,
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Super1', super_column => 'Fred', column => 'name' }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    my $value     = $what->column->value;
    my $timestamp = $what->column->timestamp;
    warn "$key2 / $value / $timestamp";
};
die $@->why if $@;

#  list<ColumnOrSuperColumn> get_slice(1:required string keyspace,
#                                      2:required string key,
#                                      3:required ColumnParent column_parent,
#                                      4:required SlicePredicate predicate,
#                                      5:required ConsistencyLevel consistency_level=1)
#                              throws (1: InvalidRequestException ire, 3: UnavailableException ue),
eval {
    my $what = $client->get_slice(
        'Keyspace1',
        $key1,
        Net::Cassandra::Backend::ColumnParent->new(
            { column_family => 'Standard1' }
        ),
        Net::Cassandra::Backend::SlicePredicate->new(
            {   slice_range => Net::Cassandra::Backend::SliceRange->new(
                    { start => '', finish => '', count => 100 }
                )
            }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    my $value     = $what->[0]->column->value;
    my $timestamp = $what->[0]->column->timestamp;
    warn "$key1 / $value / $timestamp";
};
die $@->why if $@;

#  map<string,ColumnOrSuperColumn> multiget(1:required string keyspace,
#                                           2:required list<string> keys,
#                                           3:required ColumnPath column_path,
#                                           4:required ConsistencyLevel consistency_level=1)
#                                    throws (1: InvalidRequestException ire, 2: UnavailableException ue),
eval {
    my $what = $client->multiget(
        'Keyspace1',
        [$key1],
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    my $value     = $what->{$key1}->column->value;
    my $timestamp = $what->{$key1}->column->timestamp;
    warn "$key1 / $value / $timestamp";
};
die $@->why if $@;

#  map<string,list<ColumnOrSuperColumn>> multiget_slice(1:required string keyspace,
#                                                       2:required list<string> keys,
#                                                       3:required ColumnParent column_parent,
#                                                       4:required SlicePredicate predicate,
#                                                       5:required ConsistencyLevel consistency_level=1)
#                                          throws (1: InvalidRequestException ire, 2: UnavailableException ue),
eval {
    my $what = $client->multiget_slice(
        'Keyspace1',
        [$key1],
        Net::Cassandra::Backend::ColumnParent->new(
            { column_family => 'Standard1' }
        ),
        Net::Cassandra::Backend::SlicePredicate->new(
            { column_names => ['name'], }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    my $value     = $what->{$key1}->[0]->column->value;
    my $timestamp = $what->{$key1}->[0]->column->timestamp;
    warn "$key1 / $value / $timestamp";
};
die $@->why if $@;

#  i32 get_count(1:required string keyspace,
#                2:required string key,
#                3:required ColumnParent column_parent,
#                4:required ConsistencyLevel consistency_level=1)
#      throws (1: InvalidRequestException ire, 2: UnavailableException ue),
eval {
    my $what = $client->get_count(
        'Keyspace1',
        $key1,
        Net::Cassandra::Backend::ColumnParent->new(
            { column_family => 'Standard1' }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
    warn "$key1 / $what columns";
};
die $@->why if $@;

#  list<string> get_key_range(1:required string keyspace,
#                             2:required string column_family,
#                             3:required string start="",
#                             4:required string finish="",
#                             5:required i32 count=100,
#                             6:required ConsistencyLevel consistency_level=1)
#               throws (1: InvalidRequestException ire, 2: UnavailableException ue),
eval {
    my $what
        = $client->get_key_range( 'Keyspace1', 'Standard1', '', '', 100,
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM );
    warn "Keys: ", join( ', ', @$what );
};
warn $@->why if $@;

#  void remove(1:required string keyspace,
#              2:required string key,
#              3:required ColumnPath column_path,
#              4:required i64 timestamp,
#              5:ConsistencyLevel consistency_level=0)
#       throws (1: InvalidRequestException ire, 2: UnavailableException ue),
eval {
    $client->remove(
        'Keyspace1',
        $key1,
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        $timestamp
    );
};
die $@->why if $@;
