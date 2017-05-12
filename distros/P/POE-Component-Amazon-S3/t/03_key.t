#!/usr/bin/perl

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

plan tests => 20;

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
        add_key            => \&add_key,
        add_key_done       => \&add_key_done,
        list_bucket        => \&list_bucket,
        list_bucket_done   => \&list_bucket_done,
        get_key            => \&get_key,
        get_key_done       => \&get_key_done,
        head_key           => \&head_key,
        head_key_done      => \&head_key_done,
        set_acl            => \&set_acl,
        set_acl_done       => \&set_acl_done,
        get_acl            => \&get_acl,
        get_acl_done       => \&get_acl_done,
        delete_key         => \&delete_key,
        delete_key_done    => \&delete_key_done,
        delete_bucket      => \&delete_bucket,
        delete_bucket_done => \&delete_bucket_done,
    },
    heap => {
        random_bucket => 'poco-amazon-s3-test-' . _rand_str(),
        # Some counters
        added_keys     => 0,
        listed_buckets => 0,
        got_keys       => 0,
        set_acl        => 0,
        got_acl        => 0,
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
    
    $kernel->yield( 'add_key' );
}

### Test adding keys from inline and file

sub add_key {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    # Test key with inline data
    $kernel->post(
        s3 => 'add_key', 'add_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_data',
            data   => 'testing 123',
            pass   => [ 'data' ],
        }
    );
    
    # Test key with data from a file
    $kernel->post(
        s3 => 'add_key', 'add_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_file',
            file   => $0,
            pass   => [ 'file' ],
        }
    );
    
    # Test adding a key to an invalid bucket
    $kernel->post(
        s3 => 'add_key', 'add_key_done',
        {
            bucket => _rand_str(),
            key    => 'test_fail',
            data   => 'testing 123',
            pass   => [ 'invalid' ],
        }
    );
}

sub add_key_done {
    my ( $kernel, $heap, $return, $response, $type ) = @_[ KERNEL, HEAP, ARG0 .. ARG2 ];
    
    $heap->{added_keys}++;
    
    if ( $type eq 'invalid' ) {
        if ( $return == 0 && $response->{s3_error}->{code} eq 'NoSuchBucket' ) {
            pass( 'add_key() failed properly on invalid bucket' );
        }
        else {
            fail( 'add_key() did not fail properly on invalid bucket, response: ' . dump($response) );
        }
    }
    else {
        if ( $return == 1 ) {
            pass( "add_key( $type ) uploaded OK" );
        }
        else {
            fail( "add_key( $type ) failed to upload, response: " . dump($response) );
        }
    }
    
    if ( $heap->{added_keys} == 3 ) {
        $kernel->yield( 'list_bucket' );
    }
}

### Test listing buckets

sub list_bucket {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    # Test listing all keys
    $kernel->post(
        s3 => 'list_bucket', 'list_bucket_done',
        {
            bucket => $heap->{random_bucket},
            pass   => [ 'all' ],
        },
    );
    
    # Test max-keys
    $kernel->post(
        s3 => 'list_bucket', 'list_bucket_done',
        {
            bucket     => $heap->{random_bucket},
            'max-keys' => 1,
            pass       => [ 'max-keys' ],
        },
    );
    
    # Test failure on invalid bucket
    $kernel->post(
        s3 => 'list_bucket', 'list_bucket_done',
        {
            bucket => _rand_str(),
            pass   => [ 'invalid' ],
        },
    );    
}

sub list_bucket_done {
    my ( $kernel, $heap, $return, $response, $type ) = @_[ KERNEL, HEAP, ARG0 .. ARG2 ];
    
    $heap->{listed_buckets}++;
    
    if ( $return ) {
        
        if ( $type eq 'all' ) {
            if ( scalar @{ $return->{keys} } == 2 ) {
                pass( 'list_bucket( all ) returned all keys' );
                
                for my $key ( @{ $return->{keys} } ) {
                    if ( $key->{key} eq 'test_from_data' ) {
                        if ( $key->{size} == 11 ) {
                            pass( 'test_from_data listed with correct size' );
                        }
                        else {
                            fail( 'test_from_data not listed with correct size (11), response: ' . dump($response) );
                        }
                    }
                    elsif ( $key->{key} eq 'test_from_file' ) {
                        my $size = -s $0;
                        
                        if ( $key->{size} == $size ) {
                            pass( 'test_from_file listed with correct size' );
                        }
                        else {
                            fail( "test_from_file not listed with correct size ($size), response: " . dump($response) );
                        }
                    }                        
                }
            }
            else {
                fail( 'list_bucket( all ) did not return all keys, response: ' . dump($response) );
            }
        }
        elsif ( $type eq 'max-keys' ) {
            if ( scalar @{ $return->{keys} } == 1 ) {
                pass( 'list_bucket( max-keys ) returned 1 key' );
            }
            else {
                fail( 'list_bucket( max-keys ) did not return 1 key, response: ' . dump($response) );
            }
        }
    }
    else {
        if ( $type eq 'invalid' ) {
            if ( $response->{s3_error}->{code} eq 'NoSuchBucket' ) {
                pass( 'list_bucket() failed properly on invalid bucket' );
            }
            else {
                fail( 'list_bucket() did not fail properly on invalid bucket, response: ' . dump($response) );
            }
        }
        else {
            fail( "list_bucket( $type ) did not return anything, response: " . dump($response) );
        }
    }
    
    if ( $heap->{listed_buckets} == 3 ) {
        $kernel->yield( 'get_key' );
    }
}

