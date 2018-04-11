package <: $module_name ~ "::RPC" :>;

use Pcore -role;
use <: $module_name ~ "::Util" :>;

has cfg => ( is => 'ro', isa => HashRef, required => 1 );

has util => ( is => 'ro', isa => InstanceOf ['<: $module_name :>::Util'], init_arg => undef );

around BUILD => sub ( $orig, $self, $args ) {
    $self->{util} = <: $module_name ~ "::Util" :>->new;

    $self->{util}->build_dbh( $self->{cfg}->{_}->{db} );

    return $self->$orig($args);
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
## |    1 | 8                    | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 34                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 38 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::RPC" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
