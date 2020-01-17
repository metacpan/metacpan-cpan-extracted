package <: $module_name ~ "::API::v1::Admin::Users" :>;

use Pcore -const, -class;
use <: $module_name ~ "::Const qw[:PERMS :AVATAR]" :>;

extends qw[Pcore::App::API::Base];

with qw[Pcore::App::API::Role::Admin::Users];

const our $API_NAMESPACE_PERMS => [$PERMS_ADMIN];

has default_gravatar       => $DEFAULT_AVATAR;
has default_gravatar_image => $DEFAULT_GRAVATAR_IMAGE;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 4                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 17                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 21 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Admin::Users" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
