use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Torrent::Generator v2.0.0 : isa(Net::BitTorrent::Emitter) {
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
    use Digest::SHA qw[sha1 sha256];
    use Path::Tiny;
    field $base_path : param;
    field $piece_length : param = 262144;    # 256KiB
    field @files;
    field @trackers;
    field @nodes;
    field $private     = 0;
    field $align_files = 0;
    method set_align_files ($val)     { $align_files = $val }
    method set_private     ($val)     { $private     = $val }
    method add_tracker     ($url)     { push @trackers, $url }
    method add_node        ( $h, $p ) { push @nodes,    [ $h, $p ] }

    method add_file ($rel_path) {
        my $bp = path($base_path)->absolute;
        $bp = $bp->realpath if $bp->exists;
        my $abs = $bp->child($rel_path)->absolute;

        # Canonicalize and check containment
        my $abs_real = $abs->realpath if $abs->exists;
        $abs_real //= $abs;
        if ( $abs_real !~ /^\Q$bp\E/ ) {
            $self->_emit_log( 'fatal', "Path traversal attempt blocked: $rel_path resolves outside base_path" );
            return;
        }
        if ( !$abs_real->is_file ) {
            $self->_emit_log( 'fatal', "File does not exist or is not a regular file: $abs_real" );
            return;
        }
        if ( $align_files && @files && $files[-1]{size} % $piece_length != 0 ) {
            my $pad = $piece_length - ( $files[-1]{size} % $piece_length );
            push @files, { rel => ".pad/$pad", size => $pad, padding => 1 };
        }
        push @files, { rel => $rel_path, abs => $abs_real, size => $abs_real->stat->size };
    }

    method generate_v1 () {
        my $info = $self->_base_info();
        $info->{pieces} = $self->_generate_pieces_v1();
        return $self->_wrap_torrent($info);
    }

    method generate_v2 () {
        my ( $file_tree, $piece_layers ) = $self->_generate_v2_data();
        my $info = {
            name           => path($base_path)->basename,
            'piece length' => $piece_length,
            'file tree'    => $file_tree,
            'meta version' => 2,
            private        => $private,
        };
        return $self->_wrap_torrent( $info, $piece_layers );
    }

    method generate_hybrid () {
        my ( $file_tree, $piece_layers ) = $self->_generate_v2_data();
        my $info = $self->_base_info();
        $info->{'file tree'}    = $file_tree;
        $info->{'meta version'} = 2;
        $info->{pieces}         = $self->_generate_pieces_v1();
        return $self->_wrap_torrent( $info, $piece_layers );
    }

    method _base_info () {
        my $info = { name => path($base_path)->basename, 'piece length' => $piece_length, private => $private, };
        if ( @files == 1 && !$files[0]{padding} ) {
            $info->{length} = $files[0]{size};
        }
        else {
            $info->{files} = [ map { { length => $_->{size}, path => [ split m{/}, $_->{rel} ] } } @files ];
        }
        return $info;
    }

    method _wrap_torrent ( $info, $piece_layers = undef ) {
        my $torrent = { info => $info, 'created by' => 'Net::BitTorrent 2.0.0', 'creation date' => time(), };
        $torrent->{'piece layers'}  = $piece_layers              if $piece_layers;
        $torrent->{announce}        = $trackers[0]               if @trackers;
        $torrent->{'announce-list'} = [ map { [$_] } @trackers ] if @trackers > 1;
        $torrent->{nodes}           = \@nodes                    if @nodes;
        return bencode($torrent);
    }

    method _generate_pieces_v1 () {
        my $pieces = '';
        my $buffer = '';
        for my $file (@files) {
            if ( $file->{padding} ) {
                $buffer .= "\0" x $file->{size};
                while ( length($buffer) >= $piece_length ) {
                    $pieces .= sha1( substr( $buffer, 0, $piece_length, '' ) );
                }
                next;
            }
            my $fh = $file->{abs}->openr_raw;
            while ( read( $fh, my $chunk, $piece_length - length($buffer) ) ) {
                $buffer .= $chunk;
                if ( length($buffer) == $piece_length ) {
                    $pieces .= sha1($buffer);
                    $buffer = '';
                }
            }
        }
        $pieces .= sha1($buffer) if length($buffer) > 0;
        return $pieces;
    }

    method _generate_v2_data () {
        use Digest::Merkle::SHA256;
        my $file_tree = {};
        my %piece_layers;
        for my $file ( grep { !$_->{padding} } @files ) {
            my $merkle    = Digest::Merkle::SHA256->new( file_size => $file->{size} );
            my $fh        = $file->{abs}->openr_raw;
            my $block_idx = 0;
            while ( read( $fh, my $block, 16384 ) ) {
                $merkle->set_block( $block_idx++, sha256($block) );
            }
            my @path = split m{/}, $file->{rel};
            my $curr = $file_tree;
            my $name = pop @path;
            $curr = ( $curr->{$_} //= {} ) for @path;
            $curr->{$name} = { '' => { length => $file->{size}, 'pieces root' => $merkle->root } };
            if ( $file->{size} > $piece_length ) {
                $piece_layers{ $merkle->root } = $merkle->get_piece_layer($piece_length);
            }
        }
        return ( $file_tree, \%piece_layers );
    }
} 1;
