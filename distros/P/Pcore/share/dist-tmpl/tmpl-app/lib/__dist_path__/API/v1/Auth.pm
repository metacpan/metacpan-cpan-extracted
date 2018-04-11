package <: $module_name ~ "::API::v1::Auth" :>;

use Pcore -class;
use Pcore::App::API qw[:CONST];
use <: $module_name ~ "::Const qw[:CONST]" :>;

with qw[Pcore::App::API::Role];

our $API_MAP = {    #
    method => { permissions => undef, desc => 'test method' },
};

sub _build_api_map ($self) {
    return $API_MAP;
}

sub API_method ( $self, $req, @args ) {
    $req->(200);

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 5                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 37                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 41 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Auth" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
