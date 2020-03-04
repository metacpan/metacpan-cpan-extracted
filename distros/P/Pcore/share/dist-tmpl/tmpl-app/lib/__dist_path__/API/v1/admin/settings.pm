package <: $module_name ~ "::API::v1::admin::settings" :>;

use Pcore -const, -class, -sql;
use <: $module_name ~ "::Const qw[:PERMS]" :>;

extends qw[Pcore::App::API::Base];

with qw[Pcore::App::API::Role::Admin::Settings];

const our $API_NAMESPACE_PERMS => $PERMS_ADMIN;

around API_update => sub ( $orig, $self, $auth, $args ) {

    # $args->{use_proxy} = SQL_BOOL $args->{use_proxy} if defined $args->{use_proxy};

    return $self->$orig( $auth, $args );
};

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 4                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 21                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 25 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::admin::settings" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
