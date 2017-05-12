use Test::More;
use strict; use warnings FATAL => 'all';

use lib 't/inc';
use MxRPTestUtils;

my $dispatcher_got;
my $dispatcher_expected = {
  'P_test dispatch order correct' => 1,
  'plugin_added args correct'     => 6,
  'Got plugin_removed'            => 6,
  'Got plugin_error'              => 1,
  'plugin_error correct error'    => 1,
  '_default triggered'            => 1,
  'EAT_CLIENT was eaten'          => 1,
};

{
  package
    MyDispatcher;
  use Test::More;
  use Moo;
  with 'MooX::Role::Pluggable';

  use MooX::Role::Pluggable::Constants;

  sub process {
    my ($self, $event, @args) = @_;
    my $retval = $self->_pluggable_process( 'PROCESS', $event, \@args );
    $retval
  }

  sub shutdown {
    my ($self) = @_;
    $self->_pluggable_destroy;
  }

  sub do_test_events {
    my ($self) = @_;

    local $@;
    eval {; $self->_pluggable_init( types => '' ) };
    ok $@, 'Bad args _pluggable_init dies';
    eval {; $self->_pluggable_process('type', 'event') };
    ok $@, 'Bad args _pluggable_process dies';

    $self->process( 'test', 0 );
    $self->process( 'eatable' );
    $self->process( 'not_handled' );
    $dispatcher_got->{'EAT_CLIENT was eaten'}++
      if $self->process( 'eat_client' ) == EAT_ALL;

    { local *STDERR; my $err;
        open *STDERR, '+<', \$err;
        $self->process( 'dies' );
        fail("Expected a warning") unless $err;
    }
  }

  around '_pluggable_event' => sub {
    my ($orig, $self) = splice @_, 0, 2;
    $self->process( @_ )
  };

  sub P_test {
    my ($self, undef) = splice @_, 0, 2;
    ++${ $_[0] };

    ## We should be first.
    $dispatcher_got->{'P_test dispatch order correct'}++
      if ${ $_[0] } == 1;

    EAT_NONE
  }

  sub P_dies {
    my ($self, undef) = splice @_, 0, 2;
#    Test::More::diag("This will throw warning noise:");
    die "Plugin event died!";
  }

  sub P_plugin_added {
    ## +6 tests for reloads
    my ($self, undef) = splice @_, 0, 2;
    my $alias = ${ $_[0] };
    my $obj   = ${ $_[1] };

    $dispatcher_got->{'plugin_added args correct'}++
      if $alias and ref $obj;

    EAT_ALL
  }

  sub P_plugin_removed {
    $dispatcher_got->{'Got plugin_removed'}++;
    EAT_ALL
  }

  sub P_plugin_error {
    my ($self, undef) = splice @_, 0, 2;
    my $err = ${ $_[0] };
    my $obj = ${ $_[1] };
    my $src = ${ $_[2] };

    $dispatcher_got->{'Got plugin_error'}++;

    $dispatcher_got->{'plugin_error correct error'}++
      if $err =~ /Plugin event died/;

    EAT_ALL
  }

  sub P_eatable {
    EAT_NONE
  }

  sub _default {
    my ($self, undef) = splice @_, 0, 2;
    my $event = $_[0];

    $dispatcher_got->{'_default triggered'}++
      if $event eq 'P_not_handled';

    EAT_ALL
  }
}


my $pluginA_got;
my $pluginA_expected = {
  'Got plugin_register'   => 2,
  'Got plugin_unregister' => 2,
  'Got P_eatable'         => 1,
  'P_test dispatch order correct' => 1,
};

{
  package
    MyPlugin::A;
  use strict; use warnings FATAL => 'all';
  use Test::More;

  use MooX::Role::Pluggable::Constants;

  sub new { bless [], shift }

  sub plugin_register {
    my ($self, $core) = splice @_, 0, 2;

    $pluginA_got->{'Got plugin_register'}++;

    $core->subscribe( $self, 'PROCESS', 'all' );
    EAT_NONE
  }

  sub plugin_unregister {
    $pluginA_got->{'Got plugin_unregister'}++;

    EAT_NONE
  }

  sub P_eat_client {
    EAT_CLIENT
  }

  sub P_eatable {
    $pluginA_got->{'Got P_eatable'}++;

    EAT_PLUGIN
  }

  sub P_test {
    my ($self, $core) = splice @_, 0, 2;
    ++${ $_[0] };

    $pluginA_got->{'P_test dispatch order correct'}++
      if ${ $_[0] } > 1;

    EAT_NONE
  }

  sub _default {
    my ($self, $core) = splice @_, 0, 2;
    my $event = $_[0];
    ## Should have been EATen by dispatcher
    fail("_default should not have triggered in plugin but got $event")
      unless $event eq 'P_dies';
  }
}


my $pluginB_got;
my $pluginB_expected = {
  'Got plugin_register'   => 1,
  'Got plugin_unregister' => 1,
  'Got P_test'            => 1,
};

