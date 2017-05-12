package Server::Control::t::HTTPServerSimple;
use base qw(Server::Control::t::Base);
use POSIX qw(geteuid getegid);
use Server::Control::HTTPServerSimple;
use Test::Most;
use strict;
use warnings;

__PACKAGE__->skip_if_listening();

my $test_server_class = Moose::Meta::Class->create_anon_class(
    superclasses => ['HTTP::Server::Simple'],
    methods      => {
        net_server => sub { 'Net::Server::PreForkSimple' }
    },
);

sub create_ctl {
    my ( $self, $port, $temp_dir, %extra_params ) = @_;

    return Server::Control::HTTPServerSimple->new(
        server_class      => $test_server_class->name,
        net_server_params => {
            max_servers => 2,
            port        => $port,
            pid_file    => $temp_dir . "/server.pid",
            log_file    => $temp_dir . "/server.log",
            user        => geteuid(),
            group       => getegid()
        },
        %extra_params
    );
}

sub test_bad_server_class : Test(2) {
    my $self = shift;

    my $bad_server_class = Moose::Meta::Class->create_anon_class(
        superclasses => ['HTTP::Server::Simple'],
        cache        => 1
    );
    throws_ok {
        Server::Control::HTTPServerSimple->new(
            server_class => $bad_server_class->name )->server;
    }
    qr/must be an HTTP::Server::Simple subclass with a net_server defined/;
    throws_ok {
        Server::Control::HTTPServerSimple->new( server_class => 'bleah' )
          ->server;
    }
    qr/Can't locate bleah/;
}

sub test_missing_params : Test(2) {
    my $self = shift;

    throws_ok {
        Server::Control::HTTPServerSimple->new(
            server_class      => $test_server_class->name,
            net_server_params => { port => $self->{port} }
        )->pid_file();
    }
    qr/pid_file must be passed/;
    throws_ok {
        Server::Control::HTTPServerSimple->new(
            server_class      => $test_server_class->name,
            net_server_params => { pid_file => $self->{pid_file} }
        )->port();
    }
    qr/port must be passed/;
}

sub test_wrong_port : Tests(8) {
    my $self = shift;
    my $ctl  = $self->{ctl};
    $ctl->server;    # create server object with old port

    $self->SUPER::test_wrong_port();
}

1;
