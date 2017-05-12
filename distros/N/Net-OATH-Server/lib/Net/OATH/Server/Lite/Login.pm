package Net::OATH::Server::Lite::Login;
use strict;
use warnings;

use Authen::OATH;
use Net::OATH::Server::Lite::Error;

my %DIGEST_MAP = (
    SHA1 => q{Digest::SHA1},
    MD5 => q{Digest::MD5},
    # TODO: Support SHA256, SHA512
    # SHA256 => q{Digest::SHA256},
    # SHA512 => q{Digest::SHA512},
);

sub is_valid_user {
    my ($self, $data_handler, $params) = @_;

    Net::OATH::Server::Lite::Error->throw(
        code => 500,
        error => q{server_error},
    ) unless ($data_handler && $data_handler->isa(q{Net::OATH::Server::Lite::DataHandler}));

    # Params
    my $id = $params->{id} or
        Net::OATH::Server::Lite::Error->throw(
            description => q{missing id},
        );

    my $password = $params->{password} or
        Net::OATH::Server::Lite::Error->throw(
            description => q{missing password},
        );

    # obtain user model
    my $user = $data_handler->select_user($id) or
        Net::OATH::Server::Lite::Error->throw(
            code => 404,
            description => q{invalid id},
        );
    Net::OATH::Server::Lite::Error->throw(
        code => 500,
        error => q{server_error},
    ) unless $user->isa(q{Net::OATH::Server::Lite::Model::User});

    my $timestamp = ($params->{timestamp}) ? $params->{timestamp} : time();
    my $counter = (defined $params->{counter}) ? $params->{counter} : $user->counter;
    my $is_valid = $self->_is_valid_password($password, $user, $timestamp, $counter);
    if ($user->type eq q{hotp} and !defined $params->{counter}) {
        $user->counter($user->counter + 1);
        $data_handler->update_user($user);
    }

    return ($is_valid, $user);
}

sub _is_valid_password {
    my ($self, $password, $user, $timestamp, $counter) = @_;

    # generate password
    my $oath =
        Authen::OATH->new(
            digits => $user->digits,
            digest => __digest_for_oath($user->algorithm),
            timestep => $user->period,
        );

    if ($user->type eq q{totp}) {
        # TOTP
        return ($password eq $oath->totp($user->secret, $timestamp));
    } else {
        # HOTP
        return ($password eq $oath->hotp($user->secret, $counter));
    }

    return 1;
}

sub __digest_for_oath {
    my $algorithm = shift;
    return ($DIGEST_MAP{$algorithm}) ? $DIGEST_MAP{$algorithm} : q{Digest::SHA1};
}

1;
