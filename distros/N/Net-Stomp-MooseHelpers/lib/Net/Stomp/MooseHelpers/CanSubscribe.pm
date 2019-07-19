package Net::Stomp::MooseHelpers::CanSubscribe;
$Net::Stomp::MooseHelpers::CanSubscribe::VERSION = '3.0';
{
  $Net::Stomp::MooseHelpers::CanSubscribe::DIST = 'Net-Stomp-MooseHelpers';
}
use Moose::Role;
use Net::Stomp::MooseHelpers::Exceptions;
use Net::Stomp::MooseHelpers::Types qw(SubscriptionConfigList
                                       Headers
                                  );
use Try::Tiny;
use namespace::autoclean;

# ABSTRACT: role for classes that subscribe via Net::Stomp


has subscribe_headers => (
    is => 'ro',
    isa => Headers,
    lazy => 1,
    builder => '_default_subscribe_headers',
);
sub _default_subscribe_headers { { } }


has subscriptions => (
    is => 'ro',
    isa => SubscriptionConfigList,
    coerce => 1,
    lazy => 1,
    builder => '_default_subscriptions',
);
sub _default_subscriptions { [] }

requires 'connection','current_server';


sub subscribe {
    my ($self) = @_;

    my %headers = (
        %{$self->subscribe_headers},
        %{$self->current_server->{subscribe_headers} || {}},
    );

    my $sub_id = 0;

    try {
        for my $sub (@{$self->subscriptions}) {
            my $destination = $sub->{destination};
            my $more_headers = $sub->{headers} || {};

            $self->subscribe_single(
                $sub,
                {
                    destination => $destination,
                    %headers,
                    %$more_headers,
                    id => $sub_id,
                    ack => 'client',
                }
            );

            ++$sub_id;
        }
    } catch {
        Net::Stomp::MooseHelpers::Exceptions::Stomp->throw({
            stomp_error => $_
        });
    };
}


sub subscribe_single {
    my ($self,$subscription,$headers) = @_;

    $self->connection->subscribe($headers);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stomp::MooseHelpers::CanSubscribe - role for classes that subscribe via Net::Stomp

=head1 VERSION

version 3.0

=head1 SYNOPSIS

  package MyThing;
  use Moose;
  with 'Net::Stomp::MooseHelpers::CanConnect';
  with 'Net::Stomp::MooseHelpers::CanSubscribe';
  use Try::Tiny;

  sub foo {
    my ($self) = @_;
    $self->connect();
    $self->subscribe();
    do_something( $self->connection->receive_frame() );
  }

=head1 DESCRIPTION

This role provides your class with a flexible way to define
subscriptions to a STOMP server, and to actually subscribe.

B<NOTE>: as shown in the synopsis, you need 2 separate calls the
C<with>, otherwise the roles won't apply. The reason is that this role
requires a C<connection> attribute, that is provided by
L<Net::Stomp::MooseHelpers::CanConnect>, but the role dependency
resolution does not notice that.

=head1 ATTRIBUTES

=head2 C<subscribe_headers>

Global setting for subscription headers (passed to
L<Net::Stomp/subscribe>). Can be overridden by the
C<subscribe_headers> slot in each element of L</servers> and by the
C<headers> slot in each element fof L</subscriptions>. Defaults to
the empty hashref.

=head2 C<subscriptions>

A
L<SubscriptionConfigList|Net::Stomp::MooseHelpers::Types/SubscriptionConfigList>,
that is, an arrayref of hashrefs, each of which describes a
subscription. Defaults to the empty arrayref. You should set this
value to something useful, otherwise your connection will not receive
any message.

=head1 METHODS

=head2 C<subscribe>

Call L</subscribe_single> method for each element of
L</subscriptions>, passing the generic L</subscribe_headers>, the
per-server subscribe headers (from
L<current_server|Net::Stomp::MooseHelpers::CanConnect/current_server>,
slot C<subscribe_headers>) and the per-subscription subscribe headers
(from L</subscriptions>, slot C<headers>).

Throws a L<Net::Stomp::MooseHelpers::Exceptions::Stomp> if anything
goes wrong.

=head2 C<subscribe_single>

  $self->subscribe_single($subscription,$headers);

Call the C<subscribe> method on L</connection>, passing the
C<$headers>.

You can override or modify this method in your class if you need to
perform more work on each subscription.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
