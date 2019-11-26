package Pcore::Util::Result::Role;

use Pcore -role, -const;
use Pcore::Util::Scalar qw[is_res is_ref is_plain_arrayref is_plain_hashref];
use overload
  bool  => sub { substr( $_[0]->{status}, 0, 1 ) == 2 },
  '0+'  => sub { $_[0]->{status} },
  q[""] => sub {"$_[0]->{status} $_[0]->{reason}"},
  fallback => 1;

has status => ();
has reason => ();

sub IS_PCORE_RESULT ($self) { return 1 }

sub BUILDARGS ( $self, $args ) { return $args }

around BUILDARGS => sub ( $orig, $self, $args ) {
  REDO:
    if ( is_plain_arrayref $args->{status} ) {
        ( $args->{status}, $args->{reason} ) = $args->{status}->@*;

        goto REDO;
    }
    elsif ( is_res $args->{status} ) {
        $args->{reason} = $args->{status}->{reason};
        $args->{status} = $args->{status}->{status};
    }
    elsif ( defined $args->{status} ) {
        if ( !defined $args->{reason} ) {
            $args->{reason} = Pcore::Util::Result::resolve_reason( $args->{status}, $self->get_status_reason );
        }
        elsif ( is_plain_hashref $args->{reason} ) {
            $args->{reason} = Pcore::Util::Result::resolve_reason( $args->{status}, $args->{reason} );
        }
    }

    return $self->$orig($args);
};

sub get_status_reason ($self) {return}

sub set_status ( $self, $status, $reason = undef ) {

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
            $self->{reason} = Pcore::Util::Result::resolve_reason( $status, $self->get_status_reason );
        }
        elsif ( is_plain_hashref $reason) {
            $self->{reason} = Pcore::Util::Result::resolve_reason( $status, $reason );
        }
        else {
            $self->{reason} = $reason;
        }
    }

    return;
}

# STATUS METHODS
sub is_info ($self) { return substr( $_[0]->{status}, 0, 1 ) == 1 }

sub is_success ($self) { return substr( $_[0]->{status}, 0, 1 ) == 2 }

sub is_redirect ($self) { return substr( $_[0]->{status}, 0, 1 ) == 3 }

sub is_error ($self) { return substr( $_[0]->{status}, 0, 1 ) >= 4 }

sub is_client_error ($self) { return substr( $_[0]->{status}, 0, 1 ) == 4 }

sub is_server_error ($self) { return substr( $_[0]->{status}, 0, 1 ) >= 5 }

# SERIALIZE
sub TO_JSON ($self) { return { $self->%* } }

sub TO_CBOR ($self) { return { $self->%* } }

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Result::Role

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
