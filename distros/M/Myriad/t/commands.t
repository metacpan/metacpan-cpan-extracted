use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::MockObject;
use Test::Fatal;
use Test::Deep;

use Object::Pad qw(:experimental);
use Log::Any::Adapter qw(TAP);

use Future::AsyncAwait;
use IO::Async::Loop;
use IO::Async::Test;

use Myriad;
use Myriad::Commands;
use Myriad::Config;
use Test::Myriad;

BEGIN {
    # if we want to fully test the command
    # we should be able to run mock service with a testing RPC
    # then call it with the command and test it.
    # This will be used in a different flow.t test
    Test::Myriad->add_service(name => "Test::Service::Mocked")->add_rpc('test_cmd', success => 1);
}

my $loop = IO::Async::Loop->new;
testing_loop($loop);

subtest "service command" => sub {
    # Myriad module is required for Command creation but only used in Service command
    my $myriad_module = Test::MockModule->new('Myriad');
    my ( @added_services_modules, @add_services_by_name );
    $myriad_module->mock('add_service', async sub {
        my ($self, $module, %args) = @_;
        # Calling of this sub means Service command has been executed succesfully
        push @added_services_modules, $module;
        push @add_services_by_name, $args{'name'} if exists $args{'name'};
    });

    # Fake existence of two sibling modules
    {
        package Ta::Sibling1;
        {
            no strict 'refs';
            push @{Ta::Sibling1::ISA}, 'Myriad::Service';
        }
        sub new { }
    }
    {
        package Ta::Sibling2;
        push @{Ta::Sibling2::ISA}, 'Myriad::Service';
        sub new { }
    }

    {
        package Ta::Sibling3;
        sub new { }
    }

    $INC{'Ta/Sibling1.pm'} = 1;
    $INC{'Ta/Sibling2.pm'} = 1;
    $INC{'Ta/Sibling3.pm'} = 1;
    ######

    my $metaclass = Object::Pad::MOP::Class->for_class('Myriad');

    my $myriad = Myriad->new;
    my $command = new_ok('Myriad::Commands'=> ['myriad', $myriad]);
    $metaclass->get_field('$config')->value($myriad) = Myriad::Config->new();

    # Wrong Service(module) name
    like( exception { wait_for_future( $command->service('Ta-wrong') )->get } , qr/unsupported/, 'Died when passing wrong format name');
    like( exception { wait_for_future( $command->service('Ta_wrong') )->get } , qr/not found/, 'Died when passing module that does not exist');

    # Running multiple services
    wait_for_future( $command->service('Ta::')->get->{code}->() )->get;
    cmp_deeply(\@added_services_modules, ['Ta::Sibling1', 'Ta::Sibling2'], 'Added both modules');
    # Clear it for next test.
    @added_services_modules = ();

    # Running services under the same namespace
    wait_for_future( $command->service('Ta::*')->get->{code}->() )->get;
    cmp_deeply(\@added_services_modules, ['Ta::Sibling1', 'Ta::Sibling2'], 'Added modules under the namespace');
    # Clear it for next test.
    @added_services_modules = ();

    done_testing;
};

my $myriad_mod = Test::MockModule->new('Myriad');

# Mock shutdown behaviour
# As some commands  are expected to call shutdown on completion.
my $shutdown_count = 0;
$myriad_mod->mock('shutdown', async sub {
    my $self = shift;
    my $shutdown_f = $loop->new_future(label => 'shutdown future');
    $shutdown_count++;
    $shutdown_f->done('shutdown called');
});
my $rmt_svc_cmd_called;
my $test_cmd;
my %calls;
my %started_components;

sub mock_component {
    my ($component, $cmd, $test_name) = @_;

    $test_cmd = $test_name;
    %calls = ();
    $rmt_svc_cmd_called = {};
    %started_components = ();
    $myriad_mod->mock($component, sub {
        my ($self) = @_;
        my $mock = Test::MockObject->new();
        $mock->mock( $cmd, async sub {
            my ($self, $service_name, $rpc, %args) = @_;
            $rmt_svc_cmd_called->{$cmd} //= [];
            push @{$rmt_svc_cmd_called->{$cmd}}, {svc => $service_name, rpc => $rpc, args => \%args};
            $calls{$rpc}++;
            return {success => 1};
        });
        my $f;
        $mock->mock('start', async sub {
            my ($self) = @_;
            $f //= $loop->new_future;
            $started_components{$component} = 1;
            return $f;
        });

        $mock->mock('create_from_sink', async sub {});
        return $mock;
    });

}

done_testing;
