package Pcore::Util::Data;

use Pcore -const, -export,
  { ALL   => [qw[encode_data decode_data]],
    PERL  => [qw[to_perl from_perl]],
    JSON  => [qw[to_json from_json]],
    CBOR  => [qw[to_cbor from_cbor]],
    YAML  => [qw[to_yaml from_yaml]],
    XML   => [qw[to_xml from_xml]],
    INI   => [qw[to_ini from_ini]],
    TOML  => [qw[to_toml from_toml]],
    B64   => [qw[to_b64 to_b64_url from_b64 from_b64_url]],
    B85   => [qw[to_b85 from_b85]],
    URI   => [qw[to_uri from_uri from_uri_query]],
    XOR   => [qw[to_xor from_xor]],
    CONST => [qw[$DATA_ENC_B64 $DATA_ENC_HEX $DATA_ENC_B85 $DATA_COMPRESS_ZLIB $DATA_CIPHER_DES]],
    TYPE  => [qw[$DATA_TYPE_PERL $DATA_TYPE_JSON $DATA_TYPE_CBOR $DATA_TYPE_YAML $DATA_TYPE_XML $DATA_TYPE_INI $DATA_TYPE_TOML]],
  };
use Pcore::Util::Text qw[decode_utf8 encode_utf8 escape_scalar trim];
use Pcore::Util::List qw[pairs];
use Sort::Naturally qw[nsort];
use Pcore::Util::Scalar qw[is_blessed_ref is_plain_scalarref is_plain_arrayref];
use URI::Escape::XS qw[];    ## no critic qw[Modules::ProhibitEvilModules]

const our $DATA_TYPE_PERL => 1;
const our $DATA_TYPE_JSON => 2;
const our $DATA_TYPE_CBOR => 3;
const our $DATA_TYPE_YAML => 4;
const our $DATA_TYPE_XML  => 5;
const our $DATA_TYPE_INI  => 6;
const our $DATA_TYPE_TOML => 7;

