package Pcore::App::API::LocalNoAuth;

use Pcore -class, -result;

with qw[Pcore::App::API];

sub init ( $self, $cb ) {
    $cb->( result 200 );

    return;
}

sub authenticate_private ( $self, $private_token, $cb ) {
    ...;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 14                   | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
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
