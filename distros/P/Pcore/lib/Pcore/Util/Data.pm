package Pcore::Util::Data;

use Pcore -const, -export;
use Pcore::Util::Text qw[decode_utf8 encode_utf8 escape_perl trim];
use Pcore::Util::List qw[pairs];
use Sort::Naturally qw[nsort];
use Pcore::Util::Scalar qw[is_ref is_blessed_ref is_plain_scalarref is_plain_arrayref is_plain_hashref];

our $EXPORT = {
    ALL   => [qw[encode_data decode_data]],
    PERL  => [qw[to_perl from_perl]],
    JSON  => [qw[to_json from_json]],
    CBOR  => [qw[to_cbor from_cbor]],
    YAML  => [qw[to_yaml from_yaml]],
    XML   => [qw[to_xml from_xml]],
    INI   => [qw[to_ini from_ini]],
    B64   => [qw[to_b64 to_b64u from_b64 from_b64u]],
    URI   => [qw[to_uri to_uri_component to_uri_scheme to_uri_path to_uri_query to_uri_query_frag from_uri from_uri_utf8 from_uri_query from_uri_query_utf8]],
    XOR   => [qw[to_xor from_xor]],
    CONST => [qw[$DATA_ENC_B64 $DATA_ENC_HEX $DATA_COMPRESS_ZLIB $DATA_CIPHER_DES]],
    TYPE  => [qw[$DATA_TYPE_PERL $DATA_TYPE_JSON $DATA_TYPE_CBOR $DATA_TYPE_YAML $DATA_TYPE_XML $DATA_TYPE_INI]],
};

const our $DATA_TYPE_PERL => 1;
const our $DATA_TYPE_JSON => 2;
const our $DATA_TYPE_CBOR => 3;
const our $DATA_TYPE_YAML => 4;
const our $DATA_TYPE_XML  => 5;
const our $DATA_TYPE_INI  => 6;

const our $DATA_ENC_B64 => 1;
const our $DATA_ENC_HEX => 2;

const our $DATA_COMPRESS_ZLIB => 1;

const our $DATA_CIPHER_DES => 1;

const our $CIPHER_NAME => {    #
    $DATA_CIPHER_DES => 'DES',
};

our $JSON_CACHE;

