package Net::Azure::StorageClient::Blob;
use base qw/Net::Azure::StorageClient/;
use strict;
use warnings;
{
  $Net::Azure::StorageClient::Blob::VERSION = '0.92';
}
use File::Spec;
use XML::Simple;
use Digest::MD5;
use Encode;
use File::Basename;

sub init {
    my $blobService = shift;
    my %args = @_;
    $blobService->SUPER::init( @_ );
    my $container_name = $args{ container_name };
    if ( $container_name ) {
        $container_name =~ s!/!!g;
        $blobService->{ container_name } = $container_name;
    }
    $blobService->{ type } = 'blob';
    return $blobService;
}

sub list_containers {
    my $blobService = shift;
    my ( $params ) = @_;
    return $blobService->list( '', $params );
}

sub set_blob_service_properties {
    my $blobService = shift;
    my ( $params ) = @_;
    my $prop = $blobService->get_blob_service_properties( $params );
    if ( $prop->code != 200 ) {
        return $prop;
    }
    my $result = $prop->content;
    my $xml = XML::Simple->new;
    my $list = $xml->XMLin( $result );
    my $properties = $params->{ StorageServicePropertie };
    my @properties_Logging = qw/ Version Delete Write Read /;
    my @properties_Metrics = qw/ Version Enabled IncludeAPIs /;
    for my $prop( @properties_Logging ) {
        $properties->{ Logging }->{ $prop } = $list->{ Logging }->{ $prop }
            if ( (! $properties->{ Logging }->{ $prop } )
            && ( $list->{ Logging }->{ $prop } ) );
    }
    $properties->{ Logging }->{ 'RetentionPolicy' } = $list->{ Logging }->{ RetentionPolicy }
        unless  $properties->{ Logging }->{ RetentionPolicy } && $list->{ Logging }->{ RetentionPolicy };
    for my $prop( @properties_Metrics ) {
        $properties->{ Metrics }->{ $prop } = $list->{ Metrics }->{ $prop }
            if ( (! $properties->{ Metrics }->{ $prop } )
            && ( $list->{ Metrics }->{ $prop } ) );
    }
    $properties->{ Metrics }->{ 'RetentionPolicy' } = $list->{ Metrics }->{ RetentionPolicy }
        unless  $properties->{ Metrics }->{ RetentionPolicy } && $list->{ Metrics }->{ RetentionPolicy };
    my $DefaultServiceVersion;
    if (! $properties->{ DefaultServiceVersion } ) {
        $properties->{ DefaultServiceVersion } = $list->{ DefaultServiceVersion }
            if $list->{ DefaultServiceVersion };
    }
    my $body = $xml->XMLout( $properties, NoAttr => 1, RootName => 'StorageServiceProperties' );
    $body = '<?xml version="1.0" encoding="utf-8"?>' . "\n${body}";
    my $data = '?restype=service&comp=properties';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $params->{ body } = $body;
    return $blobService->put( $data, $params );
}

sub get_blob_service_properties {
    my $blobService = shift;
    my ( $params ) = @_;
    my $data = '?restype=service&comp=properties';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    return $blobService->get( $data, $params );
}

