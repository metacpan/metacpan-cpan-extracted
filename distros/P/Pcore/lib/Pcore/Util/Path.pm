package Pcore::Util::Path;

use Pcore -class, -const, -res;
use Clone qw[];
use Cwd qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use Pcore::Util::Data qw[from_uri_utf8 to_uri_path];
use Pcore::Util::Scalar qw[is_path is_blessed_hashref];
use Pcore::Util::Text qw[encode_utf8 decode_utf8];

use overload
  q[""]  => sub { $_[0]->{path} },
  'bool' => sub {1},
  '-X'   => sub {
    state $map = { map { $_ => eval qq[sub { return -$_ \$_[0] }] } qw[r w x o R W X O e z s f d l p S b c t u g k T B M A C] };    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]

    return $map->{ $_[1] }->( $MSWIN ? $_[0]->encoded : $_[0]->{path} );
  },
  fallback => 1;

with qw[
  Pcore::Util::Path::MIME
  Pcore::Util::Path::Dir
  Pcore::Util::Path::File
  Pcore::Util::Path::Poll
];

has path          => ( required => 1 );
has volume        => ( required => 1 );
has dirname       => ( required => 1 );
has filename      => ( required => 1 );
has filename_base => ( required => 1 );
has suffix        => ( required => 1 );

has is_abs => ();

has _encoded => ( init_arg => undef );    # utf8 encoded path
has _to_url  => ( init_arg => undef );

# from_uri, from_mswin
around new => sub ( $orig, $self, $path = undef, %args ) {
    $self = ref $self if is_blessed_hashref $self;

    if ( !defined $path || $path eq $EMPTY || $path eq '.' ) {
        return bless {
            path    => '.',
            dirname => '.',
        }, $self;
    }

    if ( is_blessed_hashref $path ) {
        return $path->clone if is_path $path;

        $path = "$path";
    }
    elsif ( $path eq '/' ) {
        return bless {
            path    => '/',
            dirname => '/',
        }, $self;
    }

    if ( $args{from_uri} ) {
        $path = from_uri_utf8 $path;
    }
    elsif ( $args{from_mswin} ) {
        $path = $self->decode($path);
    }

    $self = bless _parse($path), $self;

    return $self;
};

sub encoded ( $self ) {
    if ( !exists $self->{_encoded} ) {
        if ($MSWIN) {
            state $enc = Encode::find_encoding($Pcore::WIN_ENC);

            if ( utf8::is_utf8 $self->{path} ) {
                $self->{_encoded} = $enc->encode( $self->{path}, Encode::LEAVE_SRC & Encode::DIE_ON_ERR );
            }
            else {
                $self->{_encoded} = $self->{path};
            }
        }
        else {
            $self->{_encoded} = encode_utf8 $self->{path};
        }
    }

    return $self->{_encoded};
}

sub decode ( $self, $path ) {

    # already decoded
    return $path if utf8::is_utf8 $path;

    if ($MSWIN) {
        state $enc = Encode::find_encoding($Pcore::WIN_ENC);

        return $enc->decode( $path, Encode::LEAVE_SRC & Encode::DIE_ON_ERR );
    }
    else {
        return decode_utf8 $path;
    }
}

sub to_string ($self) { return $self->{path} }

sub clone ($self) { return Clone::clone($self) }

sub to_uri ($self) {
    if ( !exists $self->{_to_uri} ) {

        # Relative Reference: https://tools.ietf.org/html/rfc3986#section-4.2
        # A path segment that contains a colon character (e.g., "this:that")
        # cannot be used as the first segment of a relative-path reference, as
        # it would be mistaken for a scheme name.  Such a segment must be
        # preceded by a dot-segment (e.g., "./this:that") to make a relative-
        # path reference.
        # $path = "./$path" if $path =~ m[\A[^/]*:]sm;

        my $path = $self->{path};

        if ( $path eq '/' ) {
            $self->{_to_uri} = '/';
        }
        elsif ( $path eq '.' ) {
            $self->{_to_uri} = $EMPTY;
        }
        else {
            if ( $self->{volume} ) {
                $path = to_uri_path $path;

                # encode ":" in volume name
                substr $path, 1, 1, '%3A';

                $self->{_to_uri} = $path;
            }
            elsif ( !$self->{is_abs} && $path =~ m[\A[^/]*:]sm ) {
                $self->{_to_uri} = to_uri_path "./$path";
            }
            else {
                $self->{_to_uri} = to_uri_path $path;
            }

            $self->{_to_uri} .= '/' if !defined $self->{filename} && substr( $self->{_to_uri}, -1, 1 ) ne '/';
        }
    }

    return $self->{_to_uri};
}

# SETTERS
sub to_abs ( $self, $base = undef ) {

    # path is already absolute
    return $self if $self->{is_abs};

    if ( !defined $base ) {
        $base = Cwd::getcwd();
    }
    elsif ( is_path $base ) {
        $base = $base->to_abs->{dirname};
    }
    else {
        $base = $self->new($base)->to_abs->{dirname};
    }

    if ( defined $self->{filename} ) {
        return $self->set_path("$base/$self->{path}");
    }
    else {
        return $self->set_path("$base/$self->{path}/");
    }
}

sub merge ( $self, $base ) {

    # path is absolute
    return $self if $self->{is_abs};

    return $self if !defined $base;

    if ( is_path $base ) {
        $base = $base->{dirname};
    }
    else {
        $base = $self->new($base)->{dirname};
    }

    if ( defined $self->{filename} ) {
        return $self->set_path("$base/$self->{path}");
    }
    else {
        return $self->set_path("$base/$self->{path}/");
    }
}