# JSON is used by default
# JSON can't serialize ScalarRefs
# objects should have TO_JSON method, otherwise object will be serialized as null
# base64 encoder is used by default, it generates more compressed data
sub encode_data ( $type, $data, @args ) {
    my %args = (
        readable           => undef,               # make serialized data readable for humans
        compress           => undef,               # use compression
        secret             => undef,               # crypt data if defined, can be ArrayRef
        secret_index       => 0,                   # index of secret to use in secret array, if secret is ArrayRef
        encode             => undef,               # 0 - disable
        token              => undef,               # attach informational token
        compress_threshold => 100,                 # min data length in bytes to perform compression, only if compress = 1
        cipher             => $DATA_CIPHER_DES,    # cipher to use
        json               => undef,               # HashRef with additional params for Cpanel::JSON::XS
        xml                => undef,               # HashRef with additional params for XML::Hash::XS
        @args,
    );

    if ( $args{readable} && $type != $DATA_TYPE_CBOR ) {
        $args{compress} = undef;
        $args{secret}   = undef;
        $args{encode}   = undef;
        $args{token}    = undef;
    }

    my $res;

    # encode
    if ( $type == $DATA_TYPE_PERL ) {
        $res = to_perl( $data, readable => $args{readable} );
    }
    elsif ( $type == $DATA_TYPE_JSON ) {
        $res = to_json( $data, $args{json}->%*, readable => $args{readable} );
    }
    elsif ( $type == $DATA_TYPE_CBOR ) {
        $res = to_cbor($data);
    }
    elsif ( $type == $DATA_TYPE_YAML ) {
        $res = to_yaml($data);
    }
    elsif ( $type == $DATA_TYPE_XML ) {
        $res = to_xml( $data, $args{xml}->%*, readable => $args{readable} );
    }
    elsif ( $type == $DATA_TYPE_INI ) {
        $res = to_ini($data);
    }
    else {
        die qq[Unknown serializer "$type"];
    }

    # compress
    if ( $args{compress} ) {
        if ( bytes::length $res >= $args{compress_threshold} ) {
            if ( $args{compress} == $DATA_COMPRESS_ZLIB ) {
                require Compress::Zlib;

                $res = Compress::Zlib::compress($res);
            }
            else {
                die qq[Unknown compressor type "$args{compress}"];
            }
        }
        else {
            $args{compress} = 0;
        }
    }

    # encrypt
    if ( defined $args{secret} ) {
        my $secret;

        if ( is_plain_arrayref $args{secret} ) {
            $secret = $args{secret}->[ $args{secret_index} ];
        }
        else {
            $secret = $args{secret};
        }

        if ( defined $secret ) {
            require Crypt::CBC;

            $res = Crypt::CBC->new(
                -key    => $secret,
                -cipher => $CIPHER_NAME->{ $args{cipher} },
            )->encrypt($res);
        }
        else {
            $args{secret} = undef;
        }
    }

    # encode
    if ( $args{encode} ) {
        if ( $args{encode} == $DATA_ENC_B64 ) {
            $res = to_b64u($res);
        }
        elsif ( $args{encode} == $DATA_ENC_HEX ) {
            $res = unpack 'H*', $res;
        }
        else {
            die qq[Unknown encoder "$args{encode}"];
        }
    }

    # add token
    if ( $args{token} ) {
        $res .= sprintf( '#%x', ( $args{compress} // 0 ) . ( defined $args{secret} ? $args{cipher} : 0 ) . ( $args{secret_index} // 0 ) . ( $args{encode} // 0 ) . $type ) . sprintf '#%x', bytes::length $res;
    }

    return $res;
}

# JSON data should be without UTF8 flag
# objects aren't deserialized automatically from JSON
sub decode_data ( $type, $data_ref, @args ) {
    $data_ref = \$_[1] if !is_ref $data_ref;

    my %args = (
        compress     => undef,
        secret       => undef,              # can be ArrayRef
        secret_index => 0,
        cipher       => $DATA_CIPHER_DES,
        encode       => undef,              # 0, 1 = 'hex', 'hex', 'b64'
        perl_ns      => undef,              # for PERL only, namespace for data evaluation
        json         => undef,              # HashRef with additional params for Cpanel::JSON::XS
        xml          => undef,              # HashRef with additional params for XML::Hash::XS
        return_token => 0,                  # return token
        @args,
        type => $type,
    );

    # parse token
    if ( $data_ref->$* =~ /#([[:xdigit:]]{1,8})#([[:xdigit:]]{1,16})\z/sm ) {
        my $token_len = 2 + length($1) + length $2;

        if ( bytes::length( $data_ref->$* ) - $token_len == hex $2 ) {
            $args{has_token} = 1;

            substr $data_ref->$*, -$token_len, $token_len, $EMPTY;

            ( $args{compress}, $args{cipher}, $args{secret_index}, $args{encode}, $type ) = split //sm, sprintf '%05s', hex $1;

            $args{type} = $type;
        }
    }

    # decode
    if ( $args{encode} ) {
        if ( $args{encode} == $DATA_ENC_B64 ) {
            $data_ref = \from_b64u( $data_ref->$* );
        }
        elsif ( $args{encode} == $DATA_ENC_HEX ) {
            $data_ref = \pack 'H*', $data_ref->$*;
        }
        else {
            die qq[Unknown encoder "$args{encode}"];
        }
    }

    # decrypt
    if ( $args{cipher} && defined $args{secret} ) {
        my $secret;

        if ( is_plain_arrayref $args{secret} ) {
            $secret = $args{secret}->[ $args{secret_index} ];
        }
        else {
            $secret = $args{secret};
        }

        if ( defined $secret ) {
            require Crypt::CBC;

            $data_ref = \Crypt::CBC->new(
                -key    => $secret,
                -cipher => $CIPHER_NAME->{ $args{cipher} },
            )->decrypt( $data_ref->$* );

        }
    }

    # decompress
    if ( $args{compress} ) {
        if ( $args{compress} == $DATA_COMPRESS_ZLIB ) {
            require Compress::Zlib;

            $data_ref = \Compress::Zlib::uncompress($data_ref);

            die if !defined $data_ref->$*;
        }
        else {
            die qq[Unknown compressor "$args{compressor}"];
        }
    }

    # decode
    my $res;

    if ( $type == $DATA_TYPE_PERL ) {
        $res = from_perl( $data_ref, perl_ns => $args{perl_ns} );
    }
    elsif ( $type == $DATA_TYPE_JSON ) {
        $res = from_json( $data_ref, $args{json}->%* );
    }
    elsif ( $type == $DATA_TYPE_CBOR ) {
        $res = from_cbor($data_ref);
    }
    elsif ( $type == $DATA_TYPE_YAML ) {
        $res = from_yaml($data_ref);
    }
    elsif ( $type == $DATA_TYPE_XML ) {
        $res = from_xml( $data_ref, $args{xml}->%* );
    }
    elsif ( $type == $DATA_TYPE_INI ) {
        $res = from_ini($data_ref);
    }
    else {
        die qq[Unknown serializer "$type"];
    }

    if ( wantarray && $args{return_token} ) {
        return $res, \%args;
    }
    else {
        return $res;
    }
}

# PERL
sub to_perl ( $data, %args ) {
    require Data::Dumper;    ## no critic qw[Modules::ProhibitEvilModules]

    state $sort_keys = sub {
        return [ nsort keys $_[0]->%* ];
    };

    my $res;

    if ( !defined $data ) {
        $res = 'undef';
    }
    else {
        no warnings qw[redefine];

        local $Data::Dumper::Indent     = 0;
        local $Data::Dumper::Purity     = 1;
        local $Data::Dumper::Pad        = $EMPTY;
        local $Data::Dumper::Terse      = 1;
        local $Data::Dumper::Deepcopy   = 0;
        local $Data::Dumper::Quotekeys  = 0;
        local $Data::Dumper::Pair       = '=>';
        local $Data::Dumper::Maxdepth   = 0;
        local $Data::Dumper::Deparse    = 0;
        local $Data::Dumper::Sparseseen = 1;
        local $Data::Dumper::Useperl    = 1;
        local $Data::Dumper::Useqq      = 1;
        local $Data::Dumper::Sortkeys   = $args{readable} ? $sort_keys : 0;
        local *Data::Dumper::qquote     = sub ( $str, $use_qqote ) { return escape_perl $str };

        $res = Data::Dumper->Dump( [$data] );
    }

    if ( $args{readable} ) {
        $res = P->src->decompress(
            path   => 'config.perl',    # mark file as perl config
            data   => $res,
            filter => {
                perl_tidy   => '--comma-arrow-breakpoints=0',
                perl_critic => 0,
            }
        )->{data};
    }

    return $res;
}

sub from_perl ( $data, %args ) {
    my $ns = $args{perl_ns} || '_Pcore::CONFIG::SANDBOX';

    $data = decode_utf8 is_plain_scalarref $data ? $data->$* : $data;

    my ( $tmp, $eval );

    if ( $data =~ /\A\s*use Filter::Crypto::Decrypt;/sm ) {
        $tmp = P->file1->tempfile;

        P->file->write_text( $tmp, $data );

        $eval = \"do '$tmp';";
    }
    else {
        $eval = \$data;
    }

    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
    my $res = eval <<"CODE";
package $ns;

$eval->$*;
CODE

    die $@ if $@;

    return $res;
}

# JSON
sub get_json ( @args ) {
    require Cpanel::JSON::XS;    ## no critic qw[Modules::ProhibitEvilModules]

    my %args = (
        allow_nonref    => 1,    # allow scalars
        allow_blessed   => 1,    # allow blessed objects
        convert_blessed => 1,    # use TO_JSON method of blessed objects
        allow_bignum    => 1,
        escape_slash    => 0,
        relaxed         => 1,
        @args,
    );

    my $json = Cpanel::JSON::XS->new;

    $json->$_( $args{$_} ) for keys %args;

    return $json;
}

sub to_json ( $data, %args ) {
    my $readable = delete $args{readable};

    if (%args) {
        return get_json(%args)->encode($data);
    }
    elsif ($readable) {
        state $json = get_json( utf8 => 1, canonical => 1, indent => 1, indent_length => 4, space_after => 1 );

        return $json->encode($data);
    }
    else {
        state $json = get_json( ascii => 1, utf8 => 1 );

        return $json->encode($data);
    }
}

sub from_json ( $data, %args ) {
    if (%args) {
        return get_json(%args)->decode( is_plain_scalarref $data ? $data->$* : $data );
    }
    else {
        state $json = get_json( utf8 => 1 );

        return $json->decode( is_plain_scalarref $data ? $data->$* : $data );
    }
}

# CBOR
sub get_cbor ( @args ) {
    require CBOR::XS;

    my %args = (
        max_depth      => 512,
        max_size       => 1024 * 1024 * 100,         # max. string size is unlimited
        allow_unknown  => 0,
        allow_sharing  => 0,                         # must be disable for compatibility with JS CBOR
        allow_cycles   => 1,
        pack_strings   => 0,                         # set to 1 affect speed, but makes size smaller
        validate_utf8  => 0,
        forbid_objects => 0,
        filter         => \&CBOR::XS::safe_filter,
        @args,
    );

    my $cbor = CBOR::XS->new;

    $cbor->$_( $args{$_} ) for keys %args;

    return $cbor;
}

sub to_cbor ( $data, @ ) {
    state $cbor = get_cbor();

    return $cbor->encode($data);
}

sub from_cbor ( $data, @ ) {
    state $cbor = get_cbor();

    return $cbor->decode( is_plain_scalarref $data ? $data->$* : $data );
}

# YAML
sub to_yaml ( $data, @ ) {
    require YAML::XS;

    local $YAML::XS::UseCode  = 0;
    local $YAML::XS::DumpCode = 0;
    local $YAML::XS::Indent   = 4;

    return YAML::XS::Dump($data);
}

sub from_yaml ( $data, @ ) {
    require YAML::XS;

    local $YAML::XS::LoadBlessed = 0;
    local $YAML::XS::UseCode     = 0;
    local $YAML::XS::LoadCode    = 0;

    return YAML::XS::Load( is_plain_scalarref $data ? $data->$* : $data );
}

# XML
sub get_xml (@args) {
    require XML::Hash::XS;

    my %args = (
        buf_size => 4096,         # buffer size for reading end encoding data
        content  => 'content',    # if defined that the key name for the text content(used only if use_attr=1)
        encoding => 'UTF-8',
        trim     => 1,            # trim leading and trailing whitespace from text nodes

        # to_xml
        canonical => 0,           # sort hash keys
        indent    => 0,
        method    => 'NATIVE',
        output    => undef,
        root      => 'root',
        use_attr  => 1,
        version   => '1.0',
        xml_decl  => 1,

        # from_xml
        force_array   => 1,
        force_content => 1,
        keep_root     => 1,
        max_depth     => 1_024,    # maximum recursion depth
        merge_text    => 1,

        @args,
    );

    return XML::Hash::XS->new(%args);
}

sub to_xml ( $data, %args ) {
    state $xml = get_xml();

    my $readable = delete $args{readable};

    if (%args) {
        return $xml->hash2xml( $data, %args );
    }
    else {
        my $root = ( keys $data->%* )[0];

        return $xml->hash2xml( $data->{$root}, root => $root, utf8 => 0, $readable ? ( canonical => 1, indent => 4 ) : () );
    }
}

sub from_xml ( $data, %args ) {
    state $xml = get_xml();

    if (%args) {
        return $xml->xml2hash( $data, %args );
    }
    else {
        return $xml->xml2hash( $data, utf8 => 1 );
    }
}

# INI
sub to_ini ( $data, @ ) {
    state $write_section = sub ( $buf, $section, $allow_hashref ) {
        for ( sort keys $section->%* ) {
            if ( !is_ref $section->{$_} ) {
                $buf->$* .= "$_=$section->{$_}\n";
            }
            elsif ( $allow_hashref && is_plain_hashref $section->{$_} ) {
                $buf->$* .= "\n" if $buf;

                $buf->$* .= "[$_]\n";

                __SUB__->( $buf, $section->{$_}, 0 );
            }
            else {
                die 'Unsupported reference type';
            }
        }

        return;
    };

    $write_section->( \my $buf, $data, 1 );

    encode_utf8 $buf;

    return $buf;
}

sub from_ini ( $data, @ ) {
    my $cfg = {};

    my @lines = grep { $_ ne $EMPTY } map { trim $_} split /\n/sm, decode_utf8 is_plain_scalarref $data ? $data->$* : $data;

    my $path = $cfg;

    for my $line (@lines) {

        # section
        if ( $line =~ /\A\[(.+)\]\z/sm ) {
            $path = $cfg->{$1} = {};
        }

        # not a section
        else {

            # comment
            if ( $line =~ /\A;/sm ) {
                next;
            }

            # variable
            else {
                my ( $key, $val ) = split /=/sm, $line, 2;

                if ( defined $val ) {
                    trim $val;

                    $val = undef if $val eq $EMPTY;
                }

                $path->{ trim $key} = $val;
            }
        }
    }

    return $cfg;
}

# BASE64
sub to_b64 : prototype($;$) {
    state $init = !!require MIME::Base64;

    return &MIME::Base64::encode_base64;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub to_b64u : prototype($) {
    state $init = !!require MIME::Base64::URLSafe;

    return &MIME::Base64::URLSafe::urlsafe_b64encode;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub from_b64 : prototype($) {
    state $init = !!require MIME::Base64;

    return &MIME::Base64::decode_base64;                 ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub from_b64u : prototype($) {
    state $init = !!require MIME::Base64::URLSafe;

    return &MIME::Base64::URLSafe::urlsafe_b64decode;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

# XOR
sub to_xor : prototype($$) ( $buf, $mask ) {
    no feature qw[bitwise];

    my $mlen = length $mask;

    # select mask length, max. mask length is 1K
    state $max_mlen = 1024;

    if ( length $buf > $max_mlen && $mlen < $max_mlen ) {
        $mask = $mask x int $max_mlen / $mlen;

        $mlen = length $mask;
    }

    my $tmp_buf = my $out = $EMPTY;

    $out .= $tmp_buf ^ $mask while length( $tmp_buf = substr $buf, 0, $mlen, $EMPTY ) == $mlen;

    $out .= $tmp_buf ^ substr $mask, 0, length $tmp_buf;

    return $out;
}

*from_xor = \&to_xor;

# URI - NOTE https://tools.ietf.org/html/rfc3986#appendix-A
use Inline(
    C => <<'C',

# define ALPHA                   "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
# define DIGIT                   "0123456789"
# define UNRESERVED              DIGIT ALPHA "-._~"
# define GEN_DELIMS              ":/?#[]@"
# define SUB_DELIMS              "!$&'()*+,;="
# define PCHAR                   UNRESERVED SUB_DELIMS ":@" // unreserved / pct-encoded / sub-delims / ":" / "@"

# define SAFE_URI_COMPONENT UNRESERVED                      // encode everything, same as encodeURIComponent
# define SAFE_SCHEME        DIGIT ALPHA "+-."               // ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
# define SAFE_USERINFO      UNRESERVED SUB_DELIMS ":"       // *( unreserved / pct-encoded / sub-delims / ":" )
# define SAFE_PATH          PCHAR "/"                       // *( pchar / "/" )
# define SAFE_QUERY_FRAG    PCHAR "/?"                      // *( pchar / "/" / "?" )

typedef struct {
    char inited;
    char map[256];
    const char* safe;
} URIEscapeMap;

static URIEscapeMap map_uri_component  = { .safe = SAFE_URI_COMPONENT };
static URIEscapeMap map_uri_scheme     = { .safe = SAFE_SCHEME };
static URIEscapeMap map_uri_path       = { .safe = SAFE_PATH };
static URIEscapeMap map_uri_query_frag = { .safe = SAFE_QUERY_FRAG };

static URIEscapeMap map_hexdigit   = { .safe = "0123456789abcdefABCDEF" };
static URIEscapeMap map_unreserved = { .safe = UNRESERVED };

static const char* escape_tbl[256] = {
    "%00","%01","%02","%03","%04","%05","%06","%07","%08","%09","%0A","%0B","%0C","%0D","%0E","%0F",
    "%10","%11","%12","%13","%14","%15","%16","%17","%18","%19","%1A","%1B","%1C","%1D","%1E","%1F",
    "%20","%21","%22","%23","%24","%25","%26","%27","%28","%29","%2A","%2B","%2C","%2D","%2E","%2F",
    "%30","%31","%32","%33","%34","%35","%36","%37","%38","%39","%3A","%3B","%3C","%3D","%3E","%3F",
    "%40","%41","%42","%43","%44","%45","%46","%47","%48","%49","%4A","%4B","%4C","%4D","%4E","%4F",
    "%50","%51","%52","%53","%54","%55","%56","%57","%58","%59","%5A","%5B","%5C","%5D","%5E","%5F",
    "%60","%61","%62","%63","%64","%65","%66","%67","%68","%69","%6A","%6B","%6C","%6D","%6E","%6F",
    "%70","%71","%72","%73","%74","%75","%76","%77","%78","%79","%7A","%7B","%7C","%7D","%7E","%7F",
    "%80","%81","%82","%83","%84","%85","%86","%87","%88","%89","%8A","%8B","%8C","%8D","%8E","%8F",
    "%90","%91","%92","%93","%94","%95","%96","%97","%98","%99","%9A","%9B","%9C","%9D","%9E","%9F",
    "%A0","%A1","%A2","%A3","%A4","%A5","%A6","%A7","%A8","%A9","%AA","%AB","%AC","%AD","%AE","%AF",
    "%B0","%B1","%B2","%B3","%B4","%B5","%B6","%B7","%B8","%B9","%BA","%BB","%BC","%BD","%BE","%BF",
    "%C0","%C1","%C2","%C3","%C4","%C5","%C6","%C7","%C8","%C9","%CA","%CB","%CC","%CD","%CE","%CF",
    "%D0","%D1","%D2","%D3","%D4","%D5","%D6","%D7","%D8","%D9","%DA","%DB","%DC","%DD","%DE","%DF",
    "%E0","%E1","%E2","%E3","%E4","%E5","%E6","%E7","%E8","%E9","%EA","%EB","%EC","%ED","%EE","%EF",
    "%F0","%F1","%F2","%F3","%F4","%F5","%F6","%F7","%F8","%F9","%FA","%FB","%FC","%FD","%FE","%FF",
};

static void __init_map ( URIEscapeMap *map ) {
    map->inited = 1;

    for( int i = 0; map->safe[i] != '\0'; i++ ) {
        map->map[ map->safe[i] ] = 1;
    }
}

static void __init_hexdigit () {
    map_hexdigit.inited = 1;

    for( int i = 0; i < 256; i++ ) {
        map_hexdigit.map[i] = 0xFF;
    }

    // 0 .. 9
    map_hexdigit.map[48] = 0;
    map_hexdigit.map[49] = 1;
    map_hexdigit.map[50] = 2;
    map_hexdigit.map[51] = 3;
    map_hexdigit.map[52] = 4;
    map_hexdigit.map[53] = 5;
    map_hexdigit.map[54] = 6;
    map_hexdigit.map[55] = 7;
    map_hexdigit.map[56] = 8;
    map_hexdigit.map[57] = 9;

    // A .. Z
    map_hexdigit.map[65] = 10;
    map_hexdigit.map[66] = 11;
    map_hexdigit.map[67] = 12;
    map_hexdigit.map[68] = 13;
    map_hexdigit.map[69] = 14;
    map_hexdigit.map[70] = 15;

    // a .. z
    map_hexdigit.map[97] = 10;
    map_hexdigit.map[98] = 11;
    map_hexdigit.map[99] = 12;
    map_hexdigit.map[100] = 13;
    map_hexdigit.map[101] = 14;
    map_hexdigit.map[102] = 15;

    return;
}

static SV *__to_uri ( SV *uri, URIEscapeMap *type ) {
    if ( !type->inited ) __init_map(type);

    /* call fetch() if a tied variable to populate the sv */
    SvGETMAGIC(uri);

    /* check for undef */
    if ( uri == &PL_sv_undef ) return newSV(0);

    U8 *src;
    size_t slen;

    /* copy the sv without the magic struct */
    src = SvPV_nomg_const(uri, slen);

    /* create result SV */
    SV *result = newSV( slen * 3 + 1 );
    SvPOK_on(result);

    size_t dlen = 0;
    U8 *dst = (U8 *)SvPV_nolen(result);

    for ( size_t i = 0; i < slen; i++ ) {
        if ( type->map[ src[i] ] ) {
            dst[dlen++] = src[i];
        }
        else{
            memcpy( &dst[dlen], escape_tbl[ src[i] ], 3 );

            dlen += 3;
        }
    }

    dst[dlen] = '\0'; /*  for sure; */

    /* set the current length of resutl */
    SvCUR_set(result, dlen);

    return result;
}

SV *to_uri_component (SV *uri) {
    return __to_uri( uri, &map_uri_component );
}

SV *to_uri_scheme (SV *uri) {
    return __to_uri( uri, &map_uri_scheme );
}

SV *to_uri_path (SV *uri) {
    return __to_uri( uri, &map_uri_path );
}

SV *to_uri_query_frag ( SV *uri ) {
    if ( !map_hexdigit.inited ) __init_hexdigit();

    if ( !map_unreserved.inited ) __init_map(&map_unreserved);

    if ( !map_uri_query_frag.inited ) __init_map(&map_uri_query_frag);

    /* call fetch() if a tied variable to populate the sv */
    SvGETMAGIC(uri);

    /* check for undef */
    if ( uri == &PL_sv_undef ) return newSV(0);

    U8 *src;
    size_t slen;

    /* copy the sv without the magic struct */
    src = SvPV_nomg_const(uri, slen);

    /* create result SV */
    SV *result = newSV( slen * 3 + 1 );
    SvPOK_on(result);

    size_t dlen = 0;
    U8 *dst = (U8 *)SvPV_nolen(result);

    for ( size_t i = 0; i < slen; i++ ) {

        // "%" character
        if ( src[i] == '%' ) {
            if ( i + 2 < slen ) {
                const unsigned char v1 = map_hexdigit.map[ (unsigned char) src[ i + 1 ] ];
                const unsigned char v2 = map_hexdigit.map[ (unsigned char) src[ i + 2 ] ];

                // valid pct sequence
                if ( (v1 | v2) != 0xFF) {

                    // decode %xx
                    const unsigned char c = (v1 << 4) | v2;

                    // char is unreserved, store as char
                    if ( map_unreserved.map[c] ) {
                        dst[ dlen++ ] = c;
                    }

                    // char is reserved, store as %xx seq.
                    else {
                        memcpy( &dst[dlen], escape_tbl[c], 3 );

                        dlen += 3;
                    }

                    i += 2;
                }

                // invalid pct seq., just escape "%"
                else {
                    memcpy( &dst[dlen], escape_tbl[ 0x25 ], 3 );

                    dlen += 3;
                }
            }

            // escape "%"
            else {
                memcpy( &dst[dlen], escape_tbl[ 0x25 ], 3 );

                dlen += 3;
            }
        }

        // character is allowed, copy as is
        else if ( map_uri_query_frag.map[ src[i] ] ) {
            dst[dlen++] = src[i];
        }

        // character is not allowed, percent encode
        else{
            memcpy( &dst[dlen], escape_tbl[ src[i] ], 3 );

            dlen += 3;
        }
    }

    dst[dlen] = '\0'; /*  for sure; */

    /* set the current length of resutl */
    SvCUR_set(result, dlen);

    return result;
}

SV *from_uri (SV *uri) {
    if ( !map_hexdigit.inited ) __init_hexdigit();

    /* call fetch() if a tied variable to populate the sv */
    SvGETMAGIC(uri);

    /* check for undef */
    if ( uri == &PL_sv_undef ) return newSV(0);

    U8 *src;
    size_t slen;

    /* copy the sv without the magic struct */
    src = SvPV_nomg_const(uri, slen);

    /* create result SV */
    SV *result = newSV(slen + 1);
    SvPOK_on(result);

    size_t dlen = 0;
    U8 *dst = (U8 *)SvPV_nolen(result);

    for ( size_t i = 0; i < slen; i++ ) {
        if ( src[i] == '%' && i + 2 < slen ) {
            const unsigned char v1 = map_hexdigit.map[ (unsigned char) src[ i + 1 ] ];
            const unsigned char v2 = map_hexdigit.map[ (unsigned char) src[ i + 2 ] ];

            /* skip invalid hex sequences */
            if ( (v1 | v2) != 0xFF) {
                dst[ dlen++ ] = (v1 << 4) | v2;

                i += 2;
            }
            else {
                dst[ dlen++ ] = '%';
            }
        }
        else {
            dst[ dlen++ ] = src[i];
        }
    }

    dst[ dlen ] = '\0';

    /* set the current length of resutl */
    SvCUR_set( result, dlen );

    return result;
}

SV *from_uri_utf8 (SV *uri) {
    SV *res = from_uri( uri );

    sv_utf8_decode(res);

    return res;
}

C
    ccflagsex  => '-Wall -Wextra -Ofast -std=c11',
    prototypes => 'ENABLE',
    prototype  => {
        to_uri_component  => '$',
        to_uri_scheme     => '$',
        to_uri_path       => '$',
        to_uri_query_frag => '$',
        from_uri          => '$',
        from_uri_utf8     => '$',
    },
);

sub to_uri : prototype($) ($data) {
    return to_uri_component $data if !is_ref $data;

    return to_uri_query($data);
}

sub to_uri_query : prototype($) ($data) {
    return to_uri_query_frag $data if !is_ref $data;

    $data = $data->get_hash if is_blessed_ref $data && $data->isa('Pcore::Util::Hash::Multivalue');

    my @res;

    if ( is_plain_arrayref $data ) {
        for ( my $i = 0; $i <= $data->$#*; $i += 2 ) {
            push @res, join q[=], defined $data->[$i] ? to_uri_component $data->[$i] : $EMPTY, defined $data->[ $i + 1 ] ? to_uri_component $data->[ $i + 1 ] : ();
        }
    }
    elsif ( is_plain_hashref $data) {
        while ( my ( $k, $v ) = each $data->%* ) {
            $k = to_uri_component $k;

            if ( ref $v ) {

                # value is ArrayRef
                for my $v1 ( $v->@* ) {
                    push @res, join q[=], $k, defined $v1 ? to_uri_component $v1 : ();
                }
            }
            else {
                push @res, join q[=], $k, defined $v ? to_uri_component $v : ();
            }
        }
    }
    else {
        die 'Unsupported ref type';
    }

    return join q[&], @res;
}

# always returns HashMultivalue
sub from_uri_query : prototype($) ($uri) {
    my $res = P->hash->multivalue;

    my $hash = $res->get_hash;

    for my $key ( split /&/sm, $_[0] ) {
        my $val;

        if ( ( my $idx = index $key, q[=] ) != -1 ) {
            $val = substr $key, $idx, length $key, $EMPTY;

            substr $val, 0, 1, $EMPTY;

            $val = from_uri $val;
        }

        $key = from_uri $key;

        push $hash->{$key}->@*, $val;
    }

    return $res;
}

sub from_uri_query_utf8 : prototype($) ($uri) {
    my $res = P->hash->multivalue;

    my $hash = $res->get_hash;

    for my $key ( split /&/sm, $_[0] ) {
        my $val;

        if ( ( my $idx = index $key, q[=] ) != -1 ) {
            $val = substr $key, $idx, length $key, $EMPTY;

            substr $val, 0, 1, $EMPTY;

            $val = from_uri_utf8 $val;
        }

        $key = from_uri_utf8 $key;

        push $hash->{$key}->@*, $val;
    }

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 48                   | * Subroutine "encode_data" with high complexity score (26)                                                     |
## |      | 159                  | * Subroutine "decode_data" with high complexity score (27)                                                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 |                      | ControlStructures::ProhibitPostfixControls                                                                     |
## |      | 367, 420             | * Postfix control "for" used                                                                                   |
## |      | 628                  | * Postfix control "while" used                                                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 963                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Data

=head1 SYNOPSIS

=head1 DESCRIPTION

JSON SERIALIZE

    ascii(1):
    - qq[\xA3] -> \u00A3, upgrded and encoded to UTF-8 character;
    - qq[£]    -> \u00A3, UTF-8 character;
    - qq[ᾥ]    -> \u1FA5, UTF-8 character;

    latin1(1):
    - qq[\xA3] -> qq[\xA3], encoded as bytes;
    - qq[£]    -> qq[\xA3], downgraded and encoded as bytes;
    - qq[ᾥ]    -> \u1FA5, downgrade impossible, encoded as UTF-8 character;

    utf8 - used only when ascii(0) and latin1(0);
    utf8(0) - upgrade scalar, UTF8 on, DO NOT USE, SERIALIZED DATA SHOULD ALWAYS BY WITHOUT UTF8 FLAG!!!!!!!!!!!!!!!!!!;
    - qq[\xA3] -> "£" (UTF8, multi-byte, len = 1, bytes::len = 2);
    - qq[£]    -> "£" (UTF8, multi-byte, len = 1, bytes::len = 2);
    - qq[ᾥ]    -> "ᾥ" (UTF8, multi-byte, len = 1, bytes::len = 3);

    utf8(1) - upgrade, encode scalar, UTF8 off;
    - qq[\xA3] -> "\xC2\xA3" (latin1, bytes::len = 2);
    - qq[£]    -> "\xC2\xA3" (latin1, bytes::len = 2);
    - qq[ᾥ]    -> "\xE1\xBE\xA5" (latin1, bytes::len = 3);

    So,
    - don't use latin1(1);
    - don't use utf8(0);

JSON DESERIALIZE

    utf8(0):
    - qq[\xA3]     -> "£", upgrade;
    - qq[£]        -> "£", as is;
    - qq[\xC2\xA3] -> "Â£", upgrade each byte, invalid;
    - qq[ᾥ]        -> error;

    utf8(1):
    - qq[\xA3]     -> "£", error, can't decode utf8;
    - qq[£]        -> "£", error, can't decode utf8;
    - qq[\xC2\xA3] -> "£", decode utf8;
    - qq[ᾥ]        -> error, can't decode utf8;

    So,
    - if data was encoded with utf8(0) - use utf8(0) to decode;
    - if data was encoded with utf8(1) - use utf8(1) to decode;

=cut
