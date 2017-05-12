#!/usr/bin/perl


use strict;
use warnings;
use FindBin qw/ $Bin /;
use Data::Dumper;
use lib "$Bin/../lib";
use Net::Amazon::DynamoDB;

$| = 1;

my $table_prefix = $ENV{ AWS_TEST_TABLE_PREFIX } || 'test_';
my $table = $table_prefix. 'sometable';

# create ddb
my $ddb = Net::Amazon::DynamoDB->new(
    access_key => $ENV{ AWS_ACCESS_KEY_ID },
    secret_key => $ENV{ AWS_SECRET_ACCESS_KEY },
    namespace  => 'dings_',
    #use_keepalives => 10,
    tables     => {
        $table => {
            hash_key  => 'hid',
            range_key => 'rid',
            attributes  => {
                hid  => 'S',
                rid  => 'S',
                data => 'S'
            }
        }
    }
);

print "Create table $table?\n";
$ddb->create_table( $table, 10, 5 )
    unless $ddb->exists_table( $table );
print "Waiting for $table ";
while(1) {
    my $descr_ref = $ddb->describe_table( $table );
    last if $descr_ref && $descr_ref->{ status } eq 'ACTIVE';
    print ".";
    sleep 1;
}
print " OK\n";

print "Put items ";
$ddb->put_item( $table => {
    hid  => 'node/somenode/http',
    rid  => '~web'. $_,
    data => 'I Am Web '. $_
} ) for 1..10;
print " OK\n";

print "Query Items ";
my $query_ref = $ddb->query_items( $table => {
    hid => 'node/somenode/http',
    rid => {
        BEGINS_WITH => '~'
    }
} );
print " OK\n";
print Dumper( $query_ref );