package POE::Component::Amazon::S3;

use strict;

use Carp qw(carp croak);
use Data::Dump qw(dump);
use Digest::HMAC_SHA1;
use HTTP::Date;
use HTTP::Request;
use MIME::Base64 qw(encode_base64);
use POE;
use POE::Component::Client::HTTP;
use URI::Escape qw(uri_escape);
use XML::LibXML;
use XML::LibXML::XPathContext;

our $VERSION = '0.01';

my $AMAZON_HEADER_PREFIX = 'x-amz-';
my $METADATA_PREFIX      = 'x-amz-meta-';

# block size when downloading/uploading to files
my $BLOCK_SIZE           = 4096;

# max keys to fetch each time when calling list_bucket_all
my $MAX_KEYS_PER_CHUNK   = 100;

# unique id counter for list_bucket_all to store temporary results
my $LIST_ID              = 1;

sub spawn {
    my $class = shift;
    
    croak "$class requires an even number of parameters" if @_ % 2;
    
    my %params = @_;
    
    croak "$class requires aws_access_key_id and aws_secret_access_key"
        unless $params{aws_access_key_id} && $params{aws_secret_access_key};
    
    $params{libxml} = XML::LibXML->new;
    
    my $self = bless \%params, $class;
    
    # A non-streaming HTTP client for most requests
    POE::Component::Client::HTTP->spawn(
        Agent   => 'POE-Component-Amazon-S3/' . $VERSION,
        Alias   => 'ua',
        Timeout => 30,
    );
    
    # A streaming HTTP client for downloads
    POE::Component::Client::HTTP->spawn(
        Agent     => 'POE-Component-Amazon-S3/' . $VERSION,
        Alias     => 'ua-streaming',
        Timeout   => 30,
        Streaming => $BLOCK_SIZE,
    );
    
    POE::Session->create(
        object_states => [
            $self => [
                qw/
                    _start
                    shutdown
                          
                    add_bucket
                    add_bucket_done
                    buckets
                    buckets_done
                    delete_bucket
                    delete_bucket_done

                    add_key
                    add_key_done
                    head_key
                    head_key_done
                    list_bucket
                    list_bucket_done
                    list_bucket_all
                    list_bucket_all_chunk
                    get_acl
                    get_acl_done
                    get_key
                    get_key_done
                    delete_key
                    delete_key_done
                    set_acl
                    set_acl_got_current
                    set_acl_done
                /
            ],
        ],
    );
    
    return;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    $kernel->alias_set( $self->{alias} || 's3' );
}

sub shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    # Shut down our HTTP clients
    $kernel->post( ua => 'shutdown' );
    $kernel->post( 'ua-streaming' => 'shutdown' );
    
    $kernel->alias_remove( $self->{alias} || 'amazon-s3' );
}

### Bucket methods

sub add_bucket {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = $conf->{bucket};
    croak 'must specify bucket' unless $bucket;

    if ($conf->{acl_short}){
        $self->_validate_acl_short($conf->{acl_short});
    }

    my $header_ref = ($conf->{acl_short})
        ? {'x-amz-acl' => $conf->{acl_short}}
        : {};
    
    my $request = $self->_make_request( PUT => $bucket, $header_ref );
    
    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $conf->{pass} || [],
    };
    
    $kernel->post( ua => request => add_bucket_done => $request, $pass );
}

sub add_bucket_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];
    
    my $return = $self->_check_error( $response );
    
    $kernel->post( 
        $pass->{sender}, 
        $pass->{event}, 
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub buckets {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];

    my $request = $self->_make_request( GET => '' );

    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $conf->{pass} || [],
    };

    $kernel->post( ua => request => buckets_done => $request, $pass );
}

sub buckets_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];

    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];
    
    my $return = $self->_check_error( $response );
    
    if ( $return ) {
        my $xpc = $self->_xpc_of_content( $response->content );
    
        my $owner_id          = $xpc->findvalue("//s3:Owner/s3:ID");
        my $owner_displayname = $xpc->findvalue("//s3:Owner/s3:DisplayName");

        my @buckets;
        foreach my $node ( $xpc->findnodes(".//s3:Bucket") ) {
            push @buckets, {
                bucket        => $xpc->findvalue( ".//s3:Name", $node ),
                creation_date => $xpc->findvalue( ".//s3:CreationDate", $node ),
            };
        }
    
        $return = {
            owner_id          => $owner_id,
            owner_displayname => $owner_displayname,
            buckets           => \@buckets,
        };
    }
    
    $kernel->post( 
        $pass->{sender}, 
        $pass->{event}, 
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub delete_bucket {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = delete $conf->{bucket};
    
    croak 'must specify bucket' unless $bucket;

    my $request = $self->_make_request( DELETE => $bucket );

    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $conf->{pass} || [],
    };

    $kernel->post( ua => request => delete_bucket_done => $request, $pass );
}

sub delete_bucket_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];

    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];

    my $return = $self->_check_error( $response );

    $kernel->post( 
        $pass->{sender}, 
        $pass->{event}, 
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

### Key methods

sub add_key {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = delete $conf->{bucket};
    my $key    = delete $conf->{key};
    
    croak 'must specify bucket' unless $bucket;
    croak 'must specify key' unless $key;
    
    if ($conf->{acl_short}) {
        $self->_validate_acl_short($conf->{acl_short});
        $conf->{'x-amz-acl'} = delete $conf->{acl_short};
    }

    my $data = delete $conf->{data} || '';
    my $file = delete $conf->{file};

    my $pass = delete $conf->{pass};
    
    my $request = $self->_make_request(
        PUT => $self->_uri( $bucket, $key ), $conf, $data
    );

    if ( $file && -e $file ) {
        # Upload directly from a file
        $request->content_length( -s $file );
    
        open my $fh, '<', $file;
        
        my $file_cb = sub {
            my $read = sysread $fh, my $buf, $BLOCK_SIZE;
            
            if ( $read ) {
                return $buf;
            }
            else {
                close $fh;
                return '';
            }
        };
   
        $request->content( $file_cb );
    }
    
    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $pass || [],
    };

    $kernel->post( ua => request => add_key_done => $request, $pass );
}

