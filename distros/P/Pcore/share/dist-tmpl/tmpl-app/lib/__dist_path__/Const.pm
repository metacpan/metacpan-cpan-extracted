package <: $module_name ~ "::Const" :>;

use Pcore -const, -export;

our $EXPORT = { CONST => [qw[$USER_ACTION_TOKEN_EMAIL $USER_ACTION_TOKEN_PASSWORD]] };

const our $USER_ACTION_TOKEN_EMAIL    => 1;
const our $USER_ACTION_TOKEN_PASSWORD => 2;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 12                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 16 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name :>::Const

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
