package Pcore::Util::Result::Status;

use Pcore -const, -role;
use Pcore::Util::Scalar qw[is_plain_arrayref is_plain_hashref];

use overload
  bool  => sub { $_[0]->{status} >= 200 && $_[0]->{status} < 300 },
  '0+'  => sub { $_[0]->{status} },
  q[""] => sub {"$_[0]->{status} $_[0]->{reason}"},
  '<=>' => sub { !$_[2] ? $_[0]->{status} <=> $_[1] : $_[1] <=> $_[0]->{status} },
  '@{}' => sub { [ $_[0]->{status}, $_[0]->{reason} ] },
  fallback => undef;

has status => ( is => 'ro', isa => PositiveOrZeroInt, required => 1 );
has reason => ( is => 'ro', isa => Str, required => 1 );

has status_reason => ( is => 'ro', isa => Maybe [HashRef] );

# http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
const our $STATUS_REASON => {
    0 => 'Unknown Status',

    # 100
    '1xx' => 'Informational',
    100   => 'Continue',
    101   => 'Switching Protocols',
    102   => 'Processing',

    # 200
    '2xx' => 'Success',
    200   => 'OK',
    201   => 'Created',
    202   => 'Accepted',
    203   => 'Non-Authoritative Information',
    204   => 'No Content',
    205   => 'Reset Content',
    206   => 'Partial Content',
    207   => 'Multi-Status',
    208   => 'Already Reported',
    226   => 'IM Used',

    # 300
    '3xx' => 'Redirection',
    300   => 'Multiple Choices',
    301   => 'Moved Permanently',
    302   => 'Found',
    303   => 'See Other',
    304   => 'Not Modified',
    305   => 'Use Proxy',
    307   => 'Temporary Redirect',
    308   => 'Permanent Redirect',

    # 400
    '4xx' => 'Client Error',
    400   => 'Bad Request',
    401   => 'Unauthorized',
    402   => 'Payment Required',
    403   => 'Forbidden',
    404   => 'Not Found',
    405   => 'Method Not Allowed',
    406   => 'Not Acceptable',
    407   => 'Proxy Authentication Required',
    408   => 'Request Timeout',
    409   => 'Conflict',
    410   => 'Gone',
    411   => 'Length Required',
    412   => 'Precondition Failed',
    413   => 'Payload Too Large',
    414   => 'URI Too Long',
    415   => 'Unsupported Media Type',
    416   => 'Range Not Satisfiable',
    417   => 'Expectation Failed',
    421   => 'Misdirected Request',
    422   => 'Unprocessable Entity',
    423   => 'Locked',
    424   => 'Failed Dependency',
    426   => 'Upgrade Required',
    428   => 'Precondition Required',
    429   => 'Too Many Requests',
    431   => 'Request Header Fields Too Large',
    451   => 'Unavailable For Legal Reasons',

    # 500
    '5xx' => 'Server Error',
    500   => 'Internal Server Error',
    501   => 'Not Implemented',
    502   => 'Bad Gateway',
    503   => 'Service Unavailable',
    504   => 'Gateway Timeout',
    505   => 'HTTP Version Not Supported',
    506   => 'Variant Also Negotiates',
    507   => 'Insufficient Storage',
    508   => 'Loop Detected',
    510   => 'Not Extended',
    511   => 'Network Authentication Required',
};

sub BUILDARGS ( $self, $args ) { return $args }

around BUILDARGS => sub ( $orig, $self, $args ) {
    $args->{status} //= 0;

    if ( is_plain_arrayref $args->{status} ) {
        if ( is_plain_hashref $args->{status}->[1] ) {
            $args->{status_reason} //= $args->{status}->[1];

            $args->{reason} //= get_reason( undef, $args->{status}->[0], $args->{status_reason} );
        }
        else {
            $args->{reason} //= $args->{status}->[1];

            $args->{status_reason} //= $args->{status}->[2];
        }

        $args->{status} = $args->{status}->[0];
    }
    elsif ( !defined $args->{reason} ) {
        $args->{reason} = get_reason( undef, $args->{status}, $args->{status_reason} );
    }

    return $self->$orig($args);
};

sub get_reason ( $self, $status, $status_reason = undef ) {
    if ( $status_reason && $status_reason->{$status} ) { return $status_reason->{$status} }
    elsif ( exists $STATUS_REASON->{$status} ) { return $STATUS_REASON->{$status} }
    elsif ( $status < 200 ) { return $STATUS_REASON->{'1xx'} }
    elsif ( $status >= 200 && $status < 300 ) { return $STATUS_REASON->{'2xx'} }
    elsif ( $status >= 300 && $status < 400 ) { return $STATUS_REASON->{'3xx'} }
    elsif ( $status >= 400 && $status < 500 ) { return $STATUS_REASON->{'4xx'} }
    else                                      { return $STATUS_REASON->{'5xx'} }
}

sub set_status ( $self, $status, $reason = undef ) {
    if ( is_plain_arrayref $status ) {
        $self->{status} = $status->[0];

        $self->{reason} = $reason // $status->[1];
    }
    else {
        $self->{status} = $status;

        $self->{reason} = $reason // get_reason( $self, $status, $self->{status_reason} );
    }

    return;
}

# STATUS METHODS
sub is_info ($self) {
    return $self->{status} < 200;
}

sub is_success ($self) {
    return $self->{status} >= 200 && $self->{status} < 300;
}

sub is_redirect ($self) {
    return $self->{status} >= 300 && $self->{status} < 400;
}

sub is_error ($self) {
    return $self->{status} >= 400;
}

sub is_client_error ($self) {
    return $self->{status} >= 400 && $self->{status} < 500;
}

sub is_server_error ($self) {
    return $self->{status} >= 500;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Result::Status

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
