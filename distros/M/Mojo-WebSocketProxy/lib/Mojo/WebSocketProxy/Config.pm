package Mojo::WebSocketProxy::Config;

use strict;
use warnings;

use Mojo::Base -base;

our $VERSION = '0.12';    ## VERSION

=head1 METHODS

=cut

=head2 init

Applies configuration. Supports the following config vars:

=over 4

=item * opened_connection - coderef which will be called when a new connection is opened

=item * finish_connection - coderef called on connection close

=item * skip_check_sanity - actions for which sanity checks will not be applied

=back

Returns an empty list.

=cut

sub init {
    my ($self, $in_config) = @_;

    $self->{config}   = {};
    $self->{actions}  = {};
    $self->{backends} = {};

    die 'Expected a coderef for opened_connection' if $in_config->{opened_connection} && ref($in_config->{opened_connection}) ne 'CODE';
    die 'Expected a coderef for finish_connection' if $in_config->{finish_connection} && ref($in_config->{finish_connection}) ne 'CODE';
    die 'Expected a regex for skip_check_sanity'   if $in_config->{skip_check_sanity} && ref($in_config->{skip_check_sanity}) ne 'Regexp';

    $self->{config} = $in_config;
    return;
}

=head2 add_action

Adds an action to the list of handlers.

Expects C<$action> as an arrayref, and an C<$order> in which the action should be applied.

=cut

sub add_action {
    my ($self, $action, $order) = @_;
    my $name    = $action->[0];
    my $options = $action->[1];

    $self->{actions}->{$name} ||= $options;
    $self->{actions}->{$name}->{order} = $order;
    $self->{actions}->{$name}->{name}  = $name;
    return;
}

sub add_backend {
    my ($self, $name, $backend) = @_;
    $self->{backends}{$name} = $backend;
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

=head2 add_backend

=head1 SEE ALSO


L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>,
L<Mojo::WebSocketProxy::Backend>,
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
