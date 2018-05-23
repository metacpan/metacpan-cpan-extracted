package <: $module_name ~ "::Index::Admin" :>;

use Pcore -class;

with qw[Pcore::App::Controller::Ext];

has ext_app            => 'Ext';
has ext_app_title      => l10n('App Title');
has ext_default_locale => 'ru';
has ext_resources      => sub { ['<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?v=3&sensor=false"></script>'] };

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 26                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 30 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

package <: $module_name ~ "::Index::Admin" :>;

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