const our $DATA_ENC_B64 => 1;
const our $DATA_ENC_HEX => 2;
const our $DATA_ENC_B85 => 3;

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
sub encode_data ( $type, $data, @ ) {
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
        splice @_, 2,
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
    elsif ( $type == $DATA_TYPE_TOML ) {
        $res = to_toml($data);
    }
    else {
        die qq[Unknown serializer "$type"];
    }

    # compress
    if ( $args{compress} ) {
        if ( bytes::length $res->$* >= $args{compress_threshold} ) {
            if ( $args{compress} == $DATA_COMPRESS_ZLIB ) {
                state $init = !!require Compress::Zlib;

                $res = \Compress::Zlib::compress( $res->$* );
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
            state $init = !!require Crypt::CBC;

            $res = \Crypt::CBC->new(
                -key    => $secret,
                -cipher => $CIPHER_NAME->{ $args{cipher} },
            )->encrypt( $res->$* );
        }
        else {
            $args{secret} = undef;
        }
    }

    # encode
    if ( $args{encode} ) {
        if ( $args{encode} == $DATA_ENC_B64 ) {
            $res = \to_b64_url( $res->$* );
        }
        elsif ( $args{encode} == $DATA_ENC_HEX ) {
            $res = \unpack 'H*', $res->$*;
        }
        elsif ( $args{encode} == $DATA_ENC_B85 ) {
            $res = \to_b85( $res->$* );
        }
        else {
            die qq[Unknown encoder "$args{encode}"];
        }
    }

    # add token
    if ( $args{token} ) {
        $res->$* .= sprintf( '#%x', ( $args{compress} // 0 ) . ( defined $args{secret} ? $args{cipher} : 0 ) . ( $args{secret_index} // 0 ) . ( $args{encode} // 0 ) . $type ) . sprintf '#%x', bytes::length $res->$*;
    }

    return $res;
}

# JSON data should be without UTF8 flag
# objects aren't deserialized automatically from JSON
sub decode_data ( $type, @ ) {
    my $data_ref = ref $_[1] ? $_[1] : \$_[1];

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
        splice( @_, 2 ),
        type => $type,
    );

    # parse token
    if ( $data_ref->$* =~ /#([[:xdigit:]]{1,8})#([[:xdigit:]]{1,16})\z/sm ) {
        my $token_len = 2 + length($1) + length $2;

        if ( bytes::length( $data_ref->$* ) - $token_len == hex $2 ) {
            $args{has_token} = 1;

            substr $data_ref->$*, -$token_len, $token_len, q[];

            ( $args{compress}, $args{cipher}, $args{secret_index}, $args{encode}, $type ) = split //sm, sprintf '%05s', hex $1;

            $args{type} = $type;
        }
    }

    # decode
    if ( $args{encode} ) {
        if ( $args{encode} == $DATA_ENC_B64 ) {
            $data_ref = \from_b64_url( $data_ref->$* );
        }
        elsif ( $args{encode} == $DATA_ENC_HEX ) {
            $data_ref = \pack 'H*', $data_ref->$*;
        }
        elsif ( $args{encode} == $DATA_ENC_B85 ) {
            $data_ref = \from_b85( $data_ref->$* );
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
            state $init = !!require Crypt::CBC;

            $data_ref = \Crypt::CBC->new(
                -key    => $secret,
                -cipher => $CIPHER_NAME->{ $args{cipher} },
            )->decrypt( $data_ref->$* );

        }
    }

    # decompress
    if ( $args{compress} ) {
        if ( $args{compress} == $DATA_COMPRESS_ZLIB ) {
            state $init = !!require Compress::Zlib;

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
    elsif ( $type == $DATA_TYPE_TOML ) {
        $res = from_toml($data_ref);
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
    state $init = !!require Data::Dumper;

    state $sort_keys = sub {
        return [ nsort keys $_[0]->%* ];
    };

    local $Data::Dumper::Indent     = 0;
    local $Data::Dumper::Purity     = 1;
    local $Data::Dumper::Pad        = q[];
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

    my $res;

    if ( !defined $data ) {
        $res = \'undef';
    }
    else {
        no warnings qw[redefine];

        local *Data::Dumper::qquote = sub {
            return q["] . encode_utf8( escape_scalar $_[0] ) . q["];
        };

        $res = \Data::Dumper->Dump( [$data] );
    }

    if ( $args{readable} ) {
        state $init1 = !!require Pcore::Src::File;

        $res = Pcore::Src::File->new(
            {   action      => $Pcore::Src::SRC_DECOMPRESS,
                path        => 'config.perl',                 # mark file as perl config
                is_realpath => 0,
                in_buffer   => $res,
                filter_args => {
                    perl_tidy   => '--comma-arrow-breakpoints=0',
                    perl_critic => 0,
                },
            }
        )->run->out_buffer;
    }

    return $res;
}

sub from_perl ( $data, %args ) {
    my $ns = $args{perl_ns} || '_Pcore::CONFIG::SANDBOX';

    $data = decode_utf8 is_plain_scalarref $data ? $data->$* : $data;

    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
    my $res = eval <<"CODE";
package $ns;

use Pcore -config;

$data
CODE
    die $@ if $@;

    die q[Config must return value] unless $res;

    return $res;
}

# JSON
sub get_json ( @args ) {
    state $init = !!require Cpanel::JSON::XS;

    my %args = (
        allow_nonref    => 1,    # allow scalars
        allow_blessed   => 1,    # allow blessed objects
        convert_blessed => 1,    # use TO_JSON method of blessed objects
        allow_bignum    => 1,
        escape_slash    => 1,
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
        return \get_json(%args)->encode($data);
    }
    elsif ($readable) {
        state $json = get_json( utf8 => 1, canonical => 1, indent => 1, space_after => 1 );

        return \$json->encode($data);
    }
    else {
        state $json = get_json( ascii => 1, utf8 => 1 );

        return \$json->encode($data);
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
    state $init = !!require CBOR::XS;

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

    return \$cbor->encode($data);
}

sub from_cbor ( $data, @ ) {
    state $cbor = get_cbor();

    return $cbor->decode( is_plain_scalarref $data ? $data->$* : $data );
}

# YAML
sub to_yaml ( $data, @ ) {
    state $init = !!require YAML::XS;

    local $YAML::XS::UseCode  = 0;
    local $YAML::XS::DumpCode = 0;
    local $YAML::XS::LoadCode = 0;

    return \YAML::XS::Dump($data);
}

sub from_yaml ( $data, @ ) {
    state $init = !!require YAML::XS;

    local $YAML::XS::UseCode  = 0;
    local $YAML::XS::DumpCode = 0;
    local $YAML::XS::LoadCode = 0;

    return YAML::XS::Load( is_plain_scalarref $data ? $data->$* : $data );
}

# XML
sub get_xml (@args) {
    state $init = !!require XML::Hash::XS;

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
        return \$xml->hash2xml( $data, %args );
    }
    else {
        my $root = ( keys $data->%* )[0];

        return \$xml->hash2xml( $data->{$root}, root => $root, utf8 => 0, $readable ? ( canonical => 1, indent => 4 ) : () );
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
    my $str = q[];

    state $write_section = sub ( $str_ref, $section, $data ) {
        if ($section) {
            $str_ref->$* .= "\n" x 2 if $str_ref->$*;

            $str_ref->$* .= "[$section]";
        }

        for my $key ( sort keys $data->%* ) {
            $str_ref->$* .= "\n" if $str_ref->$*;

            $str_ref->$* .= "$key = " . ( defined $data->{$key} ? "$data->{$key}" : q[] );
        }

        return;
    };

    if ( exists $data->{_} ) {
        $write_section->( \$str, q[], $data->{_} );
    }

    for my $section ( sort grep { $_ ne '_' } keys $data->%* ) {
        $write_section->( \$str, $section, $data->{$section} );
    }

    encode_utf8 $str;

    return \$str;
}

sub from_ini ( $data, @ ) {
    my $cfg;

    my $section = '_';

    my @lines = grep { $_ ne q[] } map { trim $_} split /\n/sm, decode_utf8 is_plain_scalarref $data ? $data->$* : $data;

    for my $line (@lines) {

        # section
        if ( $line =~ /\A\[(.+)\]\z/sm ) {
            $section = $1;

            $cfg->{$section} = {} if !exists $cfg->{$section};
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

                    $val = undef if $val eq q[];
                }

                $cfg->{$section}->{ trim $key} = $val;
            }
        }
    }

    return $cfg;
}

# TOML
sub to_toml ( $data, @ ) {
    state $init = !!require TOML;

    return \TOML::to_toml($data);
}

sub from_toml ( $data, @ ) {
    state $init = !!require TOML;

    return TOML::from_toml( $data->$* );
}

# BASE64
sub to_b64 {
    state $init = !!require MIME::Base64;

    return &MIME::Base64::encode_base64;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub to_b64_url {
    state $init = !!require MIME::Base64;

    return &MIME::Base64::encode_base64url;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub from_b64 {
    state $init = !!require MIME::Base64;

    return &MIME::Base64::decode_base64;       ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub from_b64_url {
    state $init = !!require MIME::Base64;

    return &MIME::Base64::decode_base64url;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

# BASE85
sub to_b85 {
    state $init = !!require Convert::Ascii85;

    state $args = { compress_zero => 1, compress_space => 1 };

    return Convert::Ascii85::ascii85_encode( $_[0], $args );
}

sub from_b85 {
    state $init = !!require Convert::Ascii85;

    return &Convert::Ascii85::ascii85_decode;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

# URI
sub to_uri {
    if ( ref $_[0] ) {
        my $data = is_blessed_ref $_[0] && $_[0]->isa('Pcore::Util::Hash::Multivalue') ? $_[0]->get_hash : $_[0];

        my @res;

        if ( is_plain_arrayref $data ) {
            for ( my $i = 0; $i <= $data->$#*; $i += 2 ) {
                push @res, join q[=], defined $data->[$i] ? URI::Escape::XS::encodeURIComponent( $data->[$i] ) : q[], defined $data->[ $i + 1 ] ? URI::Escape::XS::encodeURIComponent( $data->[ $i + 1 ] ) : ();
            }
        }
        else {
            while ( my ( $k, $v ) = each $data->%* ) {
                $k = URI::Escape::XS::encodeURIComponent($k);

                if ( ref $v ) {

                    # value is ArrayRef
                    for my $v1 ( $v->@* ) {
                        push @res, join q[=], $k, defined $v1 ? URI::Escape::XS::encodeURIComponent($v1) : ();
                    }
                }
                else {
                    push @res, join q[=], $k, defined $v ? URI::Escape::XS::encodeURIComponent($v) : ();
                }
            }
        }

        return join q[&], @res;
    }
    else {
        return URI::Escape::XS::encodeURIComponent( $_[0] );
    }
}

# always return scalar string
sub from_uri {
    my %args = (
        encoding => 'UTF-8',
        splice @_, 1,
    );

    my $u = URI::Escape::XS::decodeURIComponent( $_[0] );

    if ( $args{encoding} ) {
        state $encoding = {};

        $encoding->{ $args{encoding} } //= Encode::find_encoding( $args{encoding} );

        eval { $u = $encoding->{ $args{encoding} }->decode( $u, Encode::FB_CROAK | Encode::LEAVE_SRC ); 1; } or do {
            utf8::upgrade($u) if $@;
        };
    }

    if ( defined wantarray ) {
        return $u;
    }
    else {
        $_[0] = $u;

        return;
    }
}

# always return HashMultivalue
sub from_uri_query {
    my %args = (
        encoding => 'UTF-8',
        splice @_, 1,
    );

    my $enc;

    if ( $args{encoding} ) {
        state $encoding = {};

        $encoding->{ $args{encoding} } //= Encode::find_encoding( $args{encoding} );

        $enc = $encoding->{ $args{encoding} };
    }

    my $res = P->hash->multivalue;

    my $hash = $res->get_hash;

    for my $key ( split /&/sm, $_[0] ) {
        my $val;

        if ( ( my $idx = index $key, q[=] ) != -1 ) {
            $val = substr $key, $idx, length $key, q[];

            substr $val, 0, 1, q[];

            $val = URI::Escape::XS::decodeURIComponent($val);
        }

        $key = URI::Escape::XS::decodeURIComponent($key);

        if ($enc) {

            # decode key
            eval { $key = $enc->decode( $key, Encode::FB_CROAK | Encode::LEAVE_SRC ); 1; } or do {
                utf8::upgrade($key) if $@;
            };

            # decode value
            if ( defined $val ) {
                eval { $val = $enc->decode( $val, Encode::FB_CROAK | Encode::LEAVE_SRC ); 1; } or do {
                    utf8::upgrade($val) if $@;
                };
            }
        }

        push $hash->{$key}->@*, $val;
    }

    if ( defined wantarray ) {
        return $res;
    }
    else {
        $_[0] = $res;

        return;
    }
}

# XOR
sub to_xor ( $buf, $mask ) {
    no feature qw[bitwise];

    my $mlen = length $mask;

    # select mask length, max. mask length is 1K
    state $max_mlen = 1024;

    if ( length $buf > $max_mlen && $mlen < $max_mlen ) {
        $mask = $mask x int $max_mlen / $mlen;

        $mlen = length $mask;
    }

    my $tmp_buf = my $out = q[];

    $out .= $tmp_buf ^ $mask while length( $tmp_buf = substr $buf, 0, $mlen, q[] ) == $mlen;

    $out .= $tmp_buf ^ substr $mask, 0, length $tmp_buf;

    return $out;
}

*from_xor = \&to_xor;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 51                   | * Subroutine "encode_data" with high complexity score (28)                                                     |
## |      | 168                  | * Subroutine "decode_data" with high complexity score (29)                                                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 76, 255              | ControlStructures::ProhibitCascadingIfElse - Cascading if-elsif chain                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 |                      | ControlStructures::ProhibitPostfixControls                                                                     |
## |      | 380, 433             | * Postfix control "for" used                                                                                   |
## |      | 802                  | * Postfix control "while" used                                                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 666                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
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
