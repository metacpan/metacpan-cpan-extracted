use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Storage v2.0.1 : isa(Net::BitTorrent::Emitter) {
    use Net::BitTorrent::Storage::File;
    use Digest::Merkle::SHA256;    # Standalone spin-off
    use Path::Tiny  qw();
    use Digest::SHA qw[sha1];
    use builtin     qw[refaddr];
    field $base_path  : param : reader;
    field $file_tree  : param : reader = undef;
    field $piece_size : param : reader = 0;
    field $pieces_v1  : param : reader = undef;
    field %files;                  # pieces_root => File object
    field @files_ordered;          # For v1 mapping
    method files_ordered () { \@files_ordered }
    field %piece_layers;           # pieces_root => piece layer data

    # Async Disk Cache (LRU)
    field %cache;                                    # file_id => { offset => data }
    field %cache_dirty;                              # file_id => { offset => 1 }
    field @lru_list;                                 # [[file_id, offset], ...]
    field $max_cache_size     = 1024 * 1024 * 16;    # 16MiB cache limit
    field $current_cache_size = 0;
    ADJUST {
        $base_path = Path::Tiny::path($base_path);
        if ($file_tree) {
            $self->load_file_tree($file_tree);
        }
    }

    method add_file ( $rel_path, $size, $pieces_root = undef ) {
        my $file = Net::BitTorrent::Storage::File->new(
            path        => $base_path->child($rel_path),
            size        => $size,
            pieces_root => $pieces_root,
            piece_size  => $piece_size,
        );
        push @files_ordered, $file;
        $files{$pieces_root} = $file if $pieces_root;
        return $file;
    }

    method load_file_tree ($tree) {
        $self->_parse_file_tree( $tree, [] );
    }

    method _parse_file_tree ( $tree, $path_stack ) {
        for my $name ( sort keys %$tree ) {
            my $node = $tree->{$name};
            if ( exists $node->{''} ) {
                my $file_info = $node->{''};
                $self->add_file( Path::Tiny::path( @$path_stack, $name ), $file_info->{length}, $file_info->{'pieces root'} );
            }
            else {
                $self->_parse_file_tree( $node, [ @$path_stack, $name ] );
            }
        }
    }

    method get_file_by_root ($root) {
        return $files{$root};
    }

    method set_piece_layer ( $root, $layer_data ) {
        $piece_layers{$root} = $layer_data;
    }

    method get_hashes ( $root, $base_layer, $index, $length ) {
        my $file = $files{$root} or return undef;
        return $file->merkle->get_hashes( $base_layer, $index, $length );
    }

    method verify_block ( $root, $index, $data ) {
        my $file = $files{$root};
        if ( !$file ) {
            $self->_emit_log( 'fatal', 'Unknown file root' );
            return;
        }
        return $file->verify_block( $index, $data );
    }

    method verify_block_audit ( $root, $index, $data, $audit_path ) {
        my $file = $files{$root};
        if ( !$file ) {
            $self->_emit_log( 'fatal', 'Unknown file root' );
            return;
        }
        return $file->verify_block_audit( $index, $data, $audit_path );
    }

    method verify_piece_v2 ( $root, $index, $data ) {
        my $file = $files{$root};
        if ( !$file ) {
            $self->_emit_log( 'fatal', 'Unknown file root' );
            return;
        }
        my $layer    = $piece_layers{$root} or return undef;
        my $expected = substr( $layer, $index * 32, 32 );
        return $file->verify_piece_v2( $index, $data, $expected );
    }

    # Writes a block to the cache
    method write_block ( $root, $offset, $data ) {
        my $file = $files{$root};
        if ( !$file ) {
            $self->_emit_log( 'fatal', 'Unknown file root' );
            return;
        }
        $self->_write_to_cache( $file, $offset, $data );
    }

    # Reads a block, checking cache first
    method read_block ( $root, $offset, $length ) {
        my $file = $files{$root};
        if ( !$file ) {
            $self->_emit_log( 'fatal', 'Unknown file root' );
            return;
        }
        return $self->_read_from_cache( $file, $offset, $length );
    }

    method read_global ( $offset, $length ) {
        my $segments  = $self->map_abs_offset( undef, $offset, $length );
        my $full_data = '';
        for my $seg (@$segments) {
            $full_data .= $self->_read_from_cache( $seg->{file}, $seg->{offset}, $seg->{length} );
        }
        return $full_data;
    }

    method write_global ( $offset, $data ) {
        my $segments    = $self->map_abs_offset( undef, $offset, length($data) );
        my $data_offset = 0;
        for my $seg (@$segments) {
            $self->_write_to_cache( $seg->{file}, $seg->{offset}, substr( $data, $data_offset, $seg->{length} ) );
            $data_offset += $seg->{length};
        }
    }

    method _write_to_cache ( $file, $offset, $data ) {
        my $id = refaddr($file);
        $self->_emit_log( 'debug', "Adding " . length($data) . " bytes to cache for file $id at offset $offset (dirty)" );
        if ( exists $cache{$id}{$offset} ) {
            $current_cache_size -= length( $cache{$id}{$offset} );
            $self->_lru_bump( $id, $offset );
        }
        else {
            push @lru_list, [ $id, $offset ];
        }
        $cache{$id}{$offset}       = $data;
        $cache_dirty{$id}{$offset} = 1;
        $current_cache_size += length($data);
        while ( $current_cache_size > $max_cache_size ) {
            last unless $self->_evict_one();
        }
    }

    method _read_from_cache ( $file, $offset, $length ) {
        my $id = refaddr($file);
        if ( exists $cache{$id} ) {
            for my $cached_offset ( keys %{ $cache{$id} } ) {
                my $cached_data = $cache{$id}{$cached_offset};
                my $cached_len  = length($cached_data);
                if ( $offset >= $cached_offset && ( $offset + $length ) <= ( $cached_offset + $cached_len ) ) {
                    $self->_lru_bump( $id, $cached_offset );
                    return substr( $cached_data, $offset - $cached_offset, $length );
                }
            }
        }

        # Cache miss - read from disk and add to clean cache
        my $data = $file->read( $offset, $length );
        if ( defined $data && length($data) > 0 ) {
            $self->_emit_log( 'debug', "Cache miss for file $id at offset $offset, caching read" );
            push @lru_list, [ $id, $offset ];
            $cache{$id}{$offset} = $data;
            $current_cache_size += length($data);
            while ( $current_cache_size > $max_cache_size ) {
                last unless $self->_evict_one();
            }
        }
        return $data;
    }

    method _lru_bump ( $id, $offset ) {

        # Move [id, offset] to end of @lru_list
        for my $i ( 0 .. $#lru_list ) {
            if ( $lru_list[$i][0] == $id && $lru_list[$i][1] == $offset ) {
                push @lru_list, splice( @lru_list, $i, 1 );
                last;
            }
        }
    }

    method _evict_one () {
        return 0 unless @lru_list;
        my $entry = shift @lru_list;
        my ( $id, $offset ) = @$entry;
        if ( $cache_dirty{$id} && $cache_dirty{$id}{$offset} ) {

            # Must flush before evicting
            $self->_flush_one( $id, $offset );
        }
        if ( exists $cache{$id} && exists $cache{$id}{$offset} ) {
            $current_cache_size -= length( delete $cache{$id}{$offset} );
            delete $cache{$id} unless keys %{ $cache{$id} };    # Clean up empty file entry
        }
        return 1;
    }

    method _flush_one ( $id, $offset ) {
        my $file;

        # Find file object by refaddr - inefficient but safe without reverse mapping
        # In a real system we'd store file objects in a registry.
        # Actually, let's look in %files and @files_ordered.
        for my $f (@files_ordered) {
            if ( refaddr($f) == $id ) {
                $file = $f;
                last;
            }
        }
        return unless $file;
        if ( exists $cache{$id}{$offset} && delete $cache_dirty{$id}{$offset} ) {
            my $data = $cache{$id}{$offset};
            $file->write( $offset, $data );
            $current_cache_size -= length( delete $cache{$id}{$offset} );    # Remove from cache after flush
            delete $cache{$id}       unless keys %{ $cache{$id} };           # Clean up empty file entry
            delete $cache_dirty{$id} unless keys %{ $cache_dirty{$id} };     # Clean up empty dirty entry
            return 1;
        }
        return 0;
    }

    method flush ( $count = undef ) {
        my $flushed = 0;
        for my $id ( keys %cache_dirty ) {
            for my $offset ( keys %{ $cache_dirty{$id} } ) {
                $self->_flush_one( $id, $offset );
                $flushed++;
                return $flushed if defined $count && $flushed >= $count;
            }
        }
        return $flushed;
    }

    method explicit_flush () {
        $self->flush();
    }

    method tick ( $delta = 0.1 ) {

        # Throttled flush: flush up to 16 items per tick
        $self->flush(16);
    }

    method map_abs_offset ( $root, $offset, $length ) {
        my @segments;
        if ( defined $root ) {
            my $file = $files{$root};
            if ( !$file ) {
                $self->_emit_log( 'fatal', 'Unknown file root' );
                return [];
            }
            push @segments, { file => $file, offset => $offset, length => $length };
        }
        else {
            my $current_file_start = 0;
            my $end                = $offset + $length;
            for my $file (@files_ordered) {
                my $file_size        = $file->size;
                my $current_file_end = $current_file_start + $file_size;
                if ( $offset < $current_file_end && $end > $current_file_start ) {
                    my $overlap_start = $offset > $current_file_start ? $offset : $current_file_start;
                    my $overlap_end   = $end < $current_file_end      ? $end    : $current_file_end;
                    push @segments, { file => $file, offset => $overlap_start - $current_file_start, length => $overlap_end - $overlap_start, };
                }
                $current_file_start = $current_file_end;
                last if $current_file_start >= $end;
            }
        }
        return \@segments;
    }

    method map_v1_piece ($index) {
        if ( !$piece_size ) {
            $self->_emit_log( 'fatal', 'piece_size not set' );
            return [];
        }
        my $piece_start = $index * $piece_size;
        my $piece_end   = $piece_start + $piece_size;
        my @segments;
        my $current_v1_offset = 0;
        for my $file (@files_ordered) {
            my $file_size   = $file->size;
            my $padded_size = $file_size;
            if ( $file->merkle && ( $file_size % $piece_size != 0 ) ) {
                $padded_size += ( $piece_size - ( $file_size % $piece_size ) );
            }
            my $current_v1_end = $current_v1_offset + $padded_size;
            if ( $piece_start < $current_v1_end && $piece_end > $current_v1_offset ) {
                my $overlap_start = $piece_start > $current_v1_offset ? $piece_start : $current_v1_offset;
                my $overlap_end   = $piece_end < $current_v1_end      ? $piece_end   : $current_v1_end;
                my $file_offset   = $overlap_start - $current_v1_offset;
                my $length        = $overlap_end - $overlap_start;
                if ( $file_offset < $file_size ) {
                    my $actual_len = ( $file_offset + $length > $file_size ) ? ( $file_size - $file_offset ) : $length;
                    push @segments, { file => $file, offset => $file_offset, length => $actual_len, } if $actual_len > 0;
                }
            }
            $current_v1_offset = $current_v1_end;
            last if $current_v1_offset >= $piece_end;
        }
        return \@segments;
    }

    method write_piece_v1 ( $index, $data ) {
        my $segments = $self->map_v1_piece($index);
        $self->_emit_log( 'debug', "write_piece_v1: Piece $index mapped to " . scalar(@$segments) . " segments" );
        my $data_offset = 0;
        for my $seg (@$segments) {
            $self->_write_to_cache( $seg->{file}, $seg->{offset}, substr( $data, $data_offset, $seg->{length} ) );
            $data_offset += $seg->{length};
        }
    }

    method read_piece_v1 ($index) {
        my $segments  = $self->map_v1_piece($index);
        my $full_data = '';
        for my $seg (@$segments) {
            $full_data .= $self->_read_from_cache( $seg->{file}, $seg->{offset}, $seg->{length} );
        }
        return $full_data;
    }

    method verify_piece_v1 ( $index, $data ) {
        return undef unless $pieces_v1;
        my $offset = $index * 20;
        return undef if $offset + 20 > length($pieces_v1);
        my $expected = substr( $pieces_v1, $offset, 20 );
        return sha1($data) eq $expected;
    }

    method map_v2_piece ($index) {
        if ( !$piece_size ) {
            $self->_emit_log( 'fatal', 'piece_size not set' );
            return ( undef, undef );
        }
        my $offset = 0;
        for my $file (@files_ordered) {
            my $file_size   = $file->size;
            my $padded_size = $file_size;
            if ( $file_size % $piece_size != 0 ) {
                $padded_size += ( $piece_size - ( $file_size % $piece_size ) );
            }
            my $num_pieces = int( $padded_size / $piece_size );
            my $rel_index  = $index - ( $offset / $piece_size );
            if ( $rel_index >= 0 && $rel_index < $num_pieces ) {
                return ( $file->pieces_root, $rel_index ) if $file->pieces_root;
                return ( undef,              undef );
            }
            $offset += $padded_size;
        }
        return ( undef, undef );
    }

    method dump_state () {
        my %file_states;
        for my $file (@files_ordered) {
            my $rel = $file->path->relative($base_path)->stringify;
            $file_states{$rel} = $file->dump_state();
        }
        return \%file_states;
    }

    method load_state ($state) {
        for my $file (@files_ordered) {
            my $rel = $file->path->relative($base_path)->stringify;
            if ( exists $state->{$rel} ) {
                $file->load_state( $state->{$rel} );
            }
        }
    }
} 1;
