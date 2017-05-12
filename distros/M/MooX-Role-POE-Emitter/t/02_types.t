## Test configurable type prefixes.
use Test::More;
use strict; use warnings FATAL => 'all';
use POE;

use lib 't/inc';
use MxreTestUtils;

my $emitter_got;
my $emitter_expected = {
  'got Proc_things' => 1,
};

{
  package
   MyEmitter;
  use strict; use warnings FATAL => 'all';

  use POE;
  use Test::More;

  use Moo;
  use MooX::Role::Pluggable::Constants;
  with 'MooX::Role::POE::Emitter';

  sub BUILD {
    my ($self) = @_;

    $self->set_alias( 'SimpleEmitter' );

    $self->set_object_states(
      [
        $self => [ qw/
          shutdown
        / ],
      ],
    );

    $self->set_pluggable_type_prefixes(
      +{
        PROCESS => 'Proc',
        NOTIFY  => 'Notify',
      },
    );

    $self->_start_emitter;
  }

  sub shutdown {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $self->call( 'shutdown_emitter' );
  }

  sub Proc_things {
    $emitter_got->{'got Proc_things'}++;
    EAT_NONE
  }
}

my $plugin_got;
my $plugin_expected = {
  'got Notify_test_event' => 1,
  'got Proc_things'       => 1,
};

{
  package
    MyPlugin;
  use strict; use warnings FATAL => 'all';
  use Test::More;
  use MooX::Role::Pluggable::Constants;

  sub new { bless [], shift }

  sub Emitter_register {
    my ($self, $core) = splice @_, 0, 2;
    $core->subscribe( $self, 'NOTIFY', 'test_event' );
    $core->subscribe( $self, 'PROCESS', 'things' );
    EAT_NONE
  }

  sub Emitter_unregister {
    EAT_NONE
  }

  sub Notify_test_event {
    $plugin_got->{'got Notify_test_event'}++;
    EAT_NONE
  }

  sub Proc_things {
    $plugin_got->{'got Proc_things'}++;
    EAT_NONE
  }
}

my $listener_got;
my $listener_expected = {
  'got emitted_registered' => 1,
  'got emitted_test_event' => 1,
};

sub _start {
  my $emitter = MyEmitter->new;

  $poe_kernel->post( $emitter->session_id, 'subscribe' );

  $emitter->plugin_add( 'MyPlugin', MyPlugin->new );

  ## Test process()
  $emitter->process( 'things', 1 );
  ## Test emit()
  $emitter->emit( 'test_event', 1 );

  $emitter->yield('shutdown');
}

sub emitted_registered {
  ## Test 'registered' ev
  $listener_got->{'got emitted_registered'}++;
}

sub emitted_test_event {
  ## emit() received
  $listener_got->{'got emitted_test_event'}++;
}

POE::Session->create(
  package_states => [
    main => [ qw/
      _start
      emitted_registered
      emitted_test_event
    / ],
  ],
);

$poe_kernel->run;

test_expected_ok($emitter_got, $emitter_expected,
  'Got expected results from Emitter'
);

test_expected_ok($plugin_got, $plugin_expected,
  'Got expected results from Plugin'
);

test_expected_ok($listener_got, $listener_expected,
  'Got expected results from Listener'
);

done_testing;
