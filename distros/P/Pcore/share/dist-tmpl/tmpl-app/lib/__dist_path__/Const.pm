package <: $module_name ~ "::Const" :>;

use Pcore -const, -export;
use Pcore::App::API qw[:PERMS];

our $EXPORT = {
    PERMS  => [qw[$PERMS_ANY_AUTHENTICATED_USER $PERMS_ADMIN $PERMS_USER]],
    AVATAR => [qw[$DEFAULT_GRAVATAR_IMAGE $DEFAULT_AVATAR]],
};

# PERMISSIONS
const our $PERMS_ADMIN => 'admin';
const our $PERMS_USER  => 'user';
const our $PERMS       => [ $PERMS_ADMIN, $PERMS_USER ];

# AVATAR
const our $DEFAULT_GRAVATAR_IMAGE => 'identicon';                                                                                   # url encoded url or 404, mp, identicon, monsterid, wavatar, retro, robohash, blank, used if email is provided, but has no gravatar associated
const our $DEFAULT_AVATAR         => "https://s.gravatar.com/avatar/4732e01b487869e3e6d42c2720468036?d=$DEFAULT_GRAVATAR_IMAGE";    # noname@softvisio.net, used if no user email is provided

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 22                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 26 does not match the package declaration       |
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
