use strict;
use Test::More;
use Test::Requires 'Test::TCP', 'Plack::Runner', 'Digest::MD5';
use Plack::Middleware::Auth::Basic;

use_ok "Net::STF::Client";

my %BUCKETS;
my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $runner = Plack::Runner->new; 
        $runner->parse_options( '-p' => $port );
        my $app = sub {
            my $env = shift;

            my $path_info = $env->{PATH_INFO};
            my $method = $env->{REQUEST_METHOD};
            if ( $method eq 'PUT' ) {
                if ( $path_info =~ m{^/([^/]+)(/.+)?$} ) {
                    my ($bucket_name, $object_name) = ($1, $2);
                    if ( ! $object_name ) {
                        if (! exists $env->{CONTENT_LENGTH}) {
                            return [ 500, [ 'content-type' => 'text/plain' ], [ 'content-length required' ] ];
                        }
                        if ($env->{CONTENT_LENGTH} != 0) {
                            return [ 500, [ 'content-type' => 'text/plain' ], [ 'content-length invalid' ] ];
                        }

                        $BUCKETS{$bucket_name} ||= {};
                        return  [ 201, [], [] ];
                    } else {
                        my $bucket = $BUCKETS{$bucket_name};
                        if (! $bucket) {
                            return [ 404, [], [] ];
                        }
                        my $fh = $bucket->{$object_name} = File::Temp->new(UNLINK => 1);
                        my $input = $env->{'psgi.input'};
                        my $content = do { local $/; <$input> };
                        print $fh $content;
                        $fh->flush;
                        return [ 201, [], [] ];
                    }
                } else {
                    return [ 400, [], [] ];
                }
            } elsif ( $method eq 'GET' ) {
                if ( $path_info =~ m{^/([^/]+)(/.+)$} ) {
                    my ($bucket_name, $object_name) = ($1, $2);
                    my $bucket = $BUCKETS{$bucket_name};
                    if (! $bucket) {
                        return [ 404, [], [] ];
                    }

                    my $object = $bucket->{$object_name};
                    if (! $object) {
                        return [ 404, [], [] ];
                    }

                    seek $object, 0, 0;
                    my $content = do { local $/; <$object> };
                    return [ 200, [], [ $content ] ];
                } else {
                    return [ 400, [], [] ];
                }
            } elsif ( $method eq 'DELETE' ) {
                if ( $path_info =~ m{^/([^/]+)(/.+)?$} ) {
                    my ($bucket_name, $object_name) = ($1, $2);
                    my $bucket = $BUCKETS{$bucket_name};
                    if (! $bucket) {
                        return [ 404, [], [] ];
                    }

                    if ( $object_name ) { # deleting an object
                        my $object = delete $bucket->{$object_name};
                        if (! $object) {
                            return [ 404, [], [] ];
                        }
                    } else { # deleting a bucket
                        delete $BUCKETS{$bucket_name};
                    }
                    return [ 204, [], [] ]
                } else {
                    return [ 400, [], [] ];
                }
            }

            return [ 500, [], [] ];
        };
        $app = Plack::Middleware::Auth::Basic->wrap($app, authenticator => sub {
            my ($username, $password) = @_;
            return $username eq 'hoge' && $password eq 'fuga';
        } );
        $runner->run($app);
    }
);

subtest 'direct crud interface' => sub {
    my $bucket = "foo";
    my $base = sprintf "http://127.0.0.1:%d", $server->port;
    
    my $client = Net::STF::Client->new(
        username => "hoge",
        password => "fuga"
    );

    ok $client->create_bucket( "$base/$bucket" ), "bucket creation OK";
    ok $client->put_object( "$base/$bucket/foo", __FILE__ ), "object creation OK";
    
    my $object = $client->get_object( "$base/$bucket/foo" );
    if (ok $object, "object fetch OK") {
        my $mydigest = Digest::MD5->new;
        my $theirdigest = Digest::MD5->new;
    
        open my $fh, '<', __FILE__;
        $mydigest->addfile($fh);
        $theirdigest->add( $object->content );
    
        if (! is $theirdigest->hexdigest, $mydigest->hexdigest, "contents match" ) {
            diag $object->content;
        }
    }
};

subtest 'bucket interface (Net::STF like)' => sub {
    my $bucket_name = "bar";
    my $base = sprintf "http://127.0.0.1:%d", $server->port;
    
    my $client = Net::STF::Client->new(
        url => $base,
        username => "hoge",
        password => "fuga"
    );

    my $bucket = $client->create_bucket( $bucket_name );

    ok $bucket, "bucket creation OK";
    ok $bucket->put_object( foo => __FILE__ ), "object creation OK";
    
    my $object = $bucket->get_object( "foo" );
    if (ok $object, "object fetch OK") {
        my $mydigest = Digest::MD5->new;
        my $theirdigest = Digest::MD5->new;
    
        open my $fh, '<', __FILE__;
        $mydigest->addfile($fh);
        $theirdigest->add( $object->content );
    
        if (! is $theirdigest->hexdigest, $mydigest->hexdigest, "contents match" ) {
            diag $object->content;
        }

        is $object->bucket_name, "bar", "bucket name match";
        is $object->key, "foo", "object key match";

        # now attempt to delete
        $bucket->delete_object("foo");
        ok ! $bucket->get_object("foo"), "object does not exist (expected)";
        $bucket->delete;
        ok ! exists $BUCKETS{"bar"};
    }
};

done_testing;