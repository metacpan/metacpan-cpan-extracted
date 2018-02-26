package Pcore::Src::File;

use Pcore -class;
use Pcore::Util::Text qw[encode_utf8 decode_eol lcut_all rcut_all rtrim_multi remove_bom];

require Pcore::Src;

has action => ( is => 'ro', isa => Enum [ $Pcore::Src::SRC_DECOMPRESS, $Pcore::Src::SRC_COMPRESS, $Pcore::Src::SRC_OBFUSCATE ], required => 1 );
has path => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Path'], required => 1 );
has is_realpath => ( is => 'lazy', isa => Bool );
has in_buffer   => ( is => 'lazy', isa => ScalarRef, predicate => 1 );
has decode      => ( is => 'ro',   isa => Bool, default => 0 );
has dry_run     => ( is => 'ro',   isa => Bool, default => 0 );
has filter_args => ( is => 'ro',   isa => HashRef );

has out_buffer  => ( is => 'lazy', isa => ScalarRef, init_arg => undef );
has is_binary   => ( is => 'lazy', isa => Bool,      init_arg => undef );
has was_changed => ( is => 'lazy', isa => Bool,      init_arg => undef );
has severity    => ( is => 'rw',   isa => Int,       default  => 0, init_arg => undef );
has severity_range => ( is => 'lazy', isa => Enum [ keys Pcore::Src::File->cfg->{SEVERITY_RANGE}->%* ], init_arg => undef );

has _can_write => ( is => 'rw',   isa => Bool, default  => 0, init_arg => undef );
has _in_size   => ( is => 'lazy', isa => Int,  init_arg => undef );
has _in_md5    => ( is => 'lazy', isa => Str,  init_arg => undef );
has _out_size  => ( is => 'lazy', isa => Int,  init_arg => undef );
has _out_md5   => ( is => 'lazy', isa => Str,  init_arg => undef );

has dist_cfg => ( is => 'lazy', isa => HashRef, init_arg => undef );

# CLASS METHODS
sub cfg ($self) {
    state $cfg = P->cfg->load( $ENV->share->get('/data/src.perl') );

    return $cfg;
}

