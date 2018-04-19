package Pcore::WebSocket::Protocol::pcore::Request;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_blessed_ref];

use overload    #
  q[&{}] => sub ( $self, @ ) {
    return sub { return _respond( $self, @_ ) };
  },
  fallback => 1;

has _cb => ( is => 'ro', isa => Maybe [CodeRef] );

has _responded => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );    # already responded

P->init_demolish(__PACKAGE__);

sub DEMOLISH ( $self, $global ) {
    if ( !$global && !$self->{_responded} && $self->{_cb} ) {

        # API request object destroyed without return any result, this is possible run-time error in AE callback
        _respond( $self, 500 );
    }

    return;
}

sub IS_CALLBACK ($self) {
    return 1;
}

sub _respond ( $self, @ ) {
    die q[Already responded] if $self->{_responded};

    $self->{_responded} = 1;

    # remove callback
    if ( my $cb = delete $self->{_cb} ) {

        # return response, if callback is defined
        $cb->( is_blessed_ref $_[1] ? $_[1] : res splice @_, 1 );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebSocket::Protocol::pcore::Request

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
