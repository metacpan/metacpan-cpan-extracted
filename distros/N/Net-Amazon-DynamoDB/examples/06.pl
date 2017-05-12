#!/usr/bin/perl


use strict;
use warnings;
use FindBin qw/ $Bin /;
use Data::Dumper;
use lib "$Bin/../lib";
use Net::Amazon::DynamoDB;
#use Cache::File;
use Cache::Memory;
use Time::HiRes qw/ gettimeofday tv_interval /;

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
                hid          => 'S',
                rid          => 'S',
                some_attrib  => 'S',
                other_attrib => 'S',
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

if(0) {
    print "Batch write put items ";
    $ddb->batch_write_item( { $table => {
        put => [ map {
            {
                hid          => 'HKey'. $_,
                rid          => 'RKey'. $_,
                some_attrib  => 'Whatever '. ( 'Bla' x $_ ),
                other_attrib => 'Number '. $_
            }
        } 1..10 ]
    } }, { process_all => 0 } );
}
else {
    $ddb->batch_write_item( { $table => {
        delete => [ map {
            {
                hid          => 'HKey'. $_,
                rid          => 'RKey'. $_,
            }
        } 1..10 ]
    } }, { process_all => 0 } );
}
print " OK\n";