sub detect_filetype ( $self, $path, $buf_ref = undef ) {
    $path = P->path($path);

    if ( my $mime_type = $path->mime_type( $buf_ref // 1 ) ) {
        return Pcore::Src::File->cfg->{MIME_TYPE}->{$mime_type} if exists Pcore::Src::File->cfg->{MIME_TYPE}->{$mime_type};
    }

    return;
}

sub BUILDARGS ( $self, $args ) {
    $args->{path} = P->path( $args->{path} ) if !ref $args->{path};

    return $args;
}

# METHODS
sub _build_is_realpath ($self) {
    return $self->path->realpath ? 1 : 0;
}

sub _build_dist_cfg ($self) {
    my $cfg = {};

    state $path = {};

    state $dists = {};

    my $realpath = $self->is_realpath ? $self->path->realpath : 0;

    if ($realpath) {
        my $dirname = $realpath->dirname;

        # find and cache dist root for path
        if ( !exists $path->{$dirname} ) {
            $path->{$dirname} = Pcore::Dist->find_dist_root($dirname);
        }

        # load and cache dist config if path is related to some dist
        if ( $path->{$dirname} ) {
            if ( !exists $dists->{ $path->{$dirname} } ) {
                my $dist_cfg = P->cfg->load( $path->{$dirname} . 'share/dist.perl' );

                if ( exists $dist_cfg->{src} ) {
                    $dists->{ $path->{$dirname} } = $dist_cfg->{src};
                }
                else {
                    $dists->{ $path->{$dirname} } = 0;
                }
            }

            $cfg = $dists->{ $path->{$dirname} } if $dists->{ $path->{$dirname} };
        }
    }

    return $cfg;
}

sub _build_in_buffer ($self) {
    my $res;

    eval {
        $res = P->file->read_bin( $self->path );

        $self->_can_write(1);
    };

    if ($@) {
        $self->severity( Pcore::Src::File->cfg->{SEVERITY}->{OPEN} );

        $self->_can_write(0);

        $res = \q[];
    }

    return $res;
}

sub _build_is_binary ($self) {
    if ( !$self->path ) {
        return 0;
    }
    else {
        return -B $self->path ? 1 : 0;
    }
}

sub _build_was_changed ($self) {
    return $self->_in_md5 eq $self->_out_md5 ? 0 : 1;
}

sub _build__in_size ($self) {
    return bytes::length( $self->in_buffer->$* );
}

sub _build__out_size ($self) {
    return bytes::length( $self->out_buffer->$* );
}

sub _build__in_md5 ($self) {
    return P->digest->md5_hex( $self->in_buffer->$* );
}

sub _build__out_md5 ($self) {
    return P->digest->md5_hex( $self->out_buffer->$* );
}

sub _build_out_buffer ($self) {
    my $buffer;

    if ( $self->has_in_buffer ) {
        $buffer = $self->in_buffer->$*;
    }
    else {
        # check if buffer is binary
        if ( $self->is_binary ) {
            $self->severity( Pcore::Src::File->cfg->{SEVERITY}->{BINARY} );

            return $self->in_buffer;
        }

        # try to read file
        $buffer = $self->in_buffer->$*;

        # return, if has reading errors
        return $self->in_buffer if $self->severity;
    }

    if ( $self->decode ) {
        state $init = !!require Encode::Guess;

        # detect buffer encoding
        my $decoder = Encode::Guess::guess_encoding($buffer);

        $decoder = Encode::Guess::guess_encoding( $buffer, Pcore::Src::File->cfg->{DEFAULT_GUESS_ENCODING}->@* ) unless ref $decoder;

        # appropriate encoding wasn't found
        unless ( ref $decoder ) {
            $self->severity( Pcore::Src::File->cfg->{SEVERITY}->{ENCODING} );

            return $self->in_buffer;
        }

        # try to decode buffer
        eval { $buffer = $decoder->decode( $buffer, Encode::FB_CROAK ) };

        if ($@) {
            $self->severity( Pcore::Src::File->cfg->{SEVERITY}->{ENCODING} );

            return $self->in_buffer;
        }

        remove_bom $buffer;

        encode_utf8 $buffer;
    }

    # detect filetype, require and run filter
    if ( my $type = $self->detect_filetype( $self->path, \$buffer ) ) {
        my $method = $self->action;

        my $filter_args = $type->{filter_args} // {};

        P->hash->merge( $filter_args, $self->filter_args ) if $self->filter_args;

        $self->severity( P->class->load( $type->{type}, ns => 'Pcore::Src::Filter' )->new( { file => $self, buffer => \$buffer } )->$method( $filter_args->%* ) );
    }

    if ( $self->action eq 'decompress' ) {

        # clean buffer
        decode_eol $buffer;    # decode CRLF to internal \n representation

        lcut_all $buffer;      # trim leading horizontal whitespaces

        rcut_all $buffer;      # trim trailing horizontal whitespaces

        rtrim_multi $buffer;   # right trim each line

        $buffer =~ s/\t/    /smg;    # convert tabs to spaces

        $buffer .= $LF;
    }

    return \$buffer;
}

sub _build_severity_range ($self) {
    for my $range ( reverse sort { Pcore::Src::File->cfg->{SEVERITY_RANGE}->{$a} <=> Pcore::Src::File->cfg->{SEVERITY_RANGE}->{$b} } keys Pcore::Src::File->cfg->{SEVERITY_RANGE}->%* ) {
        if ( $self->severity >= Pcore::Src::File->cfg->{SEVERITY_RANGE}->{$range} ) {
            return $range;
        }
    }

    return 'VALID';
}

sub severity_range_is ( $self, $range ) {
    return $self->severity_range eq uc $range;
}

sub run ($self) {
    $self->out_buffer;

    # write file, if it was physically read from disk
    if ( $self->_can_write && !$self->dry_run && $self->was_changed ) {

        # remove READ-ONLY attr under windows
        chmod 0777, $self->path or 1 if $MSWIN;

        P->file->write_bin( $self->path, $self->out_buffer );
    }

    return $self;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 98, 181              | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Src::File

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
