package <: $module_name ~ "::RPC::Worker" :>;

use Pcore -rpc, -class, -const;
use <: $module_name ~ "::Const qw[:CONST]" :>;

with qw[<: $module_name ~ "::RPC" :>];

const our $RPC_LISTEN_EVENTS  => [];
const our $RPC_FORWARD_EVENTS => [];

sub BUILD ( $self, $args ) {
    return;
}

sub RPC_ON_CONNECT ( $self, $ws ) {
    return;
}

sub RPC_ON_DISCONNECT ( $self, $ws, $status ) {
    return;
}

sub RPC_ON_TERM ($self) {
    return;
}

sub API_test ( $self, $req, @args ) {
    $req->( 200, time );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 4                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 47                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 51 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::RPC::Worker" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
