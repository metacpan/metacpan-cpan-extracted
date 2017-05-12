#!/usr/bin/perl

use strict;

use Data::Dump qw(dump);
use Test::More;
use POE;
use POE::Component::Amazon::S3;
use Time::HiRes qw(gettimeofday);

plan skip_all => 'set AMZ_S3_ID and AMZ_S3_KEY env vars to run tests'
    unless $ENV{AMZ_S3_ID} && $ENV{AMZ_S3_KEY};

plan tests => 9;

POE::Component::Amazon::S3->spawn(
    alias                 => 's3',
    aws_access_key_id     => $ENV{AMZ_S3_ID},
    aws_secret_access_key => $ENV{AMZ_S3_KEY},
);

POE::Session->create(
    inline_states => {
        _start             => \&_start,
        shutdown           => \&shutdown,
        add_bucket         => \&add_bucket,
        add_bucket_done    => \&add_bucket_done,
        buckets            => \&buckets,
        buckets_done       => \&buckets_done,
        set_acl            => \&set_acl,
        set_acl_done       => \&set_acl_done,
        get_acl            => \&get_acl,
        get_acl_done       => \&get_acl_done,
        delete_bucket      => \&delete_bucket,
        delete_bucket_done => \&delete_bucket_done,
    },
    heap => {
        random_bucket => 'poco-amazon-s3-test-' . _rand_str(),
        # counters
        added         => 0,
        set_acl       => 0,
        got_acl       => 0,
        deleted       => 0,
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
            pass   => [ 'ok' ],
        }
    );
    
    # Try adding an invalid bucket
    $kernel->post(
        s3 => 'add_bucket', 'add_bucket_done',
        {
            bucket => 'invalid bucket',
            pass   => [ 'invalid' ],
        }
    );
}

sub add_bucket_done {
    my ( $kernel, $heap, $return, $response, $type ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];
    
    $heap->{added}++;
    
    if ( $type eq 'invalid' ) {
        if ( $return == 0 && $response->{s3_error}->{code} eq 'InvalidBucketName' ) {
            pass( 'add_bucket() failed properly with invalid name' );
        }
        else {
            fail( 'add_bucket() did not fail properly with invalid name, response: ' . dump($response) );
        }
    }
    else {    
        if ( $return == 1 ) {
            pass('add_bucket() success');
        }
        else {
            fail( 'add_bucket() was unable to add new bucket, response was: ' . dump($response) );
        }
    }
    
    if ( $heap->{added} == 2 ) {
        # Sometimes Amazon is a bit slow to add a new bucket so our buckets call will fail
        $kernel->delay_set( 'buckets', 2 );
    }
}

### Test buckets returns the newly added bucket

sub buckets {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $kernel->post(
        s3 => 'buckets', 'buckets_done',
    );
}

sub buckets_done {
    my ( $kernel, $heap, $return, $response ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];
    
    my $ok;
    
    for my $bucket ( @{ $return->{buckets} } ) {
        if ( $bucket->{bucket} eq $heap->{random_bucket} ) {
            pass('buckets() saw our new bucket');
            $ok = 1;
            last;
        }
    }
    
    if ( !$ok ) {
        fail('buckets() failed or did not see new bucket, response was: ' . dump($response) );
    }
    
    $kernel->yield( 'set_acl' );
}

### Test ACL methods

sub set_acl {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $kernel->post(
        s3 => 'set_acl', 'set_acl_done',
        {
            bucket    => $heap->{random_bucket},
            acl_short => 'public-read',
            pass      => [ 'ok' ],
        }
    );
    
    # Set an invalid ACL
    $kernel->post(
        s3 => 'set_acl', 'set_acl_done',
        {
            bucket => $heap->{random_bucket},
            acl    => [
                {
                    email      => 'foo@bar.org',
                    permission => 'READ',
                }
            ],
            pass   => [ 'invalid' ],
        }
    );
}

sub set_acl_done {
    my ( $kernel, $heap, $return, $response, $type ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];
     
    $heap->{set_acl}++;
     
    if ( $type eq 'invalid' ) {
        if ( $return == 0 && $response->{s3_error}->{code} eq 'AmbiguousGrantByEmailAddress' ) {
            pass( 'set_acl() failed properly with invalid email' );
        }
        else {
            fail( 'set_acl() did not fail properly with invalid email, response: ' . dump($response) );
        }         
    }
    else {
        if ( $return ) {
            pass( 'set_acl() ok' );
        }
        else {
            fail( 'set_acl() failed, response: ' . dump($response) );
        }
    }
    
    if ( $heap->{set_acl} == 2 ) {
        $kernel->yield( 'get_acl' );
    }
}    

sub get_acl {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $kernel->post(
        s3 => 'get_acl', 'get_acl_done',
        {
            bucket => $heap->{random_bucket},
            pass   => [ 'ok' ],
        }
    );
    
    # Try to get ACL on an invalid bucket
    $kernel->post(
        s3 => 'get_acl', 'get_acl_done',
        {
            bucket => _rand_str(),
            pass   => [ 'invalid' ],
        }
    );    
}

sub get_acl_done {
    my ( $kernel, $heap, $return, $response, $type ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];

    $heap->{got_acl}++;

    if ( $type eq 'invalid' ) {
        if ( $return == 0 && $response->{s3_error}->{code} eq 'NoSuchBucket' ) {
            pass( 'get_acl() failed properly with invalid bucket' );
        }
        else {
            fail( 'get_acl() did not fail properly with invalid bucket, response: ' . dump($response) );
        }
    }
    else {
        if ( $return && $response->content =~ /READ/ ) {
            pass( 'get_acl() ok' );
        }
        else {
            fail( 'get_acl() failed, response: ' . dump($response) );
        }
    }

    if ( $heap->{got_acl} == 2 ) {
        $kernel->yield( 'delete_bucket' );
    }
}

### Test deleting of buckets

sub delete_bucket {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    # Delete an existing bucket
    $kernel->post(
        s3 => 'delete_bucket', 'delete_bucket_done',
        {
            bucket => $heap->{random_bucket},
        }
    );
    
    # Delete a non-existant bucket
    $kernel->post(
        s3 => 'delete_bucket', 'delete_bucket_done',
        {
            bucket => _rand_str(),
            pass   => [ 'fail_ok' ],
        }
    );    
}

sub delete_bucket_done {
    my ( $kernel, $heap, $return, $response, $fail_ok ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];
    
    $heap->{deleted}++;
    
    if ( $fail_ok ) {
        if ( $return == 0 && $response->{s3_error}->{code} eq 'NoSuchBucket' ) {
            pass('delete_bucket() failed properly on invalid bucket');
        }
        else {
            fail('delete_bucket() did not fail properly on invalid bucket, response: ' . dump($response) );
        }
    }
    else {
        if ( $return == 1 ) {
            pass('delete_bucket() success');
        }
        else {
            fail( 'delete_bucket() was unable to delete bucket, response: ' . dump($response) );
        }
    }
    
    if ( $heap->{deleted} == 2 ) {
        # We're all done!
        $kernel->yield( 'shutdown' );
    }
}

### Utils 

# Taken from Data::Uniqid
sub _rand_str {
    my ($s, $us) = gettimeofday();
    my ($v) = sprintf( "%d%d%d", $us, substr($s,-5), $$ );
    return $v;
}