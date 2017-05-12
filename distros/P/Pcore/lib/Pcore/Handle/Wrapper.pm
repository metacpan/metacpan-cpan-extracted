package Pcore::Handle::Wrapper;

use Pcore -role, -autoload;

with qw[Pcore::Handle];

requires qw[_connect _disconnect];

has h => ( is => 'lazy', isa => Object, builder => '_connect', predicate => 'is_connected', clearer => 1, init_arg => undef );

sub DEMOLISH ( $self, $global ) {
    $self->disconnect if $self->is_connected && !$global;

    return;
}

sub _AUTOLOAD ( $self, $method, @ ) {
    return <<"PERL";
        sub {
            my \$self = shift;

            return \$self->h->$method(\@_);
        };
PERL
}

sub connect ($self) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    if ( !$self->is_connected ) {
        $self->{h} = $self->_connect;
    }

    return;
}

sub disconnect ($self) {
    if ( $self->is_connected ) {
        $self->_disconnect;

        $self->clear_h;
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 17                   | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_AUTOLOAD' declared but not used    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::Wrapper

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
