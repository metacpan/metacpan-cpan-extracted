use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MockModule;
use IO::Async::Loop;
use IO::Async::Test;
use Future::AsyncAwait;
# Needed to set Testing::Service method names without fully defining service as Myriad::Service
use Sub::Util qw(subname set_subname);

use Myriad;
use Myriad::Registry;
use Myriad::Config;

my $service_module = Test::MockModule->new('Myriad::Service::Implementation');
my $started_services = {};
$service_module->mock('start', async sub { my ($self) = @_; $started_services->{ref($self)} = 1; });

my $loop = IO::Async::Loop->new;
testing_loop($loop);

sub loop_notifiers {
    my $loop = shift;

    my @current_notifiers = $loop->notifiers;
    my %loaded_in_loop = map { ref()  => 1 } @current_notifiers;
    return \%loaded_in_loop;
}

my $METHODS_MAP = {rpc => 'rpc_for', batch => 'batches_for', emitter => 'emitters_for', receiver => 'receivers_for'};
sub component_for_method {
    my $method = shift;

    return $METHODS_MAP->{$method};
}

my $myriad_meta = Object::Pad::MOP::Class->for_class('Myriad');
my $reg_meta    = Object::Pad::MOP::Class->for_class('Myriad::Registry');

subtest "Adding and viewing components" => sub {

    my $registry = new_ok('Myriad::Registry');
    is $loop->add($registry), undef, "Registry Notifier class added to Loop just fine.";

    my $srv_class = 'Testing::Service';
    # RPC & Batch & emitter & receiver component
    for my $component (qw(rpc batch emitter receiver)){
        my $sub_name = "dummy_$component";
        my $dummy_sub = set_subname join('::', $srv_class, $sub_name),sub {};
        my $args = {};
        $args->{channel} = $sub_name if $component eq 'emitter' || $component eq 'receiver';
        $args->{service} = $registry->make_service_name($srv_class) if $component eq 'receiver';
        my $slot = {"$srv_class" => { $sub_name => {args => $args, code => $dummy_sub}}};

        my $add = join '_', 'add', $component;

        my  $for = component_for_method($component);

        # Always pass empty $args only with receiver set service name
        $registry->$add($srv_class, $sub_name, $dummy_sub, $component eq 'receiver'? {'service' => $srv_class} : {});
        my $reg_slot = $reg_meta->get_slot('%'.$component)->value($registry);
        cmp_deeply($reg_slot, $slot, "added $component");

        my $for_method = $registry->$for($srv_class);
        cmp_deeply($for_method, $slot->{$srv_class}, "$component for service");

        # Test calling $component_for unknown classes
        $for_method = exception {$registry->$for("Not::Added::Empty::Class")};
        isa_ok($for_method, 'Myriad::Exception::Registry::UnknownClass', "Exception for trying to get empty $component for un_added services");
    }

};

subtest "Adding Service" => sub {

    my $myriad = new_ok('Myriad');
    my $config = new_ok('Myriad::Config' => [commandline => ['--transport', 'memory']]);
    $myriad_meta->get_slot('$config')->value($myriad) = $config;
    my $registry = $Myriad::REGISTRY;

    # Define our testing service
    {
        package Testing::Service;
        use Myriad::Service;

        async method inc_test : RPC (%args) {
            my $value = $args{value};
            return ++$value;
        }

        async method batch_test : Batch (%args) {
            return 1;
        }
    }
    # Just by defining it, it will be configured. But not yet added or started.

    # Add service in our registry.
    wait_for_future($registry->add_service(myriad => $myriad, service => 'Testing::Service'))->get;

    # Get registered services in Myriad
    my $services = $myriad_meta->get_slot('$services')->value($myriad);
    # We should be having only one.
    is (keys %$services, 1, 'Only one service is added');
    my ($service) = values %$services;
    # Service name is set
    my $service_name = $service->service_name;
    like($registry->make_service_name('Testing::Service'), qr/$service_name/, "Service name is set correctly");

    my $srv_meta = Object::Pad::MOP::Class->for_class(ref $service);
    # Calling empty <component>_for for an added service will not trigger exception. reveiver and emitter in this case.
    my ($rpc, $batch, $receiver, $emitter) = map {my $meth = component_for_method($_); $registry->$meth('Testing::Service')} qw(rpc batch receiver emitter);
    cmp_deeply([map {keys %$_ } ($rpc, $batch, $receiver, $emitter)], ['inc_test', 'batch_test'], 'Registry components configured after service adding');

    my $current_notifiers = loop_notifiers($myriad->loop);
    ok($current_notifiers->{'Testing::Service'}, 'Testing::Service is added to  loop');

    my $srv_in_registry = $registry->service_by_name($registry->make_service_name('Testing::Service'));
    cmp_deeply($service, $srv_in_registry, 'Same service in Myriad and Regisrty');
    is($started_services->{'Testing::Service'}, undef, 'Registry has not started service');
};

subtest "Service name" => sub {

    my $registry = new_ok('Myriad::Registry');
    my $reg_srv_name = $registry->make_service_name('Test::Name');
    # Only lower case sepatated by .(dot)
    like ($reg_srv_name, qr/^[a-z']+\.[a-z']+$/, 'passing regex service name');

    isa_ok(exception {$registry->service_by_name("Not::Found::Service")}, 'Myriad::Exception::Registry::ServiceNotFound', "Exception for trying to get undef service");

    # Should remove the namespace from the service name;
    $reg_srv_name = $registry->make_service_name('Test::Module::Service', 'Test::Module::');
    like ($reg_srv_name, qr/^service$/, 'namespace applied correctly');
};

done_testing;
