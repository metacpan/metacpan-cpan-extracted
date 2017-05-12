package Net::OATH::Server::Lite::User;
use strict;
use warnings;

use Net::OATH::Server::Lite::Error;
use Net::OATH::Server::Lite::Model::User;

sub create {
    my ($self, $data_handler, $params) = @_;

    Net::OATH::Server::Lite::Error->throw(
        code => 500,
        error => q{server_error},
    ) unless ($data_handler && $data_handler->isa(q{Net::OATH::Server::Lite::DataHandler}));

    my ($code, $user);
    if ($params->{id}) {
        Net::OATH::Server::Lite::Error->throw();
    } else {
        $user = Net::OATH::Server::Lite::Model::User->new(
           id => $data_handler->create_id(),
           secret => $data_handler->create_secret(),
        );

        $user->type($params->{type})           if $params->{type};
        $user->algorithm($params->{algorithm}) if $params->{algorithm};
        $user->digits($params->{digits})       if $params->{digits};
        $user->counter($params->{counter})     if $params->{counter};
        $user->period($params->{period})       if $params->{period};
        Net::OATH::Server::Lite::Error->throw() unless $user->is_valid;

        unless ($data_handler->insert_user($user)) {
            Net::OATH::Server::Lite::Error->throw(
                code => 500,
                error => q{server_error},
            );
        }
        $code = 201;
    }
    return ($code, $user);
}

sub read {
    my ($self, $data_handler, $params) = @_;

    Net::OATH::Server::Lite::Error->throw(
        code => 500,
        error => q{server_error},
    ) unless ($data_handler && $data_handler->isa(q{Net::OATH::Server::Lite::DataHandler}));

    my ($code, $user);
    if ($params->{id}) {
        $user = $data_handler->select_user($params->{id}) or
                Net::OATH::Server::Lite::Error->throw(
                    code => 404,
                    description => q{invalid id},
                );
        $code = 200;
    } else {
        Net::OATH::Server::Lite::Error->throw(
            description => q{missing id},
        );
    }
    return ($code, $user);
}

sub update {
    my ($self, $data_handler, $params) = @_;

    Net::OATH::Server::Lite::Error->throw(
        code => 500,
        error => q{server_error},
    ) unless ($data_handler && $data_handler->isa(q{Net::OATH::Server::Lite::DataHandler}));

    my ($code, $user);
    if ($params->{id}) {
        $user = $data_handler->select_user($params->{id}) or
                Net::OATH::Server::Lite::Error->throw(
                    code => 404,
                    description => q{invalid id},
                );

        $user->type($params->{type})           if $params->{type};
        $user->algorithm($params->{algorithm}) if $params->{algorithm};
        $user->digits($params->{digits})       if $params->{digits};
        $user->counter($params->{counter})     if $params->{counter};
        $user->period($params->{period})       if $params->{period};
        Net::OATH::Server::Lite::Error->throw() unless $user->is_valid;

        unless ($data_handler->update_user($user)) {
            Net::OATH::Server::Lite::Error->throw(
                code => 500,
                error => q{server_error},
            );
        }
        $code = 200;
    } else {
        Net::OATH::Server::Lite::Error->throw(
            description => q{missing id},
        );
    }
    return ($code, $user);
}

sub delete {
    my ($self, $data_handler, $params) = @_;

    Net::OATH::Server::Lite::Error->throw(
        code => 500,
        error => q{server_error},
    ) unless ($data_handler && $data_handler->isa(q{Net::OATH::Server::Lite::DataHandler}));

    my ($code, $user);
    if ($params->{id}) {
        $user = $data_handler->select_user($params->{id}) or
                Net::OATH::Server::Lite::Error->throw(
                    code => 404,
                    description => q{invalid id},
                );

        unless ($data_handler->delete_user($user->id)) {
            Net::OATH::Server::Lite::Error->throw(
                code => 500,
                error => q{server_error},
            );
        }
        $code = 200;
    } else {
        Net::OATH::Server::Lite::Error->throw(
            description => q{missing id},
        );
    }
    return ($code, $user);
}

1;
