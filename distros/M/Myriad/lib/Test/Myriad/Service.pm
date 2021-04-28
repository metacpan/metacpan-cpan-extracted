package Test::Myriad::Service;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Scalar::Util qw(weaken);
use Sub::Util;

use Myriad::Service::Implementation;
use Myriad::Class;
use Myriad::Service::Attributes;

=head1 NAME

Test::Myriad::Service - an abstraction to mock microservices.

=head1 SYNOPSIS

 my $service = Myriad::Test::Service->new(..);
 $service->add_rpc('rpc_name', %default_response);

=head1 DESCRIPTION

=head1 Methods

=cut

has $name;
has $pkg;
has $meta_service;
has $myriad;

has $default_rpc;
has $mocked_rpc;

BUILD (%args) {
    $meta_service = delete $args{meta};
    $pkg = delete $args{pkg};
    weaken($myriad = delete $args{myriad});

    $default_rpc = {};
    $mocked_rpc = {};

    # Replace the RPC subs with a mockable
    # version if the class already exists
    try {
        if (my $methods = $myriad->registry->rpc_for($pkg)) {
            for my $method (keys $methods->%*) {
                $default_rpc->{$method} = $methods->{$method}->{code};
                $methods->{$method}->{code} = async sub {
                    if ($mocked_rpc->{$method}) {
                        return delete $mocked_rpc->{$method};
                    }
                    try {
                        await $default_rpc->{$method}->(@_);
                    } catch ($e) {
                        $log->tracef("An exception has been thrown while calling the original sub - %s", $e);
                        die $e;
                    }
                };
            }
        }
    } catch ($e) {
        $log->tracef('Myriad::Registry error while checking %s, %s', $pkg, $e);
    }
}

=head2 add_rpc

Attaches a new RPC to the service with a defaultt response.

=over 4

=item * C<name> - The name of the RPC.

=item * C<response> - A hash that will be sent as the response.

=back

=cut

method add_rpc ($name, %response) {
    my $faker = async sub {
        if ($mocked_rpc->{$name}) {
            return delete $mocked_rpc->{$name};
        } elsif (my $default_response = $default_rpc->{$name}) {
            return $default_response;
        }
    };

    # Don't prefix the RPC name it's used in messages delivery.

    Myriad::Service::Attributes->apply_attributes(
        class => $meta_service->name,
        code => Sub::Util::set_subname($name, $faker),
        attributes => ['RPC'],
    );

    $default_rpc->{$name} = \%response;
    $meta_service->add_method($name, $faker);

    $self;
}

=head2 mock_rpc

Override the original RPC response for a single call.

=over 4

=item * C<name> - The name of the RPC to be mocked.

=item * C<response> - A hash that will be sent as the response.

=back

=cut

method mock_rpc ($name, %response) {
     die 'You should define rpc methdos using "add_rpc" first' unless $default_rpc->{$name};
     die 'You cannot mock RPC call twice' if $mocked_rpc->{$name};
     $mocked_rpc->{$name} = \%response;

     $self;
}

=head2 call_rpc

A shortcut to call an RPC in the current service.

The call will be conducted over Myriad Transport and not
as a method invocation.

=over 4

=item * C<method> - The RPC method name.

=item * C<args> - A hash of the method arguments.

=back

=cut

async method call_rpc ($method, %args) {
    my $service_name = $myriad->registry->make_service_name($pkg);
    await $myriad->rpc_client->call_rpc($service_name, $method, %args);
}

=head2 add_subscription

Creats a new subscription in the service.

This sub takes the source of the data in multiple ways
described in the parameters section, only one of them required.

=over 4

=item * C<channel> - The channel name that the events will be emitted to.

=item * C<array> - A perl arrayref that its content is going to be emitted as events.

=back

=cut

method add_subscription ($channel, %args) {
    if (my $data = $args{array}) {
        my $batch = async sub {
            while (my @next = splice($data->@*, 0, 5)) {
                return \@next;
            }
        };

        Myriad::Service::Attributes->apply_attributes(
            class => $meta_service->name,
            code => Sub::Util::set_subname($channel, $batch),
            attributes => ['Batch'],
        );

        $meta_service->add_method("batch_$channel", $batch);

        $self
    } else {
        die 'only simple arrays are supported at the moment';
    }
}

=head2 add_receiver

Adds a new receiver in the given service.

=over 4

=item * C<from> - The source service name.

=item * C<channel> - The source of the events channel name.

=item * C<handler> - A coderef that will handle the events.

=back

=cut

method add_receiver ($from, $channel, $handler) {
    my $receiver = async sub {
        my ($self, $src) = @_;
        await $src->each($handler)->completed;
    };

    Myriad::Service::Attributes->apply_attributes(
        class => $meta_service->name,
        code => Sub::Util::set_subname("receiver_$channel", $receiver),
        attributes => ["Receiver(from => '$from', channel => '$channel')"]
    );

    $meta_service->add_method("receiver_$channel", $receiver);

    $self;
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020. Licensed under the same terms as Perl itself.

