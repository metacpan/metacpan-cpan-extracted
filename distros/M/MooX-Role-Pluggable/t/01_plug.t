use Test::More;
use strict; use warnings FATAL => 'all';

use lib 't/inc';
use MxRPTestUtils;

my $dispatcher_got;
my $dispatcher_expected = {
  'P_test args look OK' => 1,
};

{
  package
    MyDispatcher;
  use Test::More;
  use Moo;
  use MooX::Role::Pluggable::Constants;
  with 'MooX::Role::Pluggable';

  sub process {
    my ($self, $event, @args) = @_;
    my $retval = $self->_pluggable_process( 'PROCESS', $event, \@args );
  }

  sub shutdown {
    my ($self) = @_;
    $self->_pluggable_destroy;
  }

  sub do_test_events {
    my ($self) = @_;
    $self->process( 'test', 'first', 'second' );
  }

  around '_pluggable_event' => sub {
    my ($orig, $self) = splice @_, 0, 2;
    $self->process( @_ )
  };

  sub P_test {
    my ($self, $core) = splice @_, 0, 2;
    my ($first, $second) = @_;

    $dispatcher_got->{'P_test args look OK'}++
      if $$first eq 'first' and $$second eq 'second';

    EAT_NONE
  }
}


my $plugin_got;
my $plugin_expected = {
  'Got plugin_register'   => 1,
  'Got plugin_unregister' => 1,
  'P_test args look OK'   => 1,
  'Got other_register'    => 1,
  'Got Process_test'      => 1,
};

{
  package
    MyPlugin;
  use strict; use warnings FATAL => 'all';
  use Test::More;

  use MooX::Role::Pluggable::Constants;

  sub new { bless [], shift }

  sub plugin_register {
    my ($self, $core) = splice @_, 0, 2;

    $plugin_got->{'Got plugin_register'}++;

    $core->subscribe( $self, 'PROCESS', 'all' );

    EAT_NONE
  }

  sub plugin_unregister {
    $plugin_got->{'Got plugin_unregister'}++;
    EAT_NONE
  }

  sub P_test {
    my ($self, $core) = splice @_, 0, 2;
    my ($first, $second) = @_;

    $plugin_got->{'P_test args look OK'}++
      if $$first eq 'first' and $$second eq 'second';

    EAT_NONE
  }

  sub other_register {
    my ($self, $core) = splice @_, 0, 2;

    $plugin_got->{'Got other_register'}++;

    $core->subscribe( $self, 'PROCESS', 'all' );

    EAT_NONE
  }
  sub other_unregister { EAT_NONE }

  sub Process_test {
    $plugin_got->{'Got Process_test'}++;

    EAT_NONE
  }
}

my $disp = MyDispatcher->new;

ok( $disp->does('MooX::Role::Pluggable'), 'Class does Role' );

ok( $disp->plugin_add( 'MyPlug', MyPlugin->new ), 'plugin_add()' );

$disp->do_test_events;

$disp->shutdown;

ok( $disp->_pluggable_init(
  types => { PROCESS => "Process" },
  reg_prefix => 'other_',
), '_pluggable_init()' );
$disp->plugin_add( 'MyPlugB', MyPlugin->new );
$disp->process('test');

test_expected_ok( $dispatcher_got, $dispatcher_expected,
  'Got expected results from Dispatcher'
);

test_expected_ok( $plugin_got, $plugin_expected,
  'Got expected results from Plugin'
);

done_testing();
