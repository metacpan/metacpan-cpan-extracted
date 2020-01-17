package Pcore::App::API::Role::Admin::Settings;

use Pcore -role;
use Pcore::API::SMTP;

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
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Role::Admin::Settings

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
