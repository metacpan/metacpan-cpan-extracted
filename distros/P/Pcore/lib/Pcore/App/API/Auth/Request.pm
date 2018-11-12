package Pcore::App::API::Auth::Request;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_res];

use overload    #
  q[&{}] => sub ( $self, @ ) {
    return sub { return _respond( $self, @_ ) };
  },
  fallback => 1;

has auth       => ( required => 1 );       # InstanceOf ['Pcore::App::API::Auth']
has _cb        => ();                      # Maybe [CodeRef]
has _responded => 0, init_arg => undef;    # Bool, already responded

sub DESTROY ( $self ) {
    if ( ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) && !$self->{_responded} && $self->{_cb} ) {

        # API request object destroyed without return any result, this is possible run-time error in AE callback
        _respond( $self, 500 );
    }

    return;
}

sub IS_PCORE_CALLBACK ($self) { return 1 }

sub api_can_call ( $self, $method_id, $cb ) {
    $self->{auth}->api_can_call( $method_id, $cb );

    return;
}

sub api_call ( $self, $method_id, @args ) {
    return $self->{auth}->api_call( $method_id, @args );
}

sub _respond ( $self, @ ) {
    die q[Already responded] if $self->{_responded};

    $self->{_responded} = 1;

    # remove callback
    if ( my $cb = delete $self->{_cb} ) {

        # return response, if callback is defined
        $cb->( is_res $_[1] ? $_[1] : res splice @_, 1 );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Auth::Request

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