sub add_key_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];

    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];

    my $return = $self->_check_error( $response );

    $kernel->post( 
        $pass->{sender},
        $pass->{event},
        $return,
        $response,
        @{ $pass->{pass} }
    );
}

sub head_key {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = delete $conf->{bucket};
    my $key    = delete $conf->{key};
    
    croak 'must specify bucket' unless $bucket;
    croak 'must specify key' unless $key;
    
    my $request = $self->_make_request( HEAD => $self->_uri( $bucket, $key ) );
    
    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $conf->{pass} || [],
    };

    $kernel->post( ua => request => head_key_done => $request, $pass );
}

sub head_key_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];
    
    my $return = $self->_check_error( $response );
 
    $kernel->post(
        $pass->{sender},
        $pass->{event},
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub list_bucket {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = delete $conf->{bucket};
    croak 'must specify bucket' unless $bucket;
    
    my $pass = delete $conf->{pass};
    
    my $path = $bucket;
    
    if ( %$conf ) {
        $path .= '?'
            . join( '&',
            map { $_ . '=' . $self->_urlencode( $conf->{$_} ) } keys %$conf );
    }
    
    my $request = $self->_make_request( GET => $path );
    
    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $pass || [],
        conf   => $conf,
    };
    
    $kernel->post( ua => request => list_bucket_done => $request, $pass );
}

sub list_bucket_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];
    
    my $return = $self->_check_error( $response );
    
    if ( $return ) {
        my $xpc = $self->_xpc_of_content( $response->content );
    
        $return = {
            bucket       => $xpc->findvalue("//s3:ListBucketResult/s3:Name"),
            prefix       => $xpc->findvalue("//s3:ListBucketResult/s3:Prefix"),
            marker       => $xpc->findvalue("//s3:ListBucketResult/s3:Marker"),
            next_marker  => $xpc->findvalue("//s3:ListBucketResult/s3:NextMarker"),
            max_keys     => $xpc->findvalue("//s3:ListBucketResult/s3:MaxKeys"),
            is_truncated => (
                scalar $xpc->findvalue("//s3:ListBucketResult/s3:IsTruncated") eq
                    'true'
                ? 1
                : 0
            ),
        };
    
        my @keys;
        foreach my $node ( $xpc->findnodes(".//s3:Contents") ) {
            my $etag = $xpc->findvalue( ".//s3:ETag", $node );
            $etag =~ s/^"//;
            $etag =~ s/"$//;

            push @keys,
                {
                key           => $xpc->findvalue( ".//s3:Key",          $node ),
                last_modified => $xpc->findvalue( ".//s3:LastModified", $node ),
                etag          => $etag,
                size          => $xpc->findvalue( ".//s3:Size",         $node ),
                storage_class => $xpc->findvalue( ".//s3:StorageClass", $node ),
                owner_id      => $xpc->findvalue( ".//s3:ID",           $node ),
                owner_displayname =>
                    $xpc->findvalue( ".//s3:DisplayName", $node ),
                };
        }
        $return->{keys} = \@keys;
    
        if ( my $delimiter = $pass->{conf}->{delimiter} ) {
            my @common_prefixes;
            my $strip_delim = qr/$delimiter$/;

            foreach my $node ( $xpc->findnodes(".//s3:CommonPrefixes") ) {
                my $prefix = $xpc->findvalue( ".//s3:Prefix", $node );

                # strip delimiter from end of prefix
                $prefix =~ s/$strip_delim//;

                push @common_prefixes, $prefix;
            }
            $return->{common_prefixes} = \@common_prefixes;
        }
    }
    
    $kernel->post(
        $pass->{sender},
        $pass->{event},
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub list_bucket_all {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = $conf->{bucket};
    croak 'must specify bucket' unless $bucket;
    
    # Fetch small chunks of 100 from list_bucket and combine them all together
    $conf->{'max-keys'} = $MAX_KEYS_PER_CHUNK;
    
    $kernel->yield( 
        list_bucket => 'list_bucket_all_chunk',
        {
            %{$conf},
            pass => [ $sender, $event, $conf, $LIST_ID++ ],
        },
    );
}

sub list_bucket_all_chunk {
    my ( $kernel, $self, $return, $response, $sender, $event, $conf, $id ) = @_[ KERNEL, OBJECT, ARG0 .. ARG5 ];

    if ( $return ) {
        if ( $self->{ "list_results_$id" } ) {
            push @{ $self->{ "list_results_$id" }->{keys} }, @{ $return->{keys} };
        }
        else {        
            $self->{ "list_results_$id" } = $return;
        }
        
        if ( $return->{is_truncated} ) {
            # Fetch the next chunk
            my $next_marker = $return->{next_marker} || $return->{keys}->[-1]->{key};
            $conf->{marker} = $next_marker;
            
            $kernel->yield( 
                list_bucket => 'list_bucket_all_chunk',
                {
                    %{$conf},
                    pass => [ $sender, $event, $conf, $id ],
                },
            );
            
            return;
        }
        else {
            # All done!
            $return = delete $self->{ "list_results_$id" };
            
            delete $return->{is_truncated};
            delete $return->{next_marker};
            delete $return->{max_keys};
        }
    }

    $kernel->post(
        $sender,
        $event,
        $return,
        $response,
        @{ $conf->{pass} || [] },
    );
}            

sub get_acl {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = delete $conf->{bucket};
    my $key    = delete $conf->{key} || '';
    
    croak 'must specify bucket' unless $bucket;
    # Key is optional
    
    my $request = $self->_make_request( GET => $self->_uri( $bucket, $key ) . '?acl' );
    
    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $conf->{pass} || [],
    };

    $kernel->post( ua => request => get_acl_done => $request, $pass );
}

