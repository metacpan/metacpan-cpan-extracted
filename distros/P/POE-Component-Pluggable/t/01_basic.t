use strict;
use warnings;
use Test::More tests => 9;

{
  package TestSubClass;
  use strict;
  use warnings;
  use base qw(POE::Component::Pluggable);
  use POE::Component::Pluggable::Constants qw(:ALL);
  use POE;
  
  sub spawn {
    my $package = shift;
    my $self = bless { }, $package;
    $self->_pluggable_init( prefix => 'testsub_', types => [ 'SERVER' ] );
    $self->{session_id} = POE::Session->create(
	object_states => [
		$self => [ qw(_start __send_event test noret shutdown) ],
	],
	heap => $self,
	options => { trace => 0 },
    )->ID();
    return $self;
  }

  sub _start {
    my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
    $self->{session_id} = $_[SESSION]->ID();
    $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );
    $self->{sender_id} = $sender->ID();
    $kernel->refcount_increment( $self->{sender_id}, __PACKAGE__ );
    return;
  }

  sub shutdown {
    my ($kernel,$self) = @_[KERNEL,OBJECT];
    $self->_pluggable_destroy();
    $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );
    $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
    return;
  }

  sub _pluggable_event {
    my $self = shift;
    $poe_kernel->post( $self->{session_id}, '__send_event', @_ );
  }

  sub __send_event {
    my( $self, $event, @args ) = @_[ OBJECT, ARG0, ARG1 .. $#_ ];
    $self->_send_event( $event, @args );
    return;
  }

  sub _send_event {
    my $self = shift;
    my ($event, @args) = @_;
    return 1 if $self->_pluggable_process( 'SERVER', $event, \( @args ) ) == PLUGIN_EAT_ALL;
    $poe_kernel->post( $self->{sender_id}, $event, @args );
    return 1;
  }

  sub test {
    my ($kernel,$self,@args) = @_[KERNEL,OBJECT,ARG0..$#_];
    $self->_send_event( $self->{_pluggable_prefix} . 'test', @args );
    return;
  }

  sub noret {
    my ($kernel,$self,@args) = @_[KERNEL,OBJECT,ARG0..$#_];
    $self->_send_event( $self->{_pluggable_prefix} . 'noret', @args );
    return;
  }
}

{
  package TestPlugin;
  use strict;
  use warnings;
  use Test::More;
  use POE::Component::Pluggable::Constants qw(:ALL);

  sub new {
    my $package = shift;
    return bless { @_ }, $package;
  }

  sub plugin_register {
    my ($self,$subclass) = splice @_, 0, 2;
    pass(__PACKAGE__ . " Plugin Register");
    $subclass->plugin_register( $self, 'SERVER', qw(all) );
    return 1;
  }

  sub plugin_unregister {
    pass(__PACKAGE__ . " Plugin Unregister");
    return 1;
  }

  sub SERVER_test {
    my ($self,$irc) = splice @_, 0, 2;
    pass(__PACKAGE__ . ' test event' );
    return PLUGIN_EAT_NONE;
  }

  sub SERVER_noret {
    my ($self,$irc) = splice @_, 0, 2;
    pass(__PACKAGE__ . ' noret event' );
    return;
  }
}

use strict;
use warnings;
use POE;

POE::Session->create(
	package_states => [
		'main' => [qw(_start testsub_test testsub_noret testsub_plugin_add testsub_plugin_del)],
	],
	options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{test} = TestSubClass->spawn();
  isa_ok( $heap->{test}, 'POE::Component::Pluggable' );
  $heap->{test}->plugin_add( 'TestPlugin', TestPlugin->new() );
  return;
}

sub testsub_plugin_add {
  my ($kernel,$sender,$testplugin) = @_[KERNEL,SENDER,ARG1];
  isa_ok( $testplugin, 'TestPlugin' );
  $kernel->post( $sender, 'test', 'fubar' );
  return;
}

sub testsub_plugin_del {
  my ($kernel,$sender,$testplugin) = @_[KERNEL,SENDER,ARG1];
  isa_ok( $testplugin, 'TestPlugin' );
  return;
}

sub testsub_test {
  my ($kernel,$sender,$answer) = @_[KERNEL,SENDER,ARG0];
  ok( $answer eq 'fubar', "event was cool" );
  $kernel->post( $sender, 'noret' );
  return;
}

sub testsub_noret {
  my ($kernel,$sender,$answer) = @_[KERNEL,SENDER,ARG0];
  pass("testsub_noret");
  $kernel->post( $sender, 'shutdown' );
}
