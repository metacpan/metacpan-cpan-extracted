package Pcore::App::Auth::Backend::NoAuth;

use Pcore -class, -res;

with qw[Pcore::App::Auth];

sub init ( $self ) {
    return res 200;
}

# AUTHENTICATE
sub authenticate ( $self, $user_name_utf8, $token, $cb ) {
    $cb->( bless { app => $self->{app} }, 'Pcore::App::Auth::Descriptor' );

    return;
}

sub authenticate_private ( $self, $private_token, $cb ) {
    $cb->( bless { app => $self->{app} }, 'Pcore::App::Auth::Descriptor' );

    return;
}

sub do_authenticate_private ( $self, $private_token ) {
    return res [ 404, 'User not found' ];
}

# USER
sub create_user ( $self, $user_name, $password, $enabled, $permissions ) {

    # user already exists
    return res [ 400, 'Auth backend is not available' ];
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 12, 29               | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Auth::Backend::NoAuth

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
