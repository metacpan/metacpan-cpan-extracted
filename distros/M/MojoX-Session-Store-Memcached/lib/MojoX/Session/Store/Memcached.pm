package MojoX::Session::Store::Memcached;

use strict;
use warnings;

use base 'MojoX::Session::Store';
use Cache::Memcached;

__PACKAGE__->attr('memcached_connector');

our $VERSION = '0.01';

sub new {
    my($class,$param)=@_;
    my $self = $class->SUPER::new();
    bless $self,$class;
    
    if( ref $param->{servers} ne  'ARRAY' ){
        $param->{servers} = [$param->{servers}];
    }
    
    $self->memcached_connector(Cache::Memcached->new($param));
    
    return $self;
}

sub create {
    my ($self, $sid, $expires, $data) = @_;
    
    my $new_data = {
        data    => $data,
        expires => $expires
    };
    my $res = $self->{memcached_connector}->set($sid,$new_data);
    
    return $res;
}

sub update {
    my ($self, $sid, $expires, $data) = @_;
    
    my $new_data = {
        data    => $data,
        expires => $expires
    };
    
    my $res = $self->{memcached_connector}->replace($sid,$new_data);
    
    return $res;
}

sub load {
    my ($self, $sid) = @_;
    my $memd = $self->{memcached_connector};
    my $res = $memd->get($sid);
    
    return ($res->{expires},$res->{data});
}

sub delete {
    my ($self, $sid) = @_;
    
    my $res = $self->{memcached_connector}->delete($sid);
    
    return;
}

1;
__END__

=head1 NAME

MojoX::Session::Store::Memcached - Memcached Store for MojoX::Session

=head1 SYNOPSIS

    my $session = MojoX::Session->new(
        tx        => $tx,
        # all params as for Cache::Memcached
        store     => MojoX::Session::Store::Memcached->new({
            servers => [127.0.0.1:11211]
        }),
        transport => MojoX::Session::Transport::Cookie->new,
        ip_match  => 1
    );

    # see doc for MojoX::Session

=head1 DESCRIPTION

L<MojoX::Session::Store::Memcached> is a store for L<MojoX::Session> that stores a
session in a memcached daemon .

=head1 ATTRIBUTES

L<MojoX::Session::Store::Memcached> implements the following attributes.

=head2 C<memcached_connector>
    
    my $memcached_connector = $store->memcached_connector;
    $store  = $store->memcached_connector($memcached_connector);

Get and set memcached handler.

=head1 METHODS

L<MojoX::Session::Store::Memcached> inherits all methods from
L<MojoX::Session::Store>.

=head2 C<create>

Insert session to memcached.

=head2 C<update>

Update session in memcached.

=head2 C<load>

Load session from memcached.

=head2 C<delete>

Delete session from memcached.

=head1 AUTHOR

Harper, C<plcgi1 at gmail.com>.

=head1 COPYRIGHT

Copyright (C) 2009, Harper.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