### Test getting keys to content and files

sub get_key {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # Test getting a key inline
    $kernel->post(
        s3 => 'get_key', 'get_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_data',
            pass   => [ 'data' ],
        },
    );
    
    # Test failure with a bad key
    $kernel->post(
        s3 => 'get_key', 'get_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => _rand_str(),
            pass   => [ 'invalid' ],
        },
    );

    # Test getting a key to a file
    
    my $dir  = catdir( $Bin, 'poco-amazon-s3-tmp' );
    my $file = catfile( $dir, 'test_from_file.tmp' );
    
    # Clean up if needed
    rmtree $dir if -d $dir;
    
    mkdir $dir;
    
    $kernel->post(
        s3 => 'get_key', 'get_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_file',
            file   => $file,
            pass   => [ 'file', $file ],
        },
    );
}    

sub get_key_done {
    my ( $kernel, $heap, $return, $response, $type, $file ) = @_[ KERNEL, HEAP, ARG0 .. ARG3 ];
    
    $heap->{got_keys}++;
    
    if ( $type eq 'data' ) {
        if ( $response->content eq 'testing 123' ) {
            pass( 'get_key( data ) returned correct data' );
        }
        else {
            fail( 'get_key( data ) returned bad data, response: ' . dump($response) );
        }
    }
    elsif ( $type eq 'invalid' ) {
        if ( $return == 0 && $response->{s3_error}->{code} eq 'NoSuchKey' ) {
            pass( 'get_key() failed properly on invalid key' );
        }
        else {
            fail( 'get_key() did not fail properly on invalid key, response: ' . dump($response) );
        }
    }
    elsif ( $type eq 'file' ) {
        my $data;
        
        eval {
            open my $fh, '<', $file;
            $data = do { local $/; <$fh> };
            close $fh;
            
            my $dir  = catdir( $Bin, 'poco-amazon-s3-tmp' );
            rmtree $dir;
        };
        warn "Failed to read file: $@\n" if $@;
        
        if ( $data =~ /AMZ_S3_ID/ ) {
            pass( 'get_key( file ) returned correct data' );
        }
        else {
            fail( 'get_key( file ) returned bad data, response: ' . dump($response) );
        }
    }
    
    if ( $heap->{got_keys} == 3 ) {
        $kernel->yield( 'head_key' );
    }
}

### Test HEAD on a key

sub head_key {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $kernel->post(
        s3 => 'head_key', 'head_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_file',
        },
    );
}

sub head_key_done {
    my ( $kernel, $heap, $return, $response ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];

    my $file = $0;
    
    if ( $return && $response->content_length == -s $file && !$response->content ) {
        pass( 'head_key() returned ok' );
    }
    else {
        fail( 'head_key() did not return ok, response: ' . dump($response) );
    }
    
    $kernel->yield( 'set_acl' );
}

### Test ACL methods

sub set_acl {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    # Test canned ACL
    $kernel->post(
        s3 => 'set_acl', 'set_acl_done',
        {
            bucket    => $heap->{random_bucket},
            key       => 'test_from_file',
            acl_short => 'public-read',
            pass      => [ 'canned' ],
        }
    );
    
    # Test manual ACL
    my $acl = [
        {
            URI        => 'http://acs.amazonaws.com/groups/global/AuthenticatedUsers',
            permission => 'WRITE',
        },
    ];
    
    $kernel->post(
        s3 => 'set_acl', 'set_acl_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_data',
            acl    => $acl,
            pass   => [ 'manual' ],
        }
    );
}

sub set_acl_done {
    my ( $kernel, $heap, $return, $response, $type ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];

    $heap->{set_acl}++;

    if ( $response->code =~ /^2\d\d$/ ) {
        pass( "set_acl( $type ) ok" );
    }
    else {
        fail( "set_acl( $type ) failed, response: " . dump($response) );
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
            key    => 'test_from_file',
            pass   => [ 'READ' ],   # what perm to test for
        }
    );
    
    $kernel->post(
        s3 => 'get_acl', 'get_acl_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_data',
            pass   => [ 'WRITE' ], 
        }
    );
}

sub get_acl_done {
    my ( $kernel, $heap, $return, $response, $check ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];
     
    $heap->{got_acl}++;

    if ( $response->code =~ /^2\d\d$/ && $response->content =~ /$check/ ) {
        pass( "get_acl( $check ) ok" );
    }
    else {
        fail( "get_acl( $check ) failed, response: " . dump($response) );
    }
     
    if ( $heap->{got_acl} == 2 ) {
        $kernel->yield( 'delete_key' );
    }
}

### Test deleting each key

sub delete_key {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $kernel->post(
        s3 => 'delete_key', 'delete_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_data',
            pass   => [ 'data' ],
        },
    );

    $kernel->post(
        s3 => 'delete_key', 'delete_key_done',
        {
            bucket => $heap->{random_bucket},
            key    => 'test_from_file',
            pass   => [ 'file' ],
        },
    );
}

sub delete_key_done {
    my ( $kernel, $heap, $return, $response, $type ) = @_[ KERNEL, HEAP, ARG0 .. ARG2 ];
    
    $heap->{deleted_keys}++;
    
    if ( $return == 1 ) {
        pass( "delete_key( $type ) deleted ok" );
    }
    else {
        fail( "delete_key( $type ) failed to delete, response: " . dump($response) );
    }
    
    if ( $heap->{deleted_keys} == 2 ) {
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