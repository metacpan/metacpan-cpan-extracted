#!/usr/bin/perl


use strict;
use warnings;
use Test::More tests => 4;
use FindBin qw/ $Bin /;
use Data::Dumper;
use lib "$Bin/../lib";

use_ok( "Net::Amazon::DynamoDB" );
use_ok( 'Cache::Memory' );

SKIP: {
    
    skip "No AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY set in ENV. Not running any tests.\n"
        ."CAUTION: Tests require to create new tables which will cost you money!!", 2
        unless defined $ENV{ AWS_ACCESS_KEY_ID } && defined $ENV{ AWS_SECRET_ACCESS_KEY };
    my $table_prefix = $ENV{ AWS_TEST_TABLE_PREFIX } || 'test_';
    
    my @tests = (
        {
            namespace => '',
        },
        {
            namespace => 'cached_',
            cache     => Cache::Memory->new(),
        }
    );
    
    foreach my $test_ref( @tests ) {
        
        subtest( 'Online Tests ['. join( ', ', map {
            sprintf( '%s: %s', $_, defined $test_ref->{ $_ } && $test_ref->{ $_ } ? 'yes' : 'no' );
        } qw/ namespace cache / ). ']' => sub {
            
            my $table1 = $table_prefix. 'table1';
            my $table2 = $table_prefix. 'table2';
            
            # create ddb
            my $ddb = eval { Net::Amazon::DynamoDB->new(
                %$test_ref,
                access_key  => $ENV{ AWS_ACCESS_KEY_ID },
                secret_key  => $ENV{ AWS_SECRET_ACCESS_KEY },
                raise_error => 1,
                tables      => {
                    $table1 => {
                        hash_key => 'id',
                        attributes  => {
                            id => 'N',
                            name => 'S'
                        }
                    },
                    $table2 => {
                        hash_key => 'id',
                        range_key => 'range_id',
                        attributes  => {
                            id => 'N',
                            range_id => 'N',
                            attrib1 => 'S',
                            attrib2 => 'S'
                        }
                    }
                }
            ) };
            BAIL_OUT( "Failed to instantiate Net::Amazon::DynamoDB: $@" ) if $@;
            
            # create tables
            foreach my $table( $table1, $table2 ) {
                if ( $ddb->exists_table( $table ) ) {
                    pass( "Table $table already exists" );
                    next;
                }
                my $create_ref = $ddb->create_table( $table, 10, 5 );
                ok( $create_ref && ( $create_ref->{ status } eq 'ACTIVE' || $create_ref->{ status } eq 'CREATING' ), "Create response for $table" );
                
                subtest( "Waiting for $table being created", sub {
                    if ( $create_ref->{ status } eq 'ACTIVE' ) {
                        plan skip_all => "Table $table already created";
                        return;
                    }
                    plan tests => 1;
                    foreach my $num( 1..60 ) {
                        my $desc_ref = $ddb->describe_table( $table );
                        if ( $desc_ref && $desc_ref->{ status } eq 'ACTIVE' ) {
                            pass( "Table $table has been created" );
                            last;
                        }
                        sleep 1;
                    }
                } );
            }
            
            # put test
            ok( $ddb->put_item( $table1 => { id => 1, name => "First entry" } ), "First entry in $table1 created" );
            
            # read test
            my $read_ref = $ddb->get_item( $table1 => { id => 1 } );
            ok( $read_ref && $read_ref->{ id } == 1 && $read_ref->{ name } eq 'First entry', "First entry from $table1 read" );
            
            # update test
            my $update_ref = $ddb->update_item( $table1 => { name => "Updated first entry" }, { id => 1 }, {
                return_mode => 'ALL_NEW'
            } );
            ok( $update_ref && $update_ref->{ name } eq 'Updated first entry', "Update in $table1 ok" );
            
            # create multiple in table1
            foreach my $num( 2..10 ) {
                $ddb->put_item( $table1 => { id => $num, name => "${num}. entry" } )
            }
            
            # scan search in table1
            my $search_ref = $ddb->scan_items( $table1 );
            ok( $search_ref && scalar( @$search_ref ) == 10, "Scanned for 10 items in $table1" );
            #print Dumper( $search_ref );
            
            # create multiple in table2 in range table and search there
            foreach my $num( 1..10 ) {
                $ddb->put_item( $table2 => {
                    id       => ( $num % 2 )+ 1,
                    range_id => $num,
                    attrib1  => "The time string ". localtime(),
                    attrib2  => "The time unix ". time()
                } );
            }
            my $query_ref = $ddb->query_items( $table2 => { id => 1, range_id => { GT => 5 } } );
            ok( $query_ref && scalar( @$query_ref ) == 3, "Query for 3 items in $table2" );
            
            # batch get multuiple
            my $batch_ref = $ddb->batch_get_item( {
                $table1 => [
                    { id => 1 },
                    { id => 10 }
                ],
                $table2 => [
                    { id => 2, range_id => 1 },
                    { id => 1, range_id => 2 },
                ]
            } );
            #print Dumper( $batch_ref );
            ok(
                defined $batch_ref->{ $table1 } && scalar( @{ $batch_ref->{ $table1 } } ) == 2
                && defined $batch_ref->{ $table2 } && scalar( @{ $batch_ref->{ $table2 } } ) == 2,
                "Found 4 entries from $table1 and $table2 with batch get"
            );
            
            # clean up
            foreach my $table( $table1, $table2 ) {
                ok( $ddb->delete_table( $table ), "Table $table delete initialized" );
                
                foreach my $num( 1..60 ) {
                    unless( $ddb->exists_table( $table ) ) {
                        pass( "Table $table is deleted" );
                        last;
                    }
                }
            }
        } );
    }
}
