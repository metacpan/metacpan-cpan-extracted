#!/usr/bin/perl

# Create many keys and see if list_bucket_all can
# retrieve them all

use strict;

use Data::Dump qw(dump);
use FindBin qw($Bin);
use File::Path;
use File::Spec::Functions qw(catdir catfile);
use Test::More;
use POE;
use POE::Component::Amazon::S3;
use Time::HiRes qw(gettimeofday);

plan skip_all => 'set AMZ_S3_ID and AMZ_S3_KEY env vars to run tests'
    unless $ENV{AMZ_S3_ID} && $ENV{AMZ_S3_KEY};

plan skip_all => 'set AMZ_S3_STRESS to run this test.  It creates lots of keys.'
    unless $ENV{AMZ_S3_STRESS};

my $NUM_KEYS = 150;

plan tests => ( $NUM_KEYS * 2 ) + 3;

POE::Component::Amazon::S3->spawn(
    alias                 => 's3',
    aws_access_key_id     => $ENV{AMZ_S3_ID},
    aws_secret_access_key => $ENV{AMZ_S3_KEY},
);

POE::Session->create(
    inline_states => {
        _start               => \&_start,
        shutdown             => \&shutdown,
        add_bucket           => \&add_bucket,
        add_bucket_done      => \&add_bucket_done,
        add_key              => \&add_key,
        add_key_done         => \&add_key_done,
        list_bucket_all      => \&list_bucket_all,
        list_bucket_all_done => \&list_bucket_all_done,
        delete_key           => \&delete_key,
        delete_key_done      => \&delete_key_done,
        delete_bucket        => \&delete_bucket,
        delete_bucket_done   => \&delete_bucket_done,
    },
    heap => {
        random_bucket => 'poco-amazon-s3-test-' . _rand_str(),
        # Some counters
        added_keys     => 0,
        deleted_keys   => 0,
    },
);

POE::Kernel->run();
exit 1;

sub _start {
    my $kernel = @_[ KERNEL ];
    
    $kernel->alias_set( 's3_testing' );
    $kernel->yield( 'add_bucket' );
}

sub shutdown {
    my $kernel = @_[ KERNEL ];
    
    $kernel->post( s3 => 'shutdown' );
    
    $kernel->alias_remove( 's3_testing' );
}

### Test adding a bucket

sub add_bucket {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $kernel->post(
        s3 => 'add_bucket', 'add_bucket_done',
        {
            bucket => $heap->{random_bucket},
        }
    );
}

sub add_bucket_done {
    my ( $kernel, $heap, $return, $response ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];
    
    if ( $return == 1 ) {
        pass('add_bucket() success');
    }
    else {
        fail( 'add_bucket() was unable to add new bucket, response was: ' . dump($response) );
    }
    
    # Add lots of keys
    for ( 1 .. $NUM_KEYS ) {
        $kernel->yield( 'add_key', $_ );
    }
}

sub add_key {
    my ( $kernel, $heap, $count ) = @_[ KERNEL, HEAP, ARG0 ];
    
    # Test key with inline data
    $kernel->post(
        s3 => 'add_key', 'add_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'stress_' . $count,
            data   => 'testing',
        }
    );
}

sub add_key_done {
    my ( $kernel, $heap, $return, $response ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];
    
    $heap->{added_keys}++;
    
    if ( $return == 1 ) {
        pass( "add_key() uploaded OK" );
    }
    else {
        fail( "add_key() failed to upload" );
    }
    
    if ( $heap->{added_keys} == $NUM_KEYS ) {
        $kernel->yield( 'list_bucket_all' );
    }
}

sub list_bucket_all {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # Test listing all keys
    $kernel->post(
        s3 => 'list_bucket_all', 'list_bucket_all_done',
        {
            bucket => $heap->{random_bucket},
        },
    );
}

sub list_bucket_all_done {
    my ( $kernel, $heap, $return, $response ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];
    
    if ( $return ) {
        if ( scalar @{ $return->{keys} } == $NUM_KEYS ) {
            pass( 'list_bucket_all() returned all keys' );
        }
        else {
            fail( 'list_bucket_all() did not return all keys, response: ' . dump($response) );
        }
    }
    else {
        fail( "list_bucket_all() did not return anything, response: " . dump($response) );
    }
    
    for ( 1 .. $NUM_KEYS ) {
       $kernel->yield( 'delete_key', $_ );
    }
}

### Test deleting each key

sub delete_key {
    my ( $kernel, $heap, $count ) = @_[ KERNEL, HEAP, ARG0 ];
    
    $kernel->post(
        s3 => 'delete_key', 'delete_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'stress_' . $count,
        },
    );
}

sub delete_key_done {
    my ( $kernel, $heap, $return, $response ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];
    
    $heap->{deleted_keys}++;
    
    if ( $return == 1 ) {
        pass( "delete_key() deleted ok" );
    }
    else {
        fail( "delete_key() failed to delete, response: " . dump($response) );
    }
    
    if ( $heap->{deleted_keys} == $NUM_KEYS ) {
        $kernel->yield( 'delete_bucket' );
    }
}

### Clean up by deleting the test bucket

sub delete_bucket {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $kernel->post(
        s3 => 'delete_bucket', 'delete_bucket_done',
        {
            bucket => $heap->{random_bucket},
        }
    );
}

sub delete_bucket_done {
    my ( $kernel, $heap, $return, $response ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];

    if ( $return == 1 ) {
        pass('delete_bucket() success');
    }
    else {
        fail( 'delete_bucket() was unable to delete bucket, response was: ' . dump($response) );
    }
    
    # We're all done!
    $kernel->yield( 'shutdown' );
}

### Utils 

# Taken from Data::Uniqid
sub _rand_str {
    my ($s, $us) = gettimeofday();
    my ($v) = sprintf( "%d%d%d", $us, substr($s,-5), $$ );
    return $v;
}