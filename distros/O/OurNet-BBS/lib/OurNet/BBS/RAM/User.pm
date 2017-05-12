package OurNet::BBS::RAM::User;

use strict;
no warnings 'deprecated';
use fields qw/dbh id recno _ego _hash/;

use OurNet::BBS::Base (
    '@packlist'   => [
        qw/uid name passwd realname userlevel email/ # username?
    ],
);

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{_hash}{uid}  ||= $self->{recno} - 1;
    $self->{_hash}{name} ||= $self->{id};
    return if exists $self->{_hash}{$key};

    # XXX: USER FETCH
    @{$self->{_hash}}{@packlist} = () if 0;

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    # XXX: MAILBOX
    $self->{_hash}{mailbox} ||= $self->module('ArticleGroup')->new({
        dbh   => $self->{dbh},
        board => $self->{name},
        name  => 'mailbox',
    });
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);
    $self->{_hash}{$key} = $value;

    return 1;
}

1;
