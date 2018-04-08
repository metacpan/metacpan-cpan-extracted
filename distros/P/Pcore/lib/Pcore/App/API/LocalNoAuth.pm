package Pcore::App::API::LocalNoAuth;

use Pcore -class, -result;

with qw[Pcore::App::API];

sub init ( $self, $cb ) {
    $cb->( result 200 );

    return;
}

# AUTHENTICATE
sub authenticate ( $self, $user_name_utf8, $token, $cb ) {
    $cb->( bless { app => $self->{app} }, 'Pcore::App::API::Auth' );

    return;
}

sub authenticate_private ( $self, $private_token, $cb ) {
    $cb->( bless { app => $self->{app} }, 'Pcore::App::API::Auth' );

    return;
}

sub do_authenticate_private ( $self, $private_token, $cb ) {
    $cb->( result [ 404, 'User not found' ] );

    return;
}

# USER
sub create_user ( $self, $user_name, $password, $enabled, $permissions, $cb ) {

    # user already exists
    $cb->( result [ 400, 'Auth backend is not available' ] );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 14, 33               | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::LocalNoAuth

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
