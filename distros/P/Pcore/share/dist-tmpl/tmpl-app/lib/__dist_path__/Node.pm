package <: $module_name ~ "::Node" :>;

use Pcore -role;
use <: $module_name ~ "::Util" :>;

has cfg => ( required => 1 );

has util => ( init_arg => undef );    # InstanceOf ['<: $module_name :>::Util']

around BUILD => sub ( $orig, $self, $args ) {
    $self->{util} = <: $module_name ~ "::Util" :>->new;

    $self->{util}->@{ keys $args->{util}->%* } = values $args->{util}->%*;

    $self->{util}->build_dbh( $self->{cfg}->{db} );

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
## |    1 | 22                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 26 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::Node" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
