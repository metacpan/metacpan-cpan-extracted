package Pcore::Util::Path1;

use Pcore -class, -const, -res;
use Clone qw[];
use Cwd qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use Pcore::Util::Data qw[from_uri_utf8 to_uri_path];
use Pcore::Util::Scalar qw[is_blessed_hashref];

use overload
  q[""]  => sub { $_[0]->{to_string} },
  'bool' => sub {1},
  '.' => sub ( $self, $str, $order ) {

    # $str + $self
    if ($order) {
        return Pcore::Util::Path1->new("$str/$self->{to_string}");
    }

    # $self + $str
    else {
        if ( $self->{to_string} eq '' ) {
            return Pcore::Util::Path1->new("./$str");
        }
        else {
            return Pcore::Util::Path1->new("$self->{to_string}/$str");
        }
    }
  },
  fallback => 1;

with qw[
  Pcore::Util::Result::Status
  Pcore::Util::Path1::Dir
  Pcore::Util::Path1::Poll
];

has to_string     => ();
has volume        => ();
has dirname       => ();
has filename      => ();
has filename_base => ();
has suffix        => ();

has is_abs => ();

has _to_url => ( init_arg => undef );

has IS_PCORE_PATH => ( 1, init_arg => undef );

around new => sub ( $orig, $self, $path = undef, %args ) {
    $self = ref $self if is_blessed_hashref $self;

    if ( !defined $path ) {
        return bless {}, $self;
    }

    if ( is_blessed_hashref $path ) {
        return $path->clone if $path->{IS_PCORE_PATH};

        $path = "$path";
    }

    if ( $args{from_uri} ) {
        $path = from_uri_utf8 $path;
    }

    return bless _normalize($path), $self;
};

sub to_string ($self) {
    if ( !exists $self->{to_string} ) {

    }

    return $self->{to_string};
}

sub clone ($self) {
    return Clone::clone($self);
}

sub to_uri ($self) {
    if ( !exists $self->{_to_uri} ) {
        my $path = $self->{to_string};

        # Relative Reference: https://tools.ietf.org/html/rfc3986#section-4.2
        # A path segment that contains a colon character (e.g., "this:that")
        # cannot be used as the first segment of a relative-path reference, as
        # it would be mistaken for a scheme name.  Such a segment must be
        # preceded by a dot-segment (e.g., "./this:that") to make a relative-
        # path reference.
        # $path = "./$path" if $path =~ m[\A[^/]*:]sm;

        if ( $self->{volume} ) {
            $self->{_to_uri} = to_uri_path "/$path";
        }
        elsif ( $path =~ m[\A[^/]*:]sm ) {
            $self->{_to_uri} = to_uri_path "./$path";
        }
        else {
            $self->{_to_uri} = to_uri_path $path;
        }
    }

    return $self->{_to_uri};
}

sub to_abs ( $self, $base = undef ) {

    # path is already absolute
    return defined wantarray ? $self->clone : () if $self->{is_abs};

    if ( !defined $base ) {
        $base = Cwd::getcwd();
    }
    else {
        $base = $self->new($base)->to_abs->{to_string};
    }

    if ( defined wantarray ) {
        return $self->new( "$base/" . ( $self->{to_string} // '' ) );
    }
    else {
        $self->{to_string} = "$base/" . ( $self->{to_string} // '' );
    }

    return;
}

sub to_realpath ( $self ) {
    my $realpath = Cwd::realpath( $self->{to_string} // '.' );

    if ( defined wantarray ) {
        return $self->new($realpath);
    }
    else {
        $self->{to_string} = $realpath;

        return;
    }
}

sub volume ( $self, $volume = undef ) {
    return;
}

# sub TO_DUMP {
#     my $self = shift;

#     my $res;
#     my $tags;

#     $res = qq[path: "$self->{to_string}"];

#     # $res .= qq[\nMIME type: "] . $self->mime_type . q["] if $self->mime_type;

#     return $res, $tags;
# }

use Inline(
    C => <<'C',
# include "Pcore/Util/Path.h"

SV *_normalize (SV *path) {

    // call fetch() if a tied variable to populate the SV
    SvGETMAGIC(path);

    U8 *buf = NULL;
    size_t buf_len = 0;

    // check for undef
    if ( path != &PL_sv_undef ) {

        // copy the sv without the magic struct
        buf = SvPV_nomg_const(path, buf_len);
    }

    PcoreUtilPath *res = normalize(buf, buf_len);

    HV *hash = newHV();
    hv_store(hash, "is_abs", 6, newSVuv(res->is_abs), 0);
    hv_store(hash, "volume", 6, res->volume_len ? newSVpvn(res->volume, res->volume_len) : newSV(0), 0);

    if (res->path_len) {
        SV *path = newSVpvn(res->path, res->path_len);
        sv_utf8_decode(path);
        hv_store(hash, "to_string", 9, path, 0);
    }
    else {
        hv_store(hash, "to_string", 9, newSV(0), 0);
    }

    free(res->path);
    free(res->volume);
    free(res);

    sv_2mortal((SV*)newRV_noinc((SV *)hash));

    return newRV((SV *)hash);
}
C
    inc        => '-I' . $ENV->{share}->get_storage( 'Pcore', 'include' ),
    ccflagsex  => '-Wall -Wextra -Ofast -std=c11',
    prototypes => 'ENABLE',
    prototype  => { _normalize => '$', },
);

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 21, 121, 124         | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path1

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
