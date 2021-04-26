package Myriad::Service::Remote;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Service::Remote - abstraction to access other services over the network.

=head1 SYNOPSIS

 my $remote_service = $api->service_by_name('service');
 await $remote_service->call_api('some_method', %args);

=head1 DESCRIPTION

=cut

use Myriad::Class;
use Myriad::Service::Storage::Remote;

has $myriad;
has $service_name;
has $local_service_name;
has $storage;

BUILD(%args) {
    weaken($myriad = delete $args{myriad});
    $service_name = delete $args{service_name} // die 'need a service name';
    $local_service_name = delete $args{local_service_name};
    $storage = Myriad::Service::Storage::Remote->new(
        prefix             => $service_name,
        storage            => $myriad->storage,
        local_service_name => $local_service_name
    );
}

method service_name { $service_name }

=head2 storage

Returns a L<Myriad::Service::Storage::Remote> instance to access
the remote service public storage.

=cut

method storage { $storage }

=head2 call_rpc

Call a method on the remote service.

it takes

=over 4

=item * C<rpc> - The remote method names.

=item * C<args> - A hash of the method arguments.

=back

=cut

async method call_rpc ($rpc, %args) {
    await $myriad->rpc_client->call_rpc($service_name, $rpc, %args);
}

=head2 subscribe


Please use the C<Receiver> attribute in Myriad.

This method is implemented for the sake of compatibility with
the framework specs.

it subscribes to a channel in the remote service.

=cut

async method subscribe ($channel, $client = "remote_service") {
   my $sink = $myriad->ryu->sink;
   await $myriad->subscription->create_from_sink(
        sink => $sink,
        service => $service_name,
        client => $client,
        channel => $channel,
    );
   return $sink->source;
}

1;