{
  package
    MyPlugin::B;
  use strict; use warnings FATAL => 'all';
  use Test::More;

  use MooX::Role::Pluggable::Constants;

  sub new { bless [], shift }

  sub plugin_register {
    my ($self, $core) = splice @_, 0, 2;

    $pluginB_got->{'Got plugin_register'}++;

    $core->subscribe( $self, 'PROCESS', 'test', 'eatable' );

    EAT_NONE
  }

  sub plugin_unregister {
    $pluginB_got->{'Got plugin_unregister'}++;
    EAT_NONE
  }

  sub P_eatable {
    fail("Plugin::B should not have received P_eatable")
  }

  sub P_test {
    my ($self, $core) = splice @_, 0, 2;
    $pluginB_got->{'Got P_test'}++;
    EAT_NONE
  }

  sub P_default {
    fail("default should not have triggered in plug B");
  }
}

my $disp = MyDispatcher->new;

ok( $disp->does('MooX::Role::Pluggable'), 'Class does Role' );


## plugin_add()
ok( $disp->plugin_add( 'MyPlugA', MyPlugin::A->new ), 'plugin_add()' );
ok( $disp->plugin_add( 'MyPlugB', MyPlugin::B->new ), 'plugin_add() 2' );


## test events
$disp->do_test_events;


## plugin_get()
{
 my $retrieved;
 ok( $retrieved = $disp->plugin_get('MyPlugA'), 'scalar plugin_get()' );
 isa_ok( $retrieved, 'MyPlugin::A' );

 my($obj, $alias);
 cmp_ok(
   ($obj, $alias) = $disp->plugin_get($retrieved),
   '==', 2,
   'list plugin_get()' 
 );
 cmp_ok( $alias, 'eq', 'MyPlugA', 'plugin_get returns correct alias' );
 isa_ok( $obj, 'MyPlugin::A', 'plugin_get returns correct obj' );
}

## plugin_alias_list()
## (should be ordered)
my @listed = $disp->plugin_alias_list;
is_deeply \@listed, [ 'MyPlugA', 'MyPlugB' ],
  'plugin_alias_list ok';

## plugin_pipe_bump_up()
$disp->plugin_pipe_bump_up( 'MyPlugB', 1 );
cmp_ok( $disp->plugin_pipe_get_index('MyPlugB'), '==', 0, 'PlugB at pos 0' );

## plugin_pipe_bump_down()
$disp->plugin_pipe_bump_down( 'MyPlugB', 1 );
cmp_ok( $disp->plugin_pipe_get_index('MyPlugB'), '==', 1, 'PlugB at pos 1' );

{
## plugin_pipe_shift()
  my $thisplug;
  ok( $thisplug = $disp->plugin_pipe_shift, 'plugin_pipe_shift()' );
  isa_ok( $thisplug, 'MyPlugin::A' );

  cmp_ok( $disp->plugin_pipe_get_index('MyPlugB'), '==', 0, 'PlugB at pos 0' );

## plugin_pipe_unshift()
  ok( $disp->plugin_pipe_unshift(
    'MyPlugA', $thisplug
    ), 'plugin_pipe_unshift'
  );
  cmp_ok( $disp->plugin_pipe_get_index('MyPlugA'), '==', 0, 'PlugA at pos 0' );
}

{
  package
    MyPlugin::Bare;
  use Test::More;
  use strict; use warnings;
  use MooX::Role::Pluggable::Constants;

  sub new { bless [], shift }

  sub plugin_register {
    EAT_NONE
  }

  sub plugin_unregister {
    EAT_NONE
  }
}

## plugin_replace()
ok( $disp->plugin_replace(
    old    => 'MyPlugA',
    alias  => 'NewPlugA',
    plugin => MyPlugin::Bare->new,
  ), 'plugin_replace'
);
cmp_ok($disp->plugin_pipe_get_index('NewPlugA'), '==', 0, 'NewPlug at pos 0' );

## plugin_pipe_insert_after()
ok( $disp->plugin_pipe_insert_after(
    after  => 'NewPlugA',
    alias  => 'NewPlugB',
    plugin => MyPlugin::Bare->new,
  ), 'plugin_pipe_insert_after'
);
cmp_ok($disp->plugin_pipe_get_index('NewPlugB'), '==', 1, 'NewPlugB at pos 1' );

## plugin_pipe_insert_before()
ok( $disp->plugin_pipe_insert_before(
    before => 'NewPlugB',
    alias  => 'NewPlugC',
    plugin => MyPlugin::Bare->new,
  ), 'plugin_pipe_insert_before'
);
cmp_ok($disp->plugin_pipe_get_index('NewPlugC'), '==', 1, 'NewPlugC at pos 1' );

$disp->shutdown;

test_expected_ok( $dispatcher_got, $dispatcher_expected,
  'Got expected results from Dispatcher'
);

test_expected_ok( $pluginA_got, $pluginA_expected,
  'Got expected results from Plugin A'
);

test_expected_ok( $pluginB_got, $pluginB_expected,
  'Got expected results from Plugin B'
);


done_testing();
