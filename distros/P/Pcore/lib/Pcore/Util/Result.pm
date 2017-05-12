package Pcore::Util::Result;

use Pcore -class, -export => [qw[result]];

with qw[Pcore::Util::Result::Status];

sub result ( $status, @ ) {
    my %args = @_ == 2 ? ( data => $_[1] ) : splice @_, 1;

    if ( ref $status eq 'ARRAY' ) {
        $args{status} = $status->[0];

        if ( ref $status->[1] eq 'HASH' ) {
            $args{reason} = get_reason( undef, $status->[0], $status->[1] );

            $args{status_reason} = $status->[1];
        }
        else {
            $args{reason} = $status->[1] // get_reason( undef, $status->[0], $status->[2] );

            $args{status_reason} = $status->[2];
        }
    }
    else {
        $args{status} = $status;

        $args{reason} = get_reason( undef, $status, undef );
    }

    return bless \%args, __PACKAGE__;
}

# allowed attributes:
# - data - default;
# - error - error message, or HashRef field_name => field_validation_error;
# - headers - HTTP headers;

sub TO_DATA ($self) {
    my $dump = { $self->%* };

    delete $dump->{status_reason};
    delete $dump->{headers};

    return $dump;
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
