package <: $module_name ~ "::Index::Admin" :>;

use Pcore -class;

has ext_app       => ( is => 'ro', isa => Str, default => 'Billing', init_arg => undef );
has ext_app_title => ( is => 'ro', isa => Str, default => 'Billing', init_arg => undef );

with qw[Pcore::App::Controller::Ext];

has '+ext_default_locale' => ( default => 'ru' );
has '+ext_resources' => ( default => sub { ['<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?v=3&sensor=false"></script>'] } );

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 27                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 31 does not match the package declaration       |
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
