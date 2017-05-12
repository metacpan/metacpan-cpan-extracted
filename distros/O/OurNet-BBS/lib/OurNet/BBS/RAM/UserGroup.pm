package OurNet::BBS::RAM::UserGroup;

use strict;
no warnings 'deprecated';
use fields qw/dbh _ego _hash _array/;

use OurNet::BBS::Base;

sub refresh_meta {
    my ($self, $key, $flag) = @_;
    my $name;

    if (defined($key) and $flag == ARRAY) {
        # XXX: ARRAY FETCH
        return if $self->{_array}[$key];
    }
    elsif ($key and $flag == HASH) {
        # XXX: KEY FETCH
        $name = $key;
        return if $self->{_hash}{$name};
        $key = 0;
    }
    else {
        # XXX: GLOBAL FETCH
    }

    my $obj = $self->module('User')->new({
        dbh   => $self->{dbh},
        id    => $name,
        recno => $key,
    });

    $key ||= $obj->{userno} ||= 0;

    $self->{_hash}{$name} = $self->{_array}[$key] = $obj;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    %{$self->module('User', $value)->new({
        dbh => $self->{dbh},
        id  => $key
    })} = %{$value};

    $self->refresh($key);
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: USER EXISTS
    return exists ($self->ego->{_hash}{$key});
}

1;
