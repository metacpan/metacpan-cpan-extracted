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
    },
    raise_error => 1
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
    hid  => 'thehash',
    rid  => 'therid'. $_,
    data => 'I am Number '. $_
} ) for 1..10;
print " OK\n";

print "Update item ";
my $update_ref = $ddb->update_item( $table => {
    data => 'New Data'
}, {
    hid => 'thehash',
    rid => 'therid2',
} );
print " OK\n";

print "Update Table ";
my $ut_ref = $ddb->update_table( $table => 10, 6 );
print " OK\n";
print Dumper( $ut_ref );