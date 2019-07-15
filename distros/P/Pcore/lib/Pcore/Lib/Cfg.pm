package Pcore::Lib::Cfg;

use Pcore;
use Pcore::Lib::Text qw[encode_utf8];
use Pcore::Lib::Data qw[:TYPE encode_data decode_data];
use Pcore::Lib::Scalar qw[is_path];

our $EXT_TYPE_MAP = {
    perl => $DATA_TYPE_PERL,
    json => $DATA_TYPE_JSON,
    cbor => $DATA_TYPE_CBOR,
    yaml => $DATA_TYPE_YAML,
    yml  => $DATA_TYPE_YAML,
    xml  => $DATA_TYPE_XML,
    ini  => $DATA_TYPE_INI,
};

# type - can specify config type, if not defined - type will be get from file extension
# params - params, passed to template
sub read ( $path, %args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $type = delete $args{type};

    $path = P->path($path) if !is_path $path;

    die qq[Config file "$path" wasn't found.] if !-f $path;

    $type = $EXT_TYPE_MAP->{ $path->{suffix} } if !$type && defined $path->{suffix};

    my $data = \P->file->read_bin($path);

    if ( defined $args{params} ) {
        state $tmpl = P->tmpl;

        $data = $tmpl->( $data, $args{params} );
    }

    return decode_data( $type, $data, %args );
}

# type - can specify config type, if not defined - type will be get from file extension
sub write ( $path, $data, %args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $type = delete $args{type};

    $path = P->path($path) if !is_path $path;

    $type = $EXT_TYPE_MAP->{ $path->{suffix} } if !$type && defined $path->{suffix};

    P->file->write_bin( $path, encode_data( $type, $data, %args ) );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Cfg

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
