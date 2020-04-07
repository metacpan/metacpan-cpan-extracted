package <: $module_name ~ "::API" :>;

use Pcore -class;

extends qw[Pcore::App::API];

sub upgrade_schema ($self) {
    my $dbh = $self->{dbh};

    $dbh->load_schema( $ENV->{share}->get_location('/<: $dist_name :>/db'), 'main' );

    return $dbh->upgrade_schema;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 10                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 17                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 21 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