sub get_acl_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];
    
    my $return = $self->_check_error( $response );
    
    if ( $return ) {
        $return = $self->_parse_acl( $response->content );
    }
    
    $kernel->post(
        $pass->{sender},
        $pass->{event},
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub get_key {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = delete $conf->{bucket};
    my $key    = delete $conf->{key};
    my $file   = delete $conf->{file};
    
    croak 'must specify bucket' unless $bucket;
    croak 'must specify key' unless $key;
    
    my $request = $self->_make_request( GET => $self->_uri( $bucket, $key ) );
    
    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        file   => $file,
        pass   => $conf->{pass} || [],
    };

    $kernel->post( 'ua-streaming' => request => get_key_done => $request, $pass );
}

sub get_key_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    my $request  = $req->[0];
    my $pass     = $req->[1];
    
    my $response = $res->[0];
    my $chunk    = $res->[1];
    
    if ( $chunk ) {
        if ( $pass->{file} && $response->code =~ /^2\d\d$/ ) {
            # Save chunks to file, only if response is good
            if ( !$request->{_fh} ) {
                open my $fh, '>', $pass->{file};
                $request->{_fh} = $fh;
            }
    
            syswrite $request->{_fh}, $chunk;
        }
        else {
            # Save chunks to response object
            $response->content( $response->content() . $chunk );
        }
    
        return;
    }
    else {
        # We're all done
        if ( $request->{_fh} ) {
            $request->{_fh}->close();
            delete $request->{_fh};
        }
    }
    
    my $return = $self->_check_error( $response );
    
    $kernel->post(
        $pass->{sender},
        $pass->{event},
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub delete_key {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = delete $conf->{bucket};
    my $key    = delete $conf->{key};
    
    croak 'must specify bucket' unless $bucket;
    croak 'must specify key' unless $key;
    
    my $request = $self->_make_request( DELETE => $self->_uri( $bucket, $key ) );

    # Save callback info
    my $pass = {
        sender => $sender,
        event  => $event,
        pass   => $conf->{pass} || [],
    };

    $kernel->post( ua => request => delete_key_done => $request, $pass );
}

sub delete_key_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];
    
    my $return = $self->_check_error( $response );

    $kernel->post(
        $pass->{sender}, 
        $pass->{event}, 
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub set_acl {
    my ( $kernel, $self, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
    
    my $bucket = $conf->{bucket};
    
    croak 'must specify bucket' unless $bucket;
    # Key is optional
    
    # set_acl requires that we first fetch the current ACL, so we can get owner information
    $kernel->yield( 
        get_acl => 'set_acl_got_current',
        {
            %{$conf},
            pass => [ $sender, $event, $conf ],
        },
    );
}

sub set_acl_got_current {
    my ( $kernel, $self, $return, $response, $sender, $event, $conf ) = @_[ KERNEL, OBJECT, ARG0 .. ARG4 ];    
    
    if ( $return ) {
        my $bucket    = delete $conf->{bucket};
        my $key       = delete $conf->{key} || '';
        my $acl       = delete $conf->{acl};
        my $acl_short = delete $conf->{acl_short};
    
        if ( $acl_short ) {
            $self->_validate_acl_short( $acl_short );
            $acl = $self->_construct_acl( $return, $acl_short );
        }
        else {
            $acl = $self->_construct_acl( $return, $acl );
        }
    
        my $request = $self->_make_request( PUT => $self->_uri( $bucket, $key ) . '?acl', {}, $acl );
    
        # Save callback info
        my $pass = {
            sender => $sender,
            event  => $event,
            pass   => $conf->{pass} || [],
        };

        $kernel->post( ua => request => set_acl_done => $request, $pass );
    }
    else {
        # Failed to get current ACL
        $kernel->post(
            $sender,
            $event,
            $return,
            $response,
            @{ $conf->{pass} || [] },
        );
    }
}

sub set_acl_done {
    my ( $kernel, $self, $req, $res ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    my $request  = $req->[0];
    my $pass     = $req->[1];
    my $response = $res->[0];
    
    my $return = $self->_check_error( $response );
    
    $kernel->post(
        $pass->{sender},
        $pass->{event},
        $return,
        $response,
        @{ $pass->{pass} },
    );
}

sub _add_auth_header {
    my ( $self, $headers, $method, $path ) = @_;
    my $aws_access_key_id     = $self->{aws_access_key_id};
    my $aws_secret_access_key = $self->{aws_secret_access_key};

    if ( not $headers->header('Date') ) {
        $headers->header( Date => time2str(time) );
    }
    my $canonical_string
        = $self->_canonical_string( $method, $path, $headers );
    my $encoded_canonical
        = $self->_encode( $aws_secret_access_key, $canonical_string );
    $headers->header(
        Authorization => "AWS $aws_access_key_id:$encoded_canonical" );
}

# generate a canonical string for the given parameters.  expires is optional and is
# only used by query string authentication.
sub _canonical_string {
    my ( $self, $method, $path, $headers, $expires ) = @_;
    my %interesting_headers = ();
    while ( my ( $key, $value ) = each %$headers ) {
        my $lk = lc $key;
        if (   $lk eq 'content-md5'
            or $lk eq 'content-type'
            or $lk eq 'date'
            or $lk =~ /^$AMAZON_HEADER_PREFIX/ )
        {
            $interesting_headers{$lk} = $self->_trim($value);
        }
    }

    # these keys get empty strings if they don't exist
    $interesting_headers{'content-type'} ||= '';
    $interesting_headers{'content-md5'}  ||= '';

    # just in case someone used this.  it's not necessary in this lib.
    $interesting_headers{'date'} = ''
        if $interesting_headers{'x-amz-date'};

    # if you're using expires for query string auth, then it trumps date
    # (and x-amz-date)
    $interesting_headers{'date'} = $expires if $expires;

    my $buf = "$method\n";
    foreach my $key ( sort keys %interesting_headers ) {
        if ( $key =~ /^$AMAZON_HEADER_PREFIX/ ) {
            $buf .= "$key:$interesting_headers{$key}\n";
        } else {
            $buf .= "$interesting_headers{$key}\n";
        }
    }

    # don't include anything after the first ? in the resource...
    $path =~ /^([^?]*)/;    
    $buf .= '/' . uri_escape( $1, "^A-Za-z0-9\-_.!~*'()/" );

    # ...unless there is an acl or torrent parameter
    if ( $path =~ /[&?]acl($|=|&)/ ) {
        $buf .= '?acl';
    } elsif ( $path =~ /[&?]torrent($|=|&)/ ) {
        $buf .= '?torrent';
    }

    return $buf;
}

# Generates the necessary ACL XML:
#   Given a string (canned ACL)
#   Given an array ref (list of grants)
sub _construct_acl {
    my ( $self, $current, $acl ) = @_;
    
    my $owner_perm = {
        display_name => $current->{owner_display_name},
        id           => $current->{owner_id},
        permission   => 'FULL_CONTROL',
    };

    my $canned = {
        private => [ 
            $owner_perm
        ],
        'public-read' => [
            $owner_perm,
            {
                URI        => 'http://acs.amazonaws.com/groups/global/AllUsers',
                permission => 'READ',
            },
        ],
        'public-read-write' => [
            $owner_perm,
            {
                URI        => 'http://acs.amazonaws.com/groups/global/AllUsers',
                permission => 'READ',
            },
            {
                URI        => 'http://acs.amazonaws.com/groups/global/AllUsers',
                permission => 'WRITE',
            },
        ],
        'authenticated-read' => [
            $owner_perm,
            {
                URI        => 'http://acs.amazonaws.com/groups/global/AuthenticatedUsers',
                permission => 'READ',
            },
        ],
    };
    
    # Always include the owner with full control
    if ( ref $acl ) {
        unshift @{$acl}, $owner_perm;
    }
    
    my $new_acl = {
        owner_display_name => $current->{owner_display_name},
        owner_id           => $current->{owner_id},
        grants             => ( ref $acl ) ? $acl : $canned->{$acl},
    };
    
    return $self->_acl_to_xml( $new_acl );
}

sub _acl_to_xml {
    my ( $self, $acl ) = @_;
    
    my $doc = $self->{libxml}->createDocument(
        'http://s3.amazonaws.com/doc/2006-03-01/',
        'AccessControlPolicy',
    );
    
    $doc->setEncoding('UTF-8');
    
    # Add Owner element
    my $id           = $doc->createElement('ID');
    my $display_name = $doc->createElement('DisplayName');
    
    $id->appendText( $acl->{owner_id} );
    $display_name->appendText( $acl->{owner_display_name} );
    
    my $owner = $doc->createElement('Owner');
    $owner->appendChild($id);
    $owner->appendChild($display_name);
    
    # Add AccessControlList element
    
    my $acl_list = $doc->createElement('AccessControlList');
    
    for my $grant ( @{ $acl->{grants} } ) {
        
        my $grantee = $doc->createElement('Grantee');
        $grantee->setAttribute( 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance' );
        
        # URI grant
        if ( $grant->{URI} ) {
            
            $grantee->setAttribute( 'xsi:type', 'Group' );
            
            my $uri = $doc->createElement('URI');
            $uri->appendText( $grant->{URI} );
            
            $grantee->appendChild($uri);
        }
        # Amazon email grant
        elsif ( $grant->{email} ) {
            
            $grantee->setAttribute( 'xsi:type', 'AmazonCustomerByEmail' );
            
            my $email = $doc->createElement('EmailAddress');
            $email->appendText( $grant->{email} );
            
            $grantee->appendChild($email);
        }
        # Single user grant
        else {
            
            $grantee->setAttribute( 'xsi:type', 'CanonicalUser' );
            
            my $grantee_id = $doc->createElement('ID');
            $grantee_id->appendText( $grant->{id} );
        
            my $grantee_name = $doc->createElement('DisplayName');
            $grantee_name->appendText( $grant->{display_name} );
            
            $grantee->appendChild($grantee_id);
            $grantee->appendChild($grantee_name);
        }
        
        my $perm = $doc->createElement('Permission');
        $perm->appendText( $grant->{permission} );
        
        my $grant_node = $doc->createElement('Grant');
        $grant_node->appendChild($grantee);
        $grant_node->appendChild($perm);
        
        $acl_list->appendChild($grant_node);
    }
    
    my $acl_node = $doc->documentElement();
    $acl_node->appendChild( $owner );
    $acl_node->appendChild( $acl_list );

    return $doc->toString();
}

sub _check_error {
    my ( $self, $response ) = @_;
    
    if ( $response->code =~ /^2\d\d$/ ) {
        return 1;
    }
    
    if ( $response->content ) {
        my $xpc = $self->_xpc_of_content( $response->content );

        if ( $xpc->findnodes('//Error') ) {
            $response->{s3_error} = {
                code    => $xpc->findvalue('//Error/Code'),
                message => $xpc->findvalue('//Error/Message'),
            };
        }
    }
    
    return 0;
}

# finds the hmac-sha1 hash of the canonical string and the aws secret access key and then
# base64 encodes the result (optionally urlencoding after that).
sub _encode {
    my ( $self, $aws_secret_access_key, $str, $urlencode ) = @_;
    my $hmac = Digest::HMAC_SHA1->new($aws_secret_access_key);
    $hmac->add($str);
    my $b64 = encode_base64( $hmac->digest, '' );
    if ($urlencode) {
        return $self->_urlencode($b64);
    } else {
        return $b64;
    }
}

# make the HTTP::Request object
sub _make_request {
    my ( $self, $method, $path, $headers, $data, $metadata ) = @_;
    croak 'must specify method' unless $method;
    croak 'must specify path'   unless defined $path;
    $headers  ||= {};
    $data     ||= '';
    $metadata ||= {};

    my $http_headers = $self->_merge_meta( $headers, $metadata );

    $self->_add_auth_header( $http_headers, $method, $path );
    my $protocol = $self->{secure} ? 'https' : 'http';
    my $url      = "$protocol://s3.amazonaws.com/$path";
    my $request  = HTTP::Request->new( $method, $url, $http_headers );
    $request->content($data);

    return $request;
}

# generates an HTTP::Headers objects given one hash that represents http
# headers to set and another hash that represents an object's metadata.
sub _merge_meta {
    my ( $self, $headers, $metadata ) = @_;
    $headers  ||= {};
    $metadata ||= {};

    my $http_header = HTTP::Headers->new;
    while ( my ( $k, $v ) = each %$headers ) {
        $http_header->header( $k => $v );
    }
    while ( my ( $k, $v ) = each %$metadata ) {
        $http_header->header( "$METADATA_PREFIX$k" => $v );
    }

    return $http_header;
}

sub _parse_acl {
    my $self = shift;
    
    my $xpc = $self->_xpc_of_content( shift );
    
    my @grants;

    for my $grant ( $xpc->findnodes(".//s3:Grant") ) {
        my $perm = {
            permission => $xpc->findvalue( ".//s3:Permission", $grant ),
        };
        
        if ( my $id = $xpc->findvalue( ".//s3:Grantee/s3:ID", $grant ) ) {
            $perm->{id}           = $id;
            $perm->{display_name} = $xpc->findvalue( ".//s3:Grantee/s3:DisplayName", $grant );
        }
        elsif ( my $uri = $xpc->findvalue( ".//s3:Grantee/s3:URI", $grant ) ) {
            $perm->{URI} = $uri;
        }
        elsif ( my $email = $xpc->findvalue( ".//s3:Grantee/s3:EmailAddress", $grant ) ) {
            $perm->{email} = $email;
        }
            
        push @grants, $perm;
    }
    
    my $acl = {
        owner_id           => $xpc->findvalue(".//s3:AccessControlPolicy/s3:Owner/s3:ID"),
        owner_display_name => $xpc->findvalue(".//s3:AccessControlPolicy/s3:Owner/s3:DisplayName"),
        grants             => \@grants,
    };
    
    return $acl;
}

sub _trim {
    my ( $self, $value ) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
}

sub _uri {
    my ( $self, $bucket, $key ) = @_;
    return ($key)
        ? $bucket . "/" . $self->_urlencode($key)
        : $bucket
    ;
}

sub _urlencode {
    my ( $self, $unencoded ) = @_;
    
    # original module did this, but it breaks for i.e. '.'
    # return uri_escape( $unencoded, '^A-Za-z0-9_-' );
    
    return uri_escape( $unencoded );
}

sub _validate_acl_short {
    my ( $self, $policy_name ) = @_;

    if ( ! grep( { $policy_name eq $_ }
        qw(private public-read public-read-write authenticated-read) ) ){
        croak "$policy_name is not a supported canned access policy";
    }
}

sub _xpc_of_content {
    my ( $self, $content ) = @_;
    my $doc = $self->{libxml}->parse_string($content);

    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs( 's3', 'http://s3.amazonaws.com/doc/2006-03-01/' );

    return $xpc;
}

1;      
__END__

=head1 NAME

POE::Component::Amazon::S3 - Work with Amazon S3 using POE

=head1 SYNOPSIS

    use POE qw(Component::Amazon::S3);
    
    POE::Component::Amazon::S3->spawn(
        alias                 => 's3',
        aws_access_key_id     => 'your S3 id',
        aws_secret_access_key => 'your S3 key',
    );
    
    ### Methods for working with buckets
    
    # List buckets, posts back to buckets_done with the result
    $kernel->post(
        s3 => 'buckets', 'buckets_done',
    );
    
    # Add a bucket
    $kernel->post(
        s3 => 'add_bucket', 'add_bucket_done',
        { 
            bucket => 'my-bucket',
        }
    );
    
    # Delete a bucket, must be empty of all keys
    $kernel->post(
        s3 => 'delete_bucket', 'delete_bucket_done',
        {
            bucket => 'my-bucket',
        }
    );
    
    # Set access control on a bucket, see below for more info about ACL
    $kernel->post(
        s3 => 'set_acl', 'set_acl_done',
        {
            bucket    => 'my-bucket',
            acl_short => 'public-read',
        }
    );
    
    # Get the access control list for a bucket
    $kernel->post(
        s3 => 'get_acl', 'get_acl_done',
        {
            bucket => 'my-bucket',
        }
    );
    
    ### Methods for working with keys
    
    # Add a key with inline data
    $kernel->post(
        s3 => 'add_key', 'add_key_done',
        {
            bucket => 'my-bucket,
            key    => 'my-inline-key',
            data   => 'testing 123',
        }
    );
    
    # Add a key with data from a file
    $kernel->post(
        s3 => 'add_key', 'add_key_done',
        {
            bucket => 'my-bucket,
            key    => 'my-file-key',
            file   => '/path/to/large_file',
        }
    );
    
    # List some keys, used for pagination
    $kernel->post(
        s3 => 'list_bucket', 'list_bucket_done',
        {
            bucket     => 'my-bucket',
            'max-keys' => 10,
        },
    );
    
    # List all keys, may make multiple calls internally to list_bucket
    $kernel->post(
        s3 => 'list_bucket_all', 'list_bucket_all_done',
        {
            bucket => 'my-bucket',
        },
    );
    
    # Get a key, saving the contents in memory
    $kernel->post(
        s3 => 'get_key', 'get_key_done',
        {
            bucket => 'my-bucket'
            key    => 'my-inline-key',
        },
    );
    
    # Get a key, saving directly to a file
    $kernel->post(
        s3 => 'get_key', 'get_key_done',
        {
            bucket => 'my-bucket'
            key    => 'my-file-key',
            file   => '/tmp/my-file-key',
        },
    );
    
    # Get only the headers for a key
    $kernel->post(
        s3 => 'head_key', 'head_key_done',
        {
            bucket => 'my-bucket',
            key    => 'my-inline-key',
        },
    );
    
    # Delete a key
    $kernel->post(
        s3 => 'delete_key', 'delete_key_done',
        {
            bucket => 'my-bucket',
            key    => 'my-inline-key',
        },
    );
    
    # Set access control on a key, see below for more info about ACL
    $kernel->post(
        s3 => 'set_acl', 'set_acl_done',
        {
            bucket    => 'my-bucket',
            key       => 'my-inline-key',
            acl_short => 'public-read',
        }
    );
    
    # Get the access control list for a key
    $kernel->post(
        s3 => 'get_acl', 'get_acl_done',
        {
            bucket => 'my-bucket',
            key    => 'my-inline-key',
        }
    );
    
    ### Return values
    
    # All methods post back to the given state with the same parameters,
    # return and response.  Example:
    
    sub add_bucket_done {
        my ( $kernel, $return, $response ) = @_[ KERNEL, ARG0, ARG1 ];
        
        # $return contains only the results of the call
        # $response contains the full HTTP::Response object from the call

        # See individual method documentation below for details on $return
    }

=head1 DESCRIPTION

POE::Component::Amazon::S3 is an asynchronous Amazon S3 client based loosely
on L<Net::Amazon::S3>.

Amazon provides an "infinite" Simple Storage Service (S3) where you may store
as much data as you like, paying only for the bandwidth and disk space used.
An S3 account may contain up to 100 "buckets", each of which may contain any
number of keys.  Each key can contain any data up to 5GB in size.

To find out more about S3, please visit: L<http://s3.amazonaws.com/>

=head1 CONSTRUCTOR / DESTRUCTOR

=head2 spawn

C<spawn> takes the following named parameters:

=over 4

=item alias => $alias

Optional.  Sets the alias to which you can post events.  This defaults to
's3' if not specified.

=item aws_access_key_id => $amazon_s3_id

Required.  Enter your Amazon ID which you receive after signing up for an S3
account.

=item aws_secret_access_key => $amazon_access_key

Required.  Enter your Amazon access key.

=item secure => 1

Optional.  If you'd like to communicate with S3 using SSL, set C<secure> to 1.
By default all communication is done over HTTP.  Enabling this option
requires the module L<POE::Component::SSLify>.

=back

=head2 shutdown

Shuts down the component and all subcomponents.

=head1 ACCEPTED EVENTS

All requests posted to Amazon::S3 take 2 parameters:

=over 4

=item EVENT

The name of an event in the calling session where responses will be sent.

=item OPTS

Required by most events, this is a hashref of various options.  All events
support an optional key C<pass> which takes an arrayref containing anything
to be passed-through to the response event.

=back

All responses sent back contain at least 2 parameters:

=over 4

=item RETURN VALUE (ARG0)

The return value from the event.  This may be a simple boolean value
indicating success or failure, a hashref of keys, etc.

=item RESPONSE OBJECT (ARG1)

The complete HTTP::Response object returned by the request.  If the return value
returned false, the Amazon S3 error information will be stored in 
$response->{s3_error}

=item PASS-THROUGH PARAMETERS

Anything sent in the C<pass> arrayref will be returned in ARG2, ARG3, etc.

=back

=head2 buckets

Retrieve a list of all buckets.

    $kernel->post(
        s3 => 'buckets',
        'buckets_done',
        {
            pass => [ @args ],
        }
    );

Returns 0 on failure and a hashref on success:

    {
        owner_id          => $owner_id,
        owner_displayname => $display_name,
        buckets           => [
            {
                bucket        => $bucket_name,
                creation_date => $date,
            },
            ...
        ]
    }

=head2 add_bucket

Add a new bucket.  Note that there is a limit of 100 buckets per account.

    $kernel->post( 
        s3 => 'add_bucket',
        'add_bucket_done',              # event where response is sent
        {
            bucket    => $bucket_name,  # new bucket to create
            acl_short => $canned_acl,   # optional ACL for bucket, see below
            pass      => [ @args ],     # optional items passed through to response event
        }
    );

Returns 1 on success and 0 on error.

=head2 delete_bucket

Delete a bucket.  The bucket must not contain any keys or the call will fail.

    $kernel->post(
        s3 => 'delete_bucket',
        'delete_bucket_done',
        {
            bucket => $bucket_name,     # bucket to delete
            pass   => [ @args ],        # optional pass-through items
        }
    );

Returns 1 on success and 0 on error.

=head2 add_key

Add a key to a bucket.  An unlimited number of keys can be added to any one bucket.
Each keky may contain any data up to 5GB in size.

    $kernel->post(
        s3 => 'add_key',
        'add_key_done',
        {
            bucket    => $bucket_name,  # bucket which will contain the new key
            key       => $key_name,     # new key
            acl_short => $canned_acl,   # optional ACL for bucket, see below
            pass      => [ @args ],     # optional pass-through items
            
            # The key's data can be set from either an in-memory variable or 
            # from a file on disk.  Using a disk file is highly recommended for
            # large items to save on memory usage.
            
            data      => $inline_data,
            file      => $file_path,
        }
    );

Returns 1 on success and 0 on error.

=head2 head_key

Retrieve only the HTTP headers associated with a key.

    $kernel->post(
        s3 => 'head_key',
        'head_key_done',
        {
            bucket => $bucket_name,
            key    => $key,
            pass   => [ @args ],
        }
    );

Returns 1 on success and 0 on error.

=head2 list_bucket

Retrieve a list of keys in a bucket.  This method is best used for paging
through many results.  If you simply want a list of all keys regardless of
how many there are, call list_bucket_all instead.

    $kernel->post(
        s3 => 'list_bucket',
        'list_bucket_done',
        {
            bucket     => $bucket_name,
            pass       => [ @args ],
            
            # These optional params are explained below.
            prefix     => $prefix,
            delimiter  => $delimiter,
            'max-keys' => $max_keys,
            marker     => $marker,
        }
    );

=over 4

=item prefix

If specified, restricts the response to only contain results that begin with
the specified prefix.

=item delimiter

If this optional, Unicode string parameter is included with your
request, then keys that contain the same string between the prefix
and the first occurrence of the C<delimiter> will be rolled up into a
single result element and returned in the C<common_prefixes> list. These
rolled-up keys are not returned elsewhere in the response.  For
example, with prefix="USA/" and delimiter="/", the matching keys
"USA/Oregon/Salem" and "USA/Oregon/Portland" would be summarized
in the response as a single "USA/Oregon" element in the C<common_prefixes>
list. If an otherwise matching key does not contain the delimiter after
the prefix, it appears in the normal list of keys.

Each element in the C<common_prefixes> list counts as one against
the C<max-keys> limit. The rolled-up keys represented by each C<common_prefixes>
element do not.  If the C<delimiter> parameter is not present in your
request, keys in the result set will not be rolled-up and neither
the C<common_prefixes> list nor the C<next_marker> element will be
present in the response.

=item max-keys 

This optional argument limits the number of results returned in
response to your query. Amazon S3 will return no more than this
number of results, but possibly less. Even if C<max-keys> is not
specified, Amazon S3 will limit the number of results in the response
(usually this limit is 1000 keys). Check the C<is_truncated> flag to see
if your results are incomplete.  If so, use the C<marker> parameter to
request the next page of results.  For the purpose of counting max-keys,
a 'result' is either a single key, or a delimited prefix in the
C<common_prefixes> list. So for delimiter requests, C<max-keys> limits
the total number of list results, not just the number of keys.

=item marker

This optional parameter enables pagination of large result sets.
C<marker> specifies where in the result set to resume listing.  It
restricts the response to only contain results that occur alphabetically
after the value of C<marker>.  To retrieve the next page of results,
use the last key from the current page of results as the C<marker> in
your next request.

See also C<next_marker>, below. 

If C<marker> is omitted, the first page of results is returned.  

=back

Returns 0 on error and a hashref of results on success:

    {
        bucket          => $bucket_name,
        prefix          => $bucket_prefix, 
        common_prefixes => [ $prefix1, $prefix2, ... ]
        marker          => $bucket_marker, 
        next_marker     => $bucket_next_available_marker,
        max_keys        => $bucket_max_keys,
        is_truncated    => $bucket_is_truncated_boolean
        keys            => [ $key1, $key2, ... ]
    }

=over 4

=item common_prefixes

If list_bucket was requested with a C<delimiter>, C<common_prefixes> will
contain a list of prefixes matching that delimiter.  Drill down into
these prefixes by making another request with the C<prefix> parameter.

=item next_marker 

A convenience element, useful when paginating with delimiters. The
value of C<next_marker>, if present, is the largest (alphabetically)
of all key names and all C<common_prefixes> in the response.
If the C<is_truncated> flag is set, request the next page of results
by setting C<marker> to the value of C<next_marker>. This element
is only present in the response if the C<delimiter> parameter was
sent with the request.

=item is_truncated

This flag indicates whether or not all results of your query were
returned in this response.  If your results were truncated, you can
make a follow-up paginated request using the C<marker> parameter to
retrieve the rest of the results.

=back

=head2 list_bucket_all

Retrieve a list of all keys in a bucket.  This may make multiple requests
to list_bucket behind the scenes.

    $kernel->post(
        s3 => 'list_bucket_all',
        'list_bucket_all_done',
        {
            bucket => $bucket_name,
            pass   => [ @args ],
        }
    );

Returns 0 on error and a hashref of results on success.  This hashref is the
same as the one returned by list_bucket.

=head2 get_key

Retrieve a single key, optionally saving the key's data directly to a file.

    $kernel->post(
        s3 => 'get_key',
        'get_key_done',
        {
            bucket => $bucket_name,
            key    => $key_name,
            file   => $save_path,   # if specified, the key's content is saved
                                    # directly to this file.
            pass   => [ @args ],
        }
    );

Returns 1 on success and 0 on error.  If a file param was not specified, the key's
content will be in $response->content().

=head2 delete_key

Delete a single key.  WARNING: There is no way to recover a deleted key.

    $kernel->post(
        s3 => 'delete_key',
        'delete_key_done',
        {
            bucket => $bucket_name,
            key    => $key_name,
            pass   => [ @args ],
        }
    );

Returns 1 on success and 0 on error.

=head1 ACCESS CONTROL LISTS

Every bucket and key in S3 has an access control list.  This module provides full
support for setting and getting ACLs.  For a full explanation of S3's ACLs, please read
the technical documentation at L<http://s3.amazonaws.com/>

As mentioned above, the C<add_bucket> and C<add_key> events accept an optional C<acl_short>
parameter to set their ACL at the time of creation so C<set_acl> does not need to be called.

=head2 set_acl

Set a new ACL on a bucket or key.  An ACL may be specified as either one of four
standard ACLs, or as a detailed list of users/groups and permissions.

The four canned ACLs you may use with the C<acl_short> param are:

=over 4

=item private

Only the creator of the bucket/key has access.

=item public-read

Anyone may read the bucket/key.  If set on a key, it may be downloaded
using a standard HTTP GET.  This ACL is often used for storing static
website content in S3.

=item public-read-write

Anyone may read and overwrite the bucket/key.

=item authenticated-read

Any other authenticated S3 user may read the bucket/key.

=back

Example using a canned ACL:

    $kernel->post(
        s3 => 'set_acl',
        'set_acl_done',
        {
            bucket    => $bucket_name,
            key       => $key_name,        # optional
            acl_short => 'public-read',
            pass      => [ @args ],
        }
    );

ACLs may also be specified as a full list of users and/or groups, and their
permissions.  You should read the S3 documentation before using this method
for setting ACLs.

    my $acl = [
        # grant WRITE to another S3 user
        {
            display_name => $other_name,
            id           => $other_id,
            permission   => 'WRITE',
        },
        
        # grant READ to all users (same as public-read)
        {
            URI        => 'http://acs.amazonaws.com/groups/global/AllUsers',
            permission => 'READ',
        },
        
        # grant READ to a user with a valid Amazon email account
        {
            email      => $email_address,
            permission => 'READ',
        },
    ];
    
    $kernel->post(
        s3 => 'set_acl',
        'set_acl_done',
        {
            bucket => $bucket_name,
            key    => $key_name,        # optional
            acl    => $acl,
            pass   => [ @args ],
        }
    );

Returns 1 on success and 0 on error.

=head2 get_acl

Retrieve the full ACL list for a bucket or key.

    $kernel->post(
        s3 => 'get_acl',
        'get_acl_done',
        {
            bucket => $bucket_name,
            key    => $key_name,        # optional
            pass   => [ @args ],
        }
    );

Returns an arrayref containing a list of grants on the bucket or key, or 0 on error.

=head1 ERROR HANDLING

The $return value will be false (0) if an error occurred.  If an error occurred, the
$response object will contain an additional key, C<s3_error>, which is a hashref of
the error response.  Example:

    # $response->{s3_error} contains:
    {
        code    => 'NoSuchKey',
        message => 'The resource you requested does not exist',
    }

For a full list of possible error codes, please see
L<http://docs.amazonwebservices.com/AmazonS3/2006-03-01/ErrorCodeList.html>

=head1 TESTING

This module will skip all tests unless a few environment variables are set.  Running
tests will cost you a very small bit in bandwidth charges.  If any tests fail, some buckets
and/or keys may not be cleaned up properly, so you should check with a tool like the
S3 Firefox Organizer to make sure they are not costing you storage money.

=over 4

=item AMZ_S3_ID

Set to your Amazon S3 ID.

=item AMZ_S3_KEY

Set to your Amazon S3 Key.

=item AMZ_S3_STRESS

Optional.  Set if you want to run the larger stress test that creates 150 keys.

=back

=head1 THANKS

The authors of L<Net::Amazon::S3>, from which much code was borrowed:

Leon Brocard <acme@astray.com>

Brad Fitzpatrick <brad@danga.com>

=head1 AUTHOR

Andy Grundman <andy@hybridized.org>

=head1 SEE ALSO

L<Net::Amazon::S3>

S3 Firefox Organizer, provides an FTP-like interface - L<https://addons.mozilla.org/firefox/3247/>

=head1 NOTICE

This module contains code modified from Amazon that contains the
following notice:

    This software code is made available "AS IS" without warranties of any
    kind.  You may copy, display, modify and redistribute the software
    code either by itself or as incorporated into your code; provided that
    you do not remove any proprietary notices.  Your use of this software
    code is at your own risk and you waive any claim against Amazon
    Digital Services, Inc. or its affiliates with respect to your use of
    this software code. (c) 2006 Amazon Digital Services, Inc. or its
    affiliates.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
