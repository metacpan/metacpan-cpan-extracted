package Pcore::Util::Result;

use Pcore -export, -const;
use Pcore::Util::Scalar qw[is_res is_plain_arrayref is_plain_hashref];
use Pcore::Util::Result::Class;

our $EXPORT = [qw[res]];

our $STATUS_REASON;

const our $STATUS_CATEGORY => [    #
    'Unknown Status',              # 0
    'Informational',               # 1xx
    'Success',                     # 2xx
    'Redirection',                 # 3xx
    'Client Error',                # 4xx
    'Server Error',                # 5xx
];

sub update ($cb = undef) {
    print 'updating status.yaml ... ';

    return P->http->get(
        'https://www.iana.org/assignments/http-status-codes/http-status-codes-1.csv',
        sub ($res) {
            if ($res) {
                my $data;

                for my $line ( split /\n\r?/sm, $res->{data}->$* ) {
                    my ( $status, $reason ) = split /,/sm, $line;

                    $data->{$status} = $reason if $status =~ /\A\d\d\d\z/sm;
                }

                local $YAML::XS::QuoteNumericStrings = 0;

                $ENV->{share}->write( 'Pcore', 'data/status.yaml', $data );

                $STATUS_REASON = $data;
            }

            say $res;

            $cb->($res) if $cb;

            return $res;
        }
    );
}

sub _load_data {
    $STATUS_REASON = $ENV->{share}->read_cfg( 'Pcore', 'data', 'status.yaml' );

    return;
}

sub res ( $status, @args ) {
    my $self = @args % 2 ? { @args[ 1 .. $#args ], data => $args[0] } : {@args};

    $self = bless $self, 'Pcore::Util::Result::Class';

    my $reason;

  REDO:
    if ( is_plain_arrayref $status) {
        ( $status, $reason ) = $status->@*;

        goto REDO;
    }
    elsif ( is_res $status) {
        $self->{status} = $status->{status};

        $self->{reason} = $status->{reason};
    }
    else {
        $self->{status} = $status;

        if ( !defined $reason ) {
            $self->{reason} = resolve_reason($status);
        }
        elsif ( is_plain_hashref $reason) {
            $self->{reason} = resolve_reason( $status, $reason );
        }
        else {
            $self->{reason} = $reason;
        }
    }

    return $self;
}

sub resolve_reason ( $status, $status_reason = undef ) {
    _load_data() if !defined $STATUS_REASON;

    if ( $status_reason && $status_reason->{$status} ) { return $status_reason->{$status} }
    elsif ( exists $STATUS_REASON->{$status} ) { return $STATUS_REASON->{$status} }
    elsif ( $status < 200 ) { return $STATUS_CATEGORY->[1] }
    elsif ( $status >= 200 && $status < 300 ) { return $STATUS_CATEGORY->[2] }
    elsif ( $status >= 300 && $status < 400 ) { return $STATUS_CATEGORY->[3] }
    elsif ( $status >= 400 && $status < 500 ) { return $STATUS_CATEGORY->[4] }
    else                                      { return $STATUS_CATEGORY->[5] }
}

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