sub create_container {
    my $blobService = shift;
    my ( $name, $params ) = @_;
    $name =~ s!^/!!;
    my $data = 'restype=container';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    my $path = "${name}?${data}";
    if ( my $public_access = $params->{ public_access } ) {
        if ( $public_access !~ /^blob|container$/ ) {
            $public_access = 'container';
        }
        $params->{ headers }->{ 'x-ms-blob-public-access' } = $public_access;
    }
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub get_container_properties {
    my $blobService = shift;
    return $blobService->get_properties( @_ );
}

sub get_container_metadata {
    my $blobService = shift;
    return $blobService->get_metadata( @_ );
}

sub set_container_metadata {
    my $blobService = shift;
    return $blobService->set_metadata( @_ );
}

sub get_container_acl {
    my $blobService = shift;
    my ( $name, $params ) = @_;
    $name =~ s!^/!!;
    $name .= '?restype=container&comp=acl';
    my $options = $params->{ options };
    $name .= '&' . $options if $options;
    return $blobService->get( $name, $params );
}

sub set_container_acl {
    my $blobService = shift;
    my ( $name, $params ) = @_;
    $name =~ s!^/!!;
    $name .= '?restype=container&comp=acl';
    my $options = $params->{ options };
    $name .= '&' . $options if $options; # timeout=n
    if ( my $public_access = $params->{ public_access } ) {
        if ( $public_access !~ /^blob|container$/ ) {
            $public_access = 'container';
        }
        $params->{ headers }->{ 'x-ms-blob-public-access' } = $public_access;
    }
    my $Permission = $params->{ Permission } || 'rwdl';
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( time );
    my $ts = sprintf( "%04d-%02d-%02d", $year + 1900, $mon + 1, $mday );
    my $id = $blobService->_signed_identifier( 64 );
    my $SignedIdentifiers = { SignedIdentifier => { Id => $id,
                              AccessPolicy => { Start => $ts,
                                                Expiry => $ts,
                                                Permission => $Permission }, }, };
    my $xml = XML::Simple->new;
    my $body = $xml->XMLout( $SignedIdentifiers, NoAttr => 1, RootName => 'SignedIdentifiers' );
    $body = '<?xml version="1.0" encoding="utf-8"?>' . "\n${body}";
    $params->{ body } = $body;
    return $blobService->put( $name, $params );
}

sub delete_container {
    my $blobService = shift;
    my ( $name, $params ) = @_;
    $name =~ s!^/!!;
    my $data = 'restype=container';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    my $path = "${name}?${data}";
    return $blobService->delete( $path, $params );
}

sub lease_container {
    my $blobService = shift;
    return $blobService->lease( @_ );
}

sub list_blobs {
    my $blobService = shift;
    if ( wantarray ) {
        my @blobs = $blobService->list( @_ );
        return @blobs;
    }
    my $blobs = $blobService->list( @_ );
    return $blobs;
}

sub put_blob {
    my $blobService = shift;
    return $blobService->_put( @_ );
}

sub get_blob {
    my $blobService = shift;
    return $blobService->_get( @_ );
}

sub get_blob_properties {
    my $blobService = shift;
    return $blobService->get_properties( @_ );
}

sub set_blob_properties {
    my $blobService = shift;
    return $blobService->set_properties( @_ );
}

sub get_blob_metadata {
    my $blobService = shift;
    return $blobService->get_metadata( @_ );
}

sub set_blob_metadata {
    my $blobService = shift;
    return $blobService->set_metadata( @_ );
}

sub snapshot_blob {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=snapshot';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub copy_blob {
    my $blobService = shift;
    my ( $src, $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    $src = $blobService->_adjust_path( $src );
    my $data = '';
    my $account = $blobService->{ account_name };
    my $protocol = $blobService->{ protocol };
    my $type = lc( $blobService->{ type } );
    my $options = $params->{ options };
    $path .= '?' . $options if $options;
    $data .= '?' . $options if $options;
    my $url = "${protocol}://${account}.${type}.core.windows.net/${src}";
    $params->{ headers }->{ 'x-ms-copy-source' } = $url;
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub abort_copy_blob {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=copy&copyid=' . $params->{ copyid };
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub delete_blob {
    my $blobService = shift;
    return $blobService->remove( @_ );
}

sub lease_blob {
    my $blobService = shift;
    return $blobService->lease( @_ );
}

sub put_block {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=block&blockid=id' . $params->{ blockid };
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub put_block_list {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=blocklist';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    my $BlockList = $params->{ BlockList };
    my $xml = XML::Simple->new;
    my $body = $xml->XMLout( $BlockList, NoAttr => 1, RootName => 'BlockList' );
    $body = '<?xml version="1.0" encoding="utf-8"?>' . "\n${body}";
    $params->{ body } = $body;
    return $blobService->put( $path, $params );
}

sub get_block_list {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=blocklist';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    return $blobService->get( $path, $params );
}

sub put_page {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=page';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    my $page_write = $params->{ 'page-write' };
    my $range = $params->{ 'range' };
    $params->{ headers }->{ 'x-ms-page-write' } = $page_write if $page_write;
    $params->{ headers }->{ 'x-ms-range' } = $range if $range;
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub get_page_ranges {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=pagelist';
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    return $blobService->get( $path, $params );
}

sub rename_blob {
    my $blobService = shift;
    my ( $src, $path, $params ) = @_;
    my $res = $blobService->copy_blob( $src, $path, $params );
    $blobService->remove( $src );
    return $res;
}

sub download_container {
    my $blobService = shift;
    my ( $path, $dirname, $params ) = @_;
    if ( $path !~ m!/$! ) {
        $path .= '/';
    }
    $params->{ directory } = 1;
    return $blobService->download( $path, $dirname, $params );
}

sub download_blob {
    my $blobService = shift;
    return $blobService->download( @_ );
}

sub download {
    my $blobService = shift;
    my ( $path, $filename, $params ) = @_;
    my $dir_info = '';
    if ( $params->{ directory } || $path =~ m!/$! ) {
        $dir_info = $blobService->_get_directory_info( $path, $filename, $params );
    }
    if ( $dir_info ) {
        # Download blobs of directory
        my $excludes = $params->{ excludes } || $params->{ exclude };
        my $container_name = $dir_info->{ container_name };
        my $path = $dir_info->{ path };
        my $blobs = $dir_info->{ blobs };
        my $files = $dir_info->{ files };
        my $download_items;
        my @removed_items;
        my @removed;
        my $prefix = quotemeta( $path );
        my $base = quotemeta( $filename );
        require HTTP::Date;
        my @_blobs;
        for my $blob ( @$blobs ) {
            my $name = $blob->{ Name };
            if ( my $meta = $blob->{ Metadata } ) {
                if ( my $original = $meta->{ Path } ) {
                    $name = $original;
                }
            }
            Encode::_utf8_off( $name );
            next if $prefix && ( $name !~ /^$prefix/ );
            if ( $excludes ) {
                my $exclusion;
                for my $check ( @$excludes ) {
                    my $search = quotemeta( $check );
                    if ( $name =~ m/$search/ ) {
                        $exclusion = 1;
                        last;
                    }
                }
                next if $exclusion;
            }
            my $real_name = $name;
            $real_name =~ s/^$prefix// if $prefix;
            next if _basename( $real_name, '/' ) eq '$$$.$$$';
            push ( @_blobs, $real_name );
            my $not_modified;
            my $rel_path = $name;
            $rel_path =~ s/^$path// if $path;
            my $file = File::Spec->catfile( $filename, $rel_path );
            $file =~ s!/!\\!g if ( $^O eq 'MSWin32' );
            my $q = quotemeta( $file );
            if ( grep( /^$q$/, @$files ) ) {
                if ( $params->{ conditional } || $params->{ sync } ) {
                    if ( -f $file ) {
                        my $etag;
                        if ( my $meta = $blob->{ Metadata } ) {
                            $etag = $meta->{ Etag };
                        }
                        if ( $etag ) {
                            my $data = '';
                            open my $fh, "<$file" or die "Can't open '$file'.";
                            binmode $fh;
                            while ( read $fh, my ( $chunk ), 8192 ) {
                                $data .= $chunk;
                            }
                            close $fh;
                            my $comp = Digest::MD5::md5_hex( $data );
                            if ( $comp eq $etag ) {
                                $not_modified = 1;
                            }
                        } else {
                            my $mtime = $blobService->_get_mtime( $blob );
                            my @stats = stat $file;
                            if ( $stats[ 9 ] >= $mtime ) {
                                $not_modified = 1;
                            }
                        }
                    }
                }
            }
            $download_items->{ $blob->{ Name } } = $file unless $not_modified;
        }
        for my $item ( @$files ) {
            my $rel_path = $item;
            $rel_path =~ s!\\!/!g if ( $^O eq 'MSWin32' );
            $rel_path =~ s/^$base//;
            $rel_path = quotemeta( $rel_path );
            if (! grep( /^$rel_path$/, @_blobs ) ) {
                push ( @removed_items, $item );
            }
        }
        my @responses;
        if ( my $thread = $params->{ use_thread } ) {
            require Net::Azure::StorageClient::Blob::Thread;
            @responses = Net::Azure::StorageClient::Blob::Thread::download_use_thread(
              $blobService, 
            { download_items => $download_items,
              params => $params,
              container_name => $container_name,
              thread => $thread } );
        } else {
            for my $key ( keys %$download_items ) {
                $params->{ force } = 1;
                my $item;
                if ( $blobService->{ container_name } ) {
                    $item = $key;
                } else {
                    $item = $container_name . '/' . $key;
                }
                $params->{ directory } = undef;
                my $res = $blobService->download( $item,
                                                  $download_items->{ $key },
                                                  $params );
                push ( @responses, $res );
            }
        }
        if ( $params->{ sync } ) {
            my $not_remove = $params->{ not_remove };
            for my $remove( @removed_items ) {
                if ( $not_remove ) {
                    my $exclusion;
                    for my $check ( @$not_remove ) {
                        my $search = quotemeta( $check );
                        if ( $remove =~ m/$search/ ) {
                            $exclusion = 1;
                            last;
                        }
                    }
                    next if $exclusion;
                }
                if ( unlink $remove ) {
                    push ( @removed, $remove );
                }
            }
        }
        if ( $params->{ sync } ) {
            my $response = { responses => \@responses,
                             removed_files => \@removed };
            return $response;
        }
        return \@responses if @responses;
        return undef;
    }
    $params->{ filename } = $filename;
    return $blobService->_get( $path, $params );
}

sub upload_container {
    my $blobService = shift;
    my ( $path, $dirname, $params ) = @_;
    if ( $path !~ m!/$! ) {
        $path .= '/';
    }
    return $blobService->upload( $path, $dirname, $params );
}

sub upload_blob {
    my $blobService = shift;
    return $blobService->upload( @_ );
}

sub upload {
    my $blobService = shift;
    my ( $path, $filename, $params ) = @_;
    my $dir_info = '';
    if ( $params->{ directory } || $path =~ m!/$! ) {
        $dir_info = $blobService->_get_directory_info( $path, $filename, $params );
    }
    if ( $dir_info ) {
        # Upload files of directory
        my $excludes = $params->{ excludes } || $params->{ exclude };
        my $container_name = $dir_info->{ container_name };
        my $path = $dir_info->{ path };
        my $blobs = $dir_info->{ blobs };
        my $files = $dir_info->{ files };
        my @upload_items;
        my @not_modified_items;
        my @removed_items;
        my $prefix = quotemeta( $path );
        my $search_dir = quotemeta( $filename );
        if ( $params->{ conditional } || $params->{ sync } ) {
            for my $blob ( @$blobs ) {
                my $name = $blob->{ Name };
                if ( my $meta = $blob->{ Metadata } ) {
                    if ( my $original = $meta->{ Path } ) {
                        $name = $original;
                    }
                }
                next if ( _basename( $name, '/' ) eq '$$$.$$$' );
                next if $prefix && ( $name !~ /^$prefix/ );
                my $real_name = $name;
                $real_name =~ s/$prefix// if $prefix;
                my $file = File::Spec->catfile( $filename, $real_name );
                $file =~ s!/!\\!g if ( $^O eq 'MSWin32' );
                my $q = quotemeta( $file );
                if ( grep( /^$q$/, @$files ) || ( -f $file ) ) {
                    if ( -f $file ) {
                        my $etag;
                        if ( my $meta = $blob->{ Metadata } ) {
                            $etag = $meta->{ Etag };
                        }
                        if ( $etag ) {
                            my $data = '';
                            open my $fh, "<$file" or die "Can't open '$file'.";
                            binmode $fh;
                            while ( read $fh, my ( $chunk ), 8192 ) {
                                $data .= $chunk;
                            }
                            close $fh;
                            $params->{ contents }->{ $filename } = $data;
                            my $comp = Digest::MD5::md5_hex( $data );
                            if ( $comp eq $etag ) {
                                push ( @not_modified_items, _encode_path( $file ) );
                            }
                        } else {
                            my $mtime = $blobService->_get_mtime( $blob );
                            my @stats = stat $file;
                            push ( @not_modified_items, $file )
                                if ( $stats[ 9 ] <= $mtime );
                        }
                    }
                } else {
                    push ( @removed_items, $name ) if ( $params->{ sync } );
                }
            }
            for my $item ( @$files ) {
                my $q = quotemeta( _encode_path( $item ) );
                if (! grep( /^$q$/, @not_modified_items ) ) {
                    push ( @upload_items, $item );
                }
            }
        } else {
            @upload_items = @$files;
        }
        my @responses;
        my $uploads;
        for my $file ( @upload_items ) {
            if ( $excludes ) {
                my $exclusion;
                for my $check ( @$excludes ) {
                    my $search = quotemeta( $check );
                    if ( $file =~ m/$search/ ) {
                        $exclusion = 1;
                        last;
                    }
                }
                next if $exclusion;
            }
            my $item = $file;
            $item =~ s/^$search_dir//;
            if ( $blobService->{ container_name } ) {
                $item = $path . $item;
            } else {
                $item = $container_name . '/' . $path . $item;
            }
            if ( $params->{ use_thread } ) {
                $uploads->{ $item } = $file;
            } else {
                $params->{ force } = 1;
                my $res = $blobService->upload( $item, $file, $params );
                push ( @responses, $res );
            }
        }
        if ( my $thread = $params->{ use_thread } ) {
            require Net::Azure::StorageClient::Blob::Thread;
            @responses = Net::Azure::StorageClient::Blob::Thread::upload_use_thread(
              $blobService, 
            { upload_items => $uploads,
              params => $params,
              thread => $thread } );
        }
        if ( $params->{ sync } ) {
            my $not_remove = $params->{ not_remove };
            for my $item ( @removed_items ) {
                if (! $blobService->{ container_name } ) {
                    $item = $container_name . '/' . $item;
                }
                if ( $not_remove ) {
                    my $exclusion;
                    for my $check ( @$not_remove ) {
                        my $search = quotemeta( $check );
                        if ( $item =~ m/$search/ ) {
                            $exclusion = 1;
                            last;
                        }
                    }
                    next if $exclusion;
                }
                my $res = $blobService->remove( $item, $params );
                push ( @responses, $res );
            }
         }
        return \@responses if @responses;
        return undef;
    }
    $params->{ filename } = $filename;
    return $blobService->_put( $path, $params );
}

sub sync {
    my $blobService = shift;
    my ( $path, $directory, $params ) = @_;
    if ( $path !~ m!/$! ) {
        $path .= '/';
    }
    my $separator = $^O eq 'MSWin32' ? '\\' : '/';
    if ( $directory !~ m!$separator$! ) {
        $directory .= $separator;
    }
    my $direction = $params->{ direction } || 'upload';
    $params->{ conditional } = 1;
    $params->{ sync } = 1;
    $params->{ directory } = 1;
    return $blobService->$direction( $path, $directory, $params );
}

sub list {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = '' unless $path;
    $path =~ s!^/!!;
    if ( $path ) {
        $path .= '?restype=container&comp=list'; # &maxresults=n
    } else {
        $path .= '?comp=list';
    }
    my $options = $params->{ options };
    $path .= '&' . $options if $options;
    my $res = $blobService->get( $path, $params );
    my @responses;
    push ( @responses, $res );
    if ( $res->code != 200 ) {
        return $res unless wantarray;
        return \@responses;
    }
    my $marker;
    my $xml = XML::Simple->new;
    my $data = $res->content;
    my $list = $xml->XMLin( $data );
    $marker = $list->{ NextMarker };
    $marker = undef if ( ( ref $marker ) eq 'HASH' );
    if (! $marker ) {
        return $res unless wantarray;
    } else {
        while ( $marker ) {
            $marker =~ s!([^a-zA-Z0-9_.~-])!uc sprintf "%%%02x", ord($1)!eg;
            my $next = $path . '&marker=' . $marker;
            my $res = $blobService->get( $next, $params );
            if ( $res->code != 200 ) {
                return @responses if wantarray;
                return \@responses;
            }
            push ( @responses, $res );
            my $xml = XML::Simple->new;
            my $data = $res->content;
            my $n_list = $xml->XMLin( $data );
            $marker = $n_list->{ NextMarker };
            $marker = undef if ( ( ref $marker ) eq 'HASH' );
        }
    }
    return @responses if wantarray;
    return \@responses;
}

sub get_metadata {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $params->{ 'method' } = 'HEAD';
    my $options = $params->{ options } || '';
    $options .= '&' if $options;
    $options .= 'comp=metadata';
    $params->{ options } = $options;
    return $blobService->_get( $path, $params );
}

sub get_properties {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $params->{ 'method' } = 'HEAD';
    return $blobService->_get( $path, $params );
}

sub set_properties {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $options .= 'comp=properties';
    $options .= '&' . $params->{ options } if $params->{ options };
    $params->{ options } = $options;
    my $properties = $params->{ properties };
    for my $key ( keys %$properties ) {
        my $property = $key;
        if ( $key !~ m/^x\-ms\-/ ) {
            $property = 'x-ms-' . $property;
        }
        $params->{ headers }->{ $property } = $properties->{ $property };
    }
    $params->{ body } = $options;
    return $blobService->put( $path, $params );
}

sub set_metadata {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=metadata';
    if ( $path !~ m!/! ) {
        $data = 'restype=container&' . $data;
    }
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    my $metadata = $params->{ metadata };
    for my $key ( keys %$metadata ) {
        my $meta = $key;
        if ( $key !~ m/^x\-ms\-meta\-/ ) {
            $meta = 'x-ms-meta-' . $meta;
        }
        $params->{ headers }->{ $meta } = $metadata->{ $key };
    }
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub remove {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    if ( $path =~ /\%/ ) {
        $path = _encode_path( $path, '/' );
    }
    if ( $path !~ m!/! ) {
        return $blobService->delete_container( $path, $params );
    }
    my $options = $params->{ options };
    $path .= '?' . $options if $options;
    return $blobService->delete( $path, $params );
}

sub lease {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    my $data = 'comp=lease';
    if ( $path !~ m!/! ) {
        $data = 'restype=container&' . $data;
    }
    my $options = $params->{ options };
    $data .= '&' . $options if $options;
    $path = "${path}?${data}";
    my $lease_parameters = $params->{ lease_parameters };
    for my $key ( keys %$lease_parameters ) {
        my $parameter = $key;
        if ( $key !~ m/^x\-ms\-/ ) {
            $parameter = 'x-ms-' . $parameter;
        }
        $params->{ headers }->{ $parameter } = $lease_parameters->{ $key };
    }
    $params->{ body } = $data;
    return $blobService->put( $path, $params );
}

sub _get {
    my $blobService = shift;
    my ( $path, $params ) = @_;
    my $orig_path = $path;
    $path = $blobService->_adjust_path( $path );
    my $filename;
    if ( $params && $params->{ filename } ) {
        $filename = $params->{ filename };
    }
    if ( $filename && ( $params->{ conditional } || $params->{ sync } ) ) {
        if (! $params->{ force } ) {
            $params->{ compare } = 'from';
            my $metadata = $blobService->_do_conditional( $orig_path, $filename, $params );
            return $metadata if $metadata;
        }
    }
    my $method = $params->{ 'method' };
    my $separator = '?';
    if ( ( $path !~ m!/! ) && ( $method && ( $method eq 'HEAD' ) ) ) {
        $path .= '?restype=container';
        $separator = '&';
    }
    $method = 'GET' unless $method;
    my $options = $params->{ options };
    $path .= $separator . $options if $options;
    $params->{ 'method' } = $method;
    if ( $path =~ /\%/ ) {
        $path = _encode_path( $path, '/' );
    }
    my $res = $blobService->request( $method, $path, $params );
    if ( $filename ) {
        if ( $res->code == 200 ) {
            my $content = $res->content;
            my $dir = File::Basename::dirname( $filename );
            if (! -d $dir ) {
                require File::Path;
                File::Path::mkpath( $dir );
            }
            if ( -d $dir ) {
                open my $fh, ">$filename" or die "Can't open '$filename'.";
                print $fh $content;
                close $fh ;
                if ( $params->{ conditional } || $params->{ sync } ) {
                    require HTTP::Date;
                    my $mtime;
                    if( $res->headers->{ 'x-ms-meta-mtime' } ) {
                        $mtime = $res->headers->{ 'x-ms-meta-mtime' };
                    } else {
                        $mtime = $res->headers->{ 'last-modified' };
                        $mtime = HTTP::Date::str2time( $mtime );
                    }
                    if ( -f $filename ) {
                        my @stat = stat $filename;
                        my $atime = $stat[ 8 ];
                        utime $atime, $mtime, $filename;
                    }
                }
            }
        }
    }
    return $res;
}

sub _put {
    my $blobService = shift;
    my ( $path, $data, $params ) = @_;
    my $orig_path = $path;
    if ( ref $data eq 'HASH' ) {
        $params = $data;
    }
    $path = $blobService->_adjust_path( $path );
    my $filename = $params->{ filename };
    my $options = $params->{ options };
    $path .= '&' . $options if $options;
    my $blob_type = $params->{ blob_type } || 'BlockBlob';
    $params->{ headers }->{ 'x-ms-blob-type' } = $blob_type;
    if (! $params->{ no_metadata } ) {
        my $mimetype = $params->{ 'content-type' };
        if (! $mimetype ) {
            require Net::Azure::StorageClient::MIMEType;
            $mimetype = Net::Azure::StorageClient::MIMEType::get_mimetype( $path );
        }
        $params->{ headers }->{ 'content-type' } = $mimetype;
    }
    if ( $filename ) {
        $data = '';
        if ( -d $filename ) {
            $filename = File::Spec->catfile( $filename, _basename( $path, '/' ) );
        }
        if ( $params->{ contents } && $params->{ contents }->{ $filename } ) {
            $data = $params->{ contents }->{ $filename };
        } else {
            open my $fh, "<$filename" or die "Can't open '$filename'.";
            binmode $fh;
            while ( read $fh, my ( $chunk ), 8192 ) {
                $data .= $chunk;
            }
            close $fh;
        }
        if ( $params->{ conditional } || $params->{ sync } ) {
            if (! $params->{ force } ) {
                $params->{ compare } = 'to';
                $params->{ content } = $data;
                my $metadata = $blobService->_do_conditional( $orig_path, $filename, $params );
                return $metadata if $metadata;
            }
        }
        if ( -f $filename ) {
            my @stats = stat $filename;
            if (! $params->{ no_metadata } ) {
                $params->{ headers }->{ 'x-ms-meta-mtime' } = $stats[ 9 ];
                $params->{ headers }->{ 'x-ms-meta-mode' } = sprintf( '%o', $stats[ 2 ] ); # oct()
                $params->{ headers }->{ 'x-ms-meta-uid' } = $stats[ 4 ];
                $params->{ headers }->{ 'x-ms-meta-gid' } = $stats[ 5 ];
                my $etag = Digest::MD5::md5_hex( $data );
                $params->{ headers }->{ 'x-ms-meta-etag' } = $etag;
                            # Custom header for set timestamp,etag and permission.
            }
        }
    }
    $params->{ body } = $data;
    if ( $path =~ /\%/ ) {
        my $encoded = _encode_path( $path );
        if ( $encoded ne $path ) {
            my $name = $path;
            $name =~ s!^.*?/(.*)$!$1!;
            $params->{ headers }->{ 'x-ms-meta-path' } = $name;
            $path = $encoded;
        }
    }
    return $blobService->put( $path, $params );
}

sub _do_conditional {
    my ( $blobService, $path, $filename, $params ) = @_;
    return undef if (! -f $filename );
    my $metadata = $blobService->get_metadata( $path );
    if ( $metadata->code == 200 ) {
        my $conditional;
        if ( -f $filename ) {
            my $etag = $metadata->headers->{ 'x-ms-meta-etag' };
            my $mtime = $metadata->headers->{ 'x-ms-meta-mtime' };
            my $data = $params->{ content };
            if ( $etag && (! defined( $data ) ) ) {
                $data = '';
                open my $fh, "<$filename" or die "Can't open '$filename'.";
                binmode $fh;
                while ( read $fh, my ( $chunk ), 8192 ) {
                    $data .= $chunk;
                }
                close $fh;
            }
            if ( $etag && defined( $data ) ) {
                my $comp = Digest::MD5::md5_hex( $data );
                if ( $comp eq $etag ) {
                    $conditional = 1;
                }
            } elsif ( $mtime ) {
                my @stats = stat $filename;
                my $compare = $params->{ compare };
                my $conditional;
                if ( ( $compare eq 'to' ) && ( $stats[ 9 ] <= $mtime ) ) {
                    $conditional = 1;
                } elsif ( ( $compare eq 'from' ) && ( $stats[ 9 ] >= $mtime ) ) {
                    $conditional = 1;
                }
            }
        }
        if ( $conditional ) {
            $metadata->code( 304 );
            $metadata->message( 'Not Modified' );
            return $metadata;
        }
    }
    return undef;
}

sub _get_mtime {
    my $blobService = shift;
    my $blob = shift;
    my $mtime;
    if ( my $meta = $blob->{ Metadata } ) {
        if ( my $blob_mtime = $meta->{ Mtime } ) {
            $mtime = $blob_mtime;
        }
    }
    if (! $mtime ) {
        require HTTP::Date;
        $mtime = $blob->{ Properties }->{ 'Last-Modified' };
        $mtime = HTTP::Date::str2time( $mtime );
    }
    return $mtime;
}

sub _get_directory_info {
    my ( $blobService, $path, $dirname, $params ) = @_;
    $path = $blobService->_adjust_path( $path );
    if ( $path !~ m!/! ) {
        $path .= '/';
    }
    if ( $path =~ m!/$! ) {
        # Upload or Download directory
        $path = '' unless $path;
        $path =~ s!^/!!;
        my $container_name = $blobService->{ container_name };
        if (! $container_name ) {
            my @split_path = split( /\//, $path );
            $container_name = $split_path[ 0 ];
            $path =~ s!^$container_name/!!;
        } else {
            $path =~ s/^$container_name//;
            $path =~ s!^/!!;
        }
        return undef unless $container_name;
        my $dir = _basename( $path, '/', 'dirname' );
        if ( $dir eq '.' ) {
            $dir = $path;
        } else {
            $dir .= '/';
        }
        my $options = 'include=metadata';
        if ( $dir ) {
            $options .= '&prefix=' . $dir;
        }
        my $blobs;
        my $list_params = { options => $options };
        my $res = $blobService->list( $container_name, $list_params );
        my $responses;
        if ( ( ref $res ) ne 'ARRAY' ) {
            push ( @$responses, $res );
        } else {
            $responses = $res;
        }
        for my $res ( @$responses ) {
            if ( $res->code != 200 ) {
                die $res->message;
            }
            my $data = $res->content;
            my $xml = XML::Simple->new;
            my $list = $xml->XMLin( $data );
            if ( my $blob_list = $list->{ Blobs }->{ Blob } ) {
                if ( ref( $blob_list ) eq 'HASH' ) {
                    push ( @$blobs, $blob_list ); 
                } else {
                    push ( @$blobs, @$blob_list ); 
                }
            }
        }
        require File::Find;
        my $files;
        if ( -d $dirname ) {
            my $separator = $^O eq 'MSWin32' ? '\\' : '/';
            my $search_base = quotemeta( $dirname . $separator );
            my $command = 'File::Find::find( sub { 
                my $file = $File::Find::name;
                $file =~ s/^$search_base//;
                my $basename = File::Basename::basename( $_ );
                if ( $params->{ include_invisible } ) {
                    push( @$files, $file ) if ( -f $File::Find::name and  $basename !~ /^\.{1,}$/ );
                } else {
                    my @fileparse = File::Spec->splitdir( $file );
                    # push( @$files, $file ) if ( -f $File::Find::name and $basename !~ /^\./ );
                    push( @$files, $file ) if ( -f $File::Find::name and (! grep( /^\./, @fileparse ) ) );
                } },
                $dirname );';
            eval $command;
            if ( $@ ) {
                return die $@;
            }
        }
        my $dir_info = { container_name => $container_name,
                         path  => $path,
                         blobs => $blobs,
                         files => $files };
        return $dir_info;
    }
    return undef;
}

sub _encode_path {
    my ( $filename, $separator ) = @_;
    Encode::_utf8_off( $filename );
    my @fileparse;
    if (! $separator ) {
        $separator = $^O eq 'MSWin32' ? '\\' : '/';
        @fileparse = File::Spec->splitdir( $filename );
    } else {
        my $q = quotemeta( $separator );
        @fileparse = split( /$q/, $filename );
    }
    my @paths;
    for my $path ( @fileparse ) {
        $path =~ s!([^a-zA-Z0-9_.~-])!uc sprintf "%%%02x", ord($1)!eg;
        push ( @paths, $path );
    }
    $filename = join( $separator, @paths );
    return $filename;
}

sub _basename {
    my ( $filename, $separator, $want ) = @_;
    if (! $separator ) {
        $separator = $^O eq 'MSWin32' ? '\\' : '/';
    }
    $want = 'basename' unless $want;
    my $basename;
    if ( ( ( $^O ne 'MSWin32' ) && ( $separator eq '/' ) ) ||
       ( ( $^O eq 'MSWin32' ) && ( $separator eq '\\' ) ) ) {
        if ( $want eq 'dirname' ) {
            $basename = File::Basename::dirname( $filename );
        } elsif ( $want eq 'basename' ) {
            $basename = File::Basename::basename( $filename );
        }
    } else {
        my $q = quotemeta( $separator );
        $filename =~ s/$q$//;
        my @fileparse = split( /$q/, $filename );
        if ( $want eq 'dirname' ) {
            pop @fileparse;
            $basename = join( $separator, @fileparse );
            if (! $basename ) {
                $basename = '.';
            }
        } else {
            $basename = pop @fileparse;
        }
    }
    return $basename;
}

1;

__END__

=head1 NAME

Net::Azure::StorageClient::Blob - Interface to Windows Azure Blob Service

=head1 SYNOPSIS

  my $blobService = Net::Azure::StorageClient::Blob->new(
                                    account_name => $you_account_name,
                                    primary_access_key => $your_primary_access_key,
                                    [ container_name => $container_name, ]
                                    [ protocol => 'https', ] );
  my $path = 'path/to/blob';
  my $res = $blobService->get_blob( $path );

  # Request with custom http headers and query.
  my $params = { headers => { 'x-ms-foo' => 'bar' },
                 options => 'timeout=90' };
  my $res = $blobService->set_metadata( $path, $params );
  
  # return HTTP::Response object(s)

=head2 Operation on the Account(Blob Service)

=head3 list_containers

The List Containers operation returns a list of the containers under the specified account.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179352.aspx

  my $res = $blobService->list_containers( $params );

=head3 set_blob_service_properties

The Set Blob Service Properties operation sets the properties of a storage account's Blob service,
including Windows Azure Storage Analytics.
You can also use this operation to set the default request version for all incoming requests that
do not have a version specified.
http://msdn.microsoft.com/en-us/library/windowsazure/hh452235.aspx

  my $params = { StorageServicePropertie => { Logging => { Read => 'true' }, ... } };
  my $res = $blobService->set_blob_service_properties( $params );

=head3 get_blob_service_properties

The Get Blob Service Properties operation gets the properties of a storage account's Blob service,
including Windows Azure Storage Analytics.
http://msdn.microsoft.com/en-us/library/windowsazure/hh452239.aspx

  my $res = $blobService->get_blob_service_properties( $params );

=head2 Operation on Containers

=head3 create_container

The Create Container operation creates a new container under the specified account.
If the container with the same name already exists, the operation fails.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179468.aspx

  my $res = $blobService->create_container( $container_name );

  # Create container and set container's permission.
  my $params = { public_access => 'blob' }; # or container
  my $res = $blobService->create_container( $container_name, $params );

=head3 get_container_properties

The Get Container Properties operation returns all user-defined metadata and system properties
for the specified container.
The data returned does not include the container's list of blobs.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179370.aspx

  my $res = $blobService->get_container_properties( $container_name );

=head3 get_container_metadata

The Get Container Metadata operation returns all user-defined metadata for the container.
http://msdn.microsoft.com/en-us/library/windowsazure/ee691976.aspx

  my $res = $blobService->get_container_metadata( $container_name );

=head3 set_container_metadata

The Set Container Metadata operation sets one or more user-defined name-value pairs for the specified container.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179362.aspx

  my $res = $blobService->set_container_metadata( $container_name, { metadata => { 'foo' => 'bar' } } );
  # x-ms-meta-foo: bar

=head3 get_container_acl

The Get Container ACL operation gets the permissions for the specified container.
The permissions indicate whether container data may be accessed publicly.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179469.aspx

  my $res = $blobService->get_container_acl( $container_name );

=head3 set_container_acl

The Set Container ACL operation sets the permissions for the specified container.
The permissions indicate whether blobs in a container may be accessed publicly.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179391.aspx

  my $res = $blobService->set_container_acl( $container_name, { public_access => 'blob' } );
                                                                             # or container

=head3 delete_container

The Delete Container operation marks the specified container for deletion.
The container and any blobs contained within it are later deleted during garbage collection.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179408.aspx

  my $res = $blobService->delete_container( $container_name );

=head3 lease_container

The Lease Container operation establishes and manages a lock on a container for delete operations. 
The lock duration can be 15 to 60 seconds, or can be infinite.
http://msdn.microsoft.com/en-us/library/windowsazure/jj159103.aspx

  my $params = { lease_parameters => { 'lease-action' => 'acquire', ... } };
  my $res = $blobService->lease_container( $container_name, $params );

=head3 list_blobs

The List Blobs operation enumerates the list of blobs under the specified container.
http://msdn.microsoft.com/en-us/library/windowsazure/dd135734.aspx

  my $res = $blobService->list_blobs( $container_name );

=head3 download_container

Download all blobs of container to local directory.

  my $res = $blobService->list_blobs( $container_name, $dirname );

  # Download updated blobs only.
  my $params = { conditional => 1 };
  my $res = $blobService->list_blobs( $container_name, $dirname, $params );

  # Download updated blobs and delete deleted files of local directory.
  my $params = { conditional => 1, sync => 1 };
  my $res = $blobService->list_blobs( $container_name, $dirname, $params );

=head2 Operation on Blobs

=head3 put_blob

The Put Blob operation creates a new block blob or page blob,
or updates the content of an existing block blob.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179451.aspx

  my $res = $blobService->put_blob( $path, $data );

  # Upload local file to blob.
  my $params = { filename => '/path/to/filename' };
  my $res = $blobService->put_blob( $path, $params );

=head3 get_blob

The Get Blob operation reads or downloads a blob from the system,
including its metadata and properties. You can also call Get Blob to read a snapshot.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179440.aspx

  my $res = $blobService->get_blob( $path );

  # Download blob to local file.
  my $params = { filename => '/path/to/filename' };
  my $res = $blobService->get_blob( $path, $params );

=head3 get_blob_properties

The Get Blob Properties operation returns all user-defined metadata,
standard HTTP properties, and system properties for the blob. It does not return the content of the blob.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179394.aspx

  my $res = $blobService->get_blob_properties( $path );

=head3 set_blob_properties

The Set Blob Properties operation sets system properties on the blob.
http://msdn.microsoft.com/en-us/library/windowsazure/ee691966.aspx

  my $params = { properties => { 'content-length' => 1024, ... } };
  my $res = $blobService->set_blob_properties( $path, $params );

=head3 get_blob_metadata

The Get Blob Metadata operation returns all user-defined metadata for the specified blob
http://msdn.microsoft.com/en-us/library/windowsazure/dd179350.aspx

  my $res = $blobService->get_metadata( $path );

=head3 set_blob_metadata

The Set Blob Metadata operation sets user-defined metadata for the specified blob as one or more name-value pairs.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179414.aspx

  # Set x-ms-meta-category and x-ms-meta-author metadata.
  my $params = { metadata => { category => 'image'
                               author => $author_name } };
  my $res = $blobService->set_blob_metadata( $path, $params );

=head3 lease_blob

The Lease Blob operation establishes and manages a lock on a blob for write and delete operations.
http://msdn.microsoft.com/en-us/library/windowsazure/ee691972.aspx

  my $params = { lease_parameters => { 'lease-action' => 'acquire', ... } };
  my $res = $blobService->lease_blob( $path, $params );

=head3 snapshot_blob

The Snapshot Blob operation creates a read-only snapshot of a blob.
http://msdn.microsoft.com/en-us/library/windowsazure/ee691971.aspx

  my $res = $blobService->snapshot_blob( $path );

=head3 copy_blob

The Copy Blob operation copies a blob to a destination within the storage account.
http://msdn.microsoft.com/en-us/library/windowsazure/dd894037.aspx

  my $res = $blobService->copy_blob( $source_blob, $new_blob );

=head3 abort_copy_blob

The Abort Copy Blob operation aborts a pending Copy Blob operation,
and leaves a destination blob with zero length and full metadata.
http://msdn.microsoft.com/en-us/library/windowsazure/jj159098.aspx

  my $params = { copyid => $copyid };
  my $res = $blobService->abort_copy_blob( $path, $params );

=head3 delete_blob

The Delete Blob operation marks the specified blob or snapshot for deletion.
The blob is later deleted during garbage collection.
Note that in order to delete a blob, you must delete all of its snapshots.
You can delete both at the same time with the Delete Blob operation.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179413.aspx

  my $res = $blobService->delete_blob( $path );

=head3 rename_blob

Copy blob and delete copy source blob.
http://msdn.microsoft.com/en-us/library/windowsazure/dd894037.aspx
http://msdn.microsoft.com/en-us/library/windowsazure/dd179413.aspx

  my $res = $blobService->rename_blob( $source_blob, $new_blob );

=head2 Operation on Block Blobs

=head3 put_block

The Put Block operation creates a new block to be committed as part of a blob.
http://msdn.microsoft.com/en-us/library/windowsazure/dd135726.aspx

  my $params = { options => "blockid=${blockid}" };
  my $res = $blobService->put_block( $path, $params );

=head3 put_block_list

The Put Block List operation writes a blob by specifying the list of block IDs that make up the blob.
In order to be written as part of a blob,
a block must have been successfully written to the server in a prior Put Block (REST API) operation.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179467.aspx

  my $params = { BlockList => { Latest => 'foo' } };
  my $res = $blobService->put_block_list( $path, $params );

=head3 get_block_list

The Get Block List operation retrieves the list of blocks that have been uploaded as part of a block blob.
http://msdn.microsoft.com/en-us/library/windowsazure/dd179400.aspx

  my $res = $blobService->get_block_list( $path, $params );

=head2 Operation on Page Blobs

=head3 put_page

The Put Page operation writes a range of pages to a page blob.
http://msdn.microsoft.com/en-us/library/windowsazure/ee691975.aspx

  my $params = { 'page-write' => 'update', 'range' => 'bytes=0-65535' };
  my $res = $blobService->put_page( $path, $params );

=head3 get_page_ranges

The Get Page Ranges operation returns the list of valid page ranges for a page blob
or snapshot of a page blob.
http://msdn.microsoft.com/en-us/library/windowsazure/ee691973.aspx

  my $res = $blobService->get_page_ranges( $path );

=head2 Other Operations

=head3 download

Download a blob(or directory or container) and save to local file(s).

  my $res = $blobService->download( $path, $filename );

  # Download files of directory(Updated files only).
  my $params = { conditional => 1 };
  my $res = $blobService->download( $path, $directory, $params );

  # Download files of directory(updated files only) and delete deleted files.
  my $params = { conditional => 1, sync => 1 [, include_invisible => 1 ] };
  my $res = $blobService->download( $path, $directory, $params );

  # Using multi-thread.
  my $params = { conditional => 1, sync => 1, use_thread => n(Count of thread) };
  my $res = $blobService->download( $path, $directory, $params );

=head3 upload

Upload blob(s) from local file(s).

  my $res = $blobService->upload( $path, $filename );

  # Upload files of directory(updated files only).
  my $params = { conditional => 1 };
  my $res = $blobService->upload( $path, $directory, $perams );

  # Upload files of directory(updated files only) and delete deleted blobs.
  my $params = { conditional => 1, sync => 1 [, include_invisible => 1 ] };
  my $res = $blobService->upload( $path, $directory, $params );

  # Using multi-thread.
  my $params = { conditional => 1, sync => 1, use_thread => n(Count of thread) };
  my $res = $blobService->upload( $path, $directory, $params );

=head3 sync

Synchronize between the directory of blob storage and the local directory.

  my $params = { direction => 'upload' [, include_invisible => 1 ] };
  my $res = $blobService->sync( $path, $directory, $params );

  # Using multi-thread.
  my $params = { direction => 'upload', use_thread => n(Count of thread) };
  my $res = $blobService->upload( $path, $directory, $params );

=head1 AUTHOR

Junnama Noda <junnama@alfasado.jp>

=head1 COPYRIGHT

Copyright (C) 2013, Junnama Noda.

=head1 LICENSE

This program is free software;
you can redistribute it and modify it under the same terms as Perl itself.

=cut