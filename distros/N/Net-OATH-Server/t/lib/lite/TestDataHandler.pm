package TestDataHandler;

use strict;
use warnings;

use parent 'Net::OATH::Server::Lite::DataHandler';
use Net::OATH::Server::Lite::Model::User;
use Crypt::OpenSSL::Random qw/random_bytes/;

use lib 't/lib/lite';
use Dummy;

my %users;
my $force_return_false = 0;

sub set_force_return_false {
    $force_return_false = 1;
}

sub unset_force_return_false {
    $force_return_false = 0;
}

# method for test
sub clean_user_for_test {
    my ($self) = @_;
    %users = ();
}

# defined method
sub create_id {
    my $class = shift;
    return unpack('H*', random_bytes(20));
}

sub create_secret {
    my $class = shift;
    return random_bytes(20);
}

sub insert_user {
    my ($self, $user) = @_;

    return if $force_return_false;

    return unless ($user && $user->isa(q{Net::OATH::Server::Lite::Model::User}));

    unless (exists($users{$user->id})) {
        $users{$user->id} = $user;
        warn("user is added. id=" . $user->id);
        return 1;
    } else {
        warn("user is found. id=" . $user->id);
        return;
    }
}

sub select_user {
    my ($self, $id) = @_;

    return unless $id;

    # for test
    if ($id eq q{dummy}) {
        return Dummy->new;
    }

    if (exists($users{$id})) {
        warn("user is found. id=" . $id);
        return $users{$id};
    } else {
        warn("user is not found. id=" . $id);
        return;
    }
}

sub update_user {
    my ($self, $user) = @_;

    return if $force_return_false;

    return unless ($user && $user->isa(q{Net::OATH::Server::Lite::Model::User}));

    if (exists($users{$user->id})) {
        $users{$user->id} = $user;
        warn("user is updated. id=" . $user->id);
        return 1;
    } else {
        warn("user is not found. id=" . $user->id);
        return;
    }
}

sub delete_user {
    my ($self, $id) = @_;

    return if $force_return_false;

    return unless $id;

    if (exists($users{$id})) {
        delete $users{$id};
        warn("user is deleted. id = " . $id);
        return 1;
    } else {
        warn("user is not found. id=" . $id);
        return;
    }
}

1;
