package <: $module_name ~ "::API::v1::Admin::Settings" :>;

use Pcore -const, -class, -sql, -res;
use <: $module_name ~ "::Const qw[:PERMS]" :>;
use Pcore::API::SMTP;

extends qw[Pcore::App::API::Base];

const our $API_NAMESPACE_PERMS => [$PERMS_ADMIN];

sub API_read ( $self, $auth, @ ) {
    return 200, $self->{api}->{settings};
}

sub API_update ( $self, $auth, $args ) {
    return $self->{api}->settings_update($args);
}

sub API_test_smtp ( $self, $auth, $args ) {
    my $smtp = Pcore::API::SMTP->new( {
        host     => $args->{smtp_host},
        port     => $args->{smtp_port},
        username => $args->{smtp_username},
        password => $args->{smtp_password},
        tls      => $args->{smtp_tls},
    } );

    return $smtp->test;
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
## |    1 | 33                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 37 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Admin::Settings" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
