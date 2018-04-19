package Pcore::Util::Result;

use Pcore -export => [qw[res]];
use Pcore::Util::Result::Status;
use Pcore::Util::Scalar qw[is_plain_arrayref is_plain_hashref];
use Pcore::Util::Result::Status;

use overload    #
  q[bool] => sub {
    return substr( $_[0]->{status}, 0, 1 ) == 2;
  },
  q[0+] => sub {
    return $_[0]->{status};
  },
  q[""] => sub {
    return $_[0]->{status} . q[ ] . $_[0]->{reason};
  },
  fallback => 1;

# CONSTRUCTOR
sub res ( $status, @args ) {
    my $hash = @args % 2 ? { @args[ 1 .. $#args ], data => $args[0] } : {@args};

    my $self = bless $hash, __PACKAGE__;

    if ( is_plain_arrayref $status ) {
        $hash->{status} = $status->[0];

        if ( is_plain_hashref $status->[1] ) {
            $hash->{reason} = Pcore::Util::Result::Status::get_reason( undef, $status->[0], $status->[1] );
        }
        else {
            $hash->{reason} = $status->[1] // Pcore::Util::Result::Status::get_reason( undef, $status->[0], $status->[2] );
        }
    }
    else {
        $hash->{status} = $status;

        $hash->{reason} = Pcore::Util::Result::Status::get_reason( undef, $status, undef );
    }

    return $self;
}

sub get_standard_reason ( $status ) {
    $status = 0+ $status;

    if    ( exists $Pcore::Util::Result::Status::STATUS_REASON->{$status} ) { return $Pcore::Util::Result::Status::STATUS_REASON->{$status} }
    elsif ( $status < 200 )                                                 { return $Pcore::Util::Result::Status::STATUS_REASON->{'1xx'} }
    elsif ( $status < 300 )                                                 { return $Pcore::Util::Result::Status::STATUS_REASON->{'2xx'} }
    elsif ( $status < 400 )                                                 { return $Pcore::Util::Result::Status::STATUS_REASON->{'3xx'} }
    elsif ( $status < 500 )                                                 { return $Pcore::Util::Result::Status::STATUS_REASON->{'4xx'} }
    else                                                                    { return $Pcore::Util::Result::Status::STATUS_REASON->{'5xx'} }
}

# STATUS METHODS
sub is_info ($self) {
    return substr( $_[0]->{status}, 0, 1 ) == 1;
}

sub is_success ($self) {
    return substr( $_[0]->{status}, 0, 1 ) == 2;
}

sub is_redirect ($self) {
    return substr( $_[0]->{status}, 0, 1 ) == 3;
}

sub is_error ($self) {
    return substr( $_[0]->{status}, 0, 1 ) >= 4;
}

sub is_client_error ($self) {
    return substr( $_[0]->{status}, 0, 1 ) == 4;
}

sub is_server_error ($self) {
    return substr( $_[0]->{status}, 0, 1 ) >= 5;
}

# SERIALIZE
*TO_JSON = *TO_CBOR = sub ($self) {
    return { $_[0]->%* };
};

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Result

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