# TODO
sub to_rel ( $self, $base = undef ) {
    ...;

    return;
}

sub to_realpath ( $self ) {
    my $realpath = Cwd::realpath( $self->{path} );

    return $self->set_path($realpath);
}

sub set_path ( $self, $path = undef ) {
    my $hash = _parse($path);

    $self->@{ keys $hash->%* } = values $hash->%*;

    $self->_clear_cache;

    return $self;
}

sub set_volume ( $self, $volume = undef ) {
    my $path;

    # remove volume
    if ( !$volume ) {
        if ( $self->{volume} ) {
            $path = $self->{path};

            substr $path, 0, 2, $EMPTY;
        }

        # nothing to do
        else {
            return $self;
        }
    }

    # set volume
    else {
        $volume = lc $volume;

        # has volume
        if ( $self->{volume} ) {

            # nothing to do
            return $self if $self->{volume} eq $volume;

            # replace volume
            $path = $self->{path};

            substr $path, 0, 1, $volume;
        }

        # add volume
        else {
            $path = "$volume:/$self->{path}";
        }
    }

    return $self->set_path($path);
}

sub set_dirname ( $self, $dirname = undef ) {
    if ( defined $dirname ) {
        return $self->set_path( defined $self->{filename} ? "$dirname/$self->{filename}" : $dirname );
    }
    else {
        return $self->set_path( $self->{filename} );
    }
}

sub set_filename ( $self, $filename = undef ) {
    if ( defined $filename ) {
        return $self->set_path( defined $self->{dirname} ? "$self->{dirname}/$filename" : $filename );
    }
    else {
        return $self if !defined $self->{filename};

        return $self->set_path( defined $self->{dirname} ? "$self->{dirname}/" : undef );
    }
}

sub set_filename_base ( $self, $filename_base = undef ) {
    if ( !defined $filename_base ) {
        return $self->set_filename;
    }
    else {
        my $path = $EMPTY;

        $path .= "$self->{dirname}/" if defined $self->{dirname};

        $path .= $filename_base;

        $path .= ".$self->{suffix}" if defined $self->{suffix};

        return $self->set_path($path);
    }
}

sub set_suffix ( $self, $suffix = undef ) {
    return $self if !defined $self->{filename};

    my $path = $EMPTY;

    $path .= "$self->{dirname}/" if defined $self->{dirname};

    $path .= $self->{filename_base};

    $path .= ".$suffix" if defined $suffix && $suffix ne $EMPTY;

    return $self->set_path($path);
}

sub _clear_cache ($self) {
    delete $self->@{qw[_encoded _to_uri]};

    return;
}

*TO_JSON = *TO_CBOR = sub ($self) {
    return $self->{path};
};

sub TO_DUMP1 ( $self, @ ) {
    my $res;
    my $tags;

    $res = qq[path: "$self->{path}"];

    # $res .= qq[\nMIME type: "] . $self->mime_type . q["] if $self->mime_type;

    return $res, $tags;
}

use Inline(
    C => <<'C',
# include "Pcore/Lib/Path.h"

SV *_parse (SV *path) {

    // call fetch() if a tied variable to populate the SV
    SvGETMAGIC(path);

    const char *buf = NULL;
    size_t buf_len = 0;

    // check for undef
    if ( path != &PL_sv_undef ) {

        // copy the sv without the magic struct
        buf = SvPV_nomg_const(path, buf_len);
    }

    PcoreLibPath *res = parse(buf, buf_len);

    HV *hash = newHV();
    hv_store(hash, "is_abs", 6, newSVuv(res->is_abs), 0);

    // path
    SV *path_sv = newSVpvn(res->path, res->path_len);
    sv_utf8_decode(path_sv);
    hv_store(hash, "path", 4, path_sv, 0);

    // volume
    hv_store(hash, "volume", 6, res->volume_len ? newSVpvn(res->volume, res->volume_len) : newSV(0), 0);

    // dirname
    if (res->dirname_len) {
        SV *sv = newSVpvn(res->dirname, res->dirname_len);
        sv_utf8_decode(sv);
        hv_store(hash, "dirname", 7, sv, 0);
    }
    else {
        hv_store(hash, "dirname", 7, newSV(0), 0);
    }

    // filename
    if (res->filename_len) {
        SV *sv = newSVpvn(res->filename, res->filename_len);
        sv_utf8_decode(sv);
        hv_store(hash, "filename", 8, sv, 0);
    }
    else {
        hv_store(hash, "filename", 8, newSV(0), 0);
    }

    // filename_base
    if (res->filename_base_len) {
        SV *sv = newSVpvn(res->filename_base, res->filename_base_len);
        sv_utf8_decode(sv);
        hv_store(hash, "filename_base", 13, sv, 0);
    }
    else {
        hv_store(hash, "filename_base", 13, newSV(0), 0);
    }

    // suffix
    if (res->suffix_len) {
        SV *sv = newSVpvn(res->suffix, res->suffix_len);
        sv_utf8_decode(sv);
        hv_store(hash, "suffix", 6, sv, 0);
    }
    else {
        hv_store(hash, "suffix", 6, newSV(0), 0);
    }

    destroyPcoreLibPath(res);

    sv_2mortal((SV*)newRV_noinc((SV *)hash));

    return newRV((SV *)hash);
}
C
    inc        => "-I$ENV->{PCORE_SHARE_DIR}/include",
    ccflagsex  => '-Wall -Wextra -Ofast -std=c11',
    prototypes => 'ENABLE',
    prototype  => { _parse => '$', },

    # build_noisy => 1,
    # force_build => 1,
);

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 14                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 203                  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
