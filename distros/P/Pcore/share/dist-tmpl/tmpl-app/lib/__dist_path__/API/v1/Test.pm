package <: $module_name ~ "::API::v1::Test" :>;

use Pcore -const, -class, -sql, -res;
use <: $module_name ~ "::Const qw[:PERMS]" :>;

extends qw[Pcore::App::API::Base];

const our $API_NAMESPACE_PERMS => undef;

sub API_test ( $self, $auth, @ ) {
    return 200;
}

sub API_test1 : Perms('$PERMS_ANY_AUTHENTICATED_USER') ( $self, $auth, @ ) {
    return 200;
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
## |    1 | 20                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 24 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Test" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
