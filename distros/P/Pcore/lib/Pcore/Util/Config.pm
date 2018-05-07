package Pcore::Util::Config;

use Pcore -const;
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::Data qw[:TYPE encode_data decode_data];

const our $EXT_TYPE_MAP => {
    perl => $DATA_TYPE_PERL,
    json => $DATA_TYPE_JSON,
    cbor => $DATA_TYPE_CBOR,
    yaml => $DATA_TYPE_YAML,
    yml  => $DATA_TYPE_YAML,
    xml  => $DATA_TYPE_XML,
    ini  => $DATA_TYPE_INI,
};

sub read ( $cfg, @ ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my %args = (
        type => undef,
        splice @_, 1,
    );

    my $type = delete $args{type};

    if ( !ref $cfg ) {
        die qq[Config file "$cfg" wasn't found.] if !-f $cfg;

        $type = $EXT_TYPE_MAP->{$1} if !$type && $cfg =~ /[.]([^.]+)\z/sm;

        $cfg = P->file->read_bin($cfg);
    }
    else {
        encode_utf8 $cfg->$*;
    }

    $type //= $DATA_TYPE_PERL;

    return decode_data( $type, $cfg, %args );
}

sub write ( $path, $cfg, @ ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my %args = (
        type => undef,
        splice @_, 2,
    );

    my $type = delete $args{type};

    $type = $EXT_TYPE_MAP->{$1} if !$type && $path =~ /[.]([^.]+)\z/sm;

    $type //= $DATA_TYPE_PERL;

    P->file->write_bin( $path, encode_data( $type, $cfg, %args ) );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 49                   | RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Config

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
