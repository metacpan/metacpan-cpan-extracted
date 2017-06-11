package Mojo::WebSocketProxy::Config;

use strict;
use warnings;

use Mojo::Base -base;

our $VERSION = '0.06';    ## VERSION

sub init {
    my ($self, $in_config) = @_;

    $self->{config}  = {};
    $self->{actions} = {};

    die 'Wrong parameter' if $in_config->{opened_connection} && ref($in_config->{opened_connection}) ne 'CODE';
    die 'Wrong parameter' if $in_config->{finish_connection} && ref($in_config->{finish_connection}) ne 'CODE';
    die 'Wrong parameter' if $in_config->{skip_check_sanity} && ref($in_config->{skip_check_sanity}) ne 'Regexp';

    $self->{config} = $in_config;
    return;
}

sub add_action {
    my ($self, $action, $order) = @_;
    my $name    = $action->[0];
    my $options = $action->[1];

    $self->{actions}->{$name} ||= $options;
    $self->{actions}->{$name}->{order} = $order;
    $self->{actions}->{$name}->{name}  = $name;
    return;
}

1;

__END__

=head1 NAME

Mojo::WebSocketProxy::Parser

=head1 DESCRIPTION

This module using for store server configuration in memory.

=head1 METHODS

=head2 init

=head2 add_action

=head1 SEE ALSO


L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>,
L<Mojo::WebSocketProxy::CallingEngine>,
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
