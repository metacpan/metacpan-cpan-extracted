package Server::Control::t::NetServer;
use base qw(Server::Control::t::Base);
use Server::Control::NetServer;
use POSIX qw(geteuid getegid);
use Test::Most;
use strict;
use warnings;

sub create_ctl {
    my ( $self, $port, $temp_dir, %extra_params ) = @_;

    return $self->create_net_server_ctl( $port, $temp_dir, %extra_params );
}

sub test_missing_params : Test(2) {
    my $self = shift;
    my $port = $self->{port};

    throws_ok {
        Server::Control::NetServer->new(
            net_server_class  => 'Net::Server::Fork',
            net_server_params => { port => $port }
        )->pid_file();
    }
    qr/pid_file must be passed/;
    throws_ok {
        Server::Control::NetServer->new(
            net_server_class  => 'Net::Server::Fork',
            net_server_params => { pid_file => $self->{pid_file} }
        )->port();
    }
    qr/port must be passed/;
}

1;
