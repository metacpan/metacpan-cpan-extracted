package <: $module_name ~ "::Node" :>;

use Pcore -role;
use <: $module_name ~ "::Util" :>;

has env      => ( required => 1 );
has settings => ( required => 1 );

has util => ( init_arg => undef );    # InstanceOf ['<: $module_name :>::Util']

around BUILD => sub ( $orig, $self, $args ) {
    P->on(
        'app.api.settings.updated',
        sub ($ev) {
            $self->_on_settings_update( $ev->{data} );

            return;
        }
    );

    $self->{util} = <: $module_name ~ "::Util" :>->new( settings => $self->{settings} );

    return $self->$orig($args);
};

sub _on_settings_update ( $self, $data ) {
    $self->{settings} = $data;

    $self->on_settings_update($data);

    return;
}

sub on_settings_update ( $self, $data ) {
    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 4                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 40                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 44 does not match the package declaration       |
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
