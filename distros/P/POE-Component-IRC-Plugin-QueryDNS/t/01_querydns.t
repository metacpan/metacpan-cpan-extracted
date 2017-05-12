use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok('POE::Component::IRC') };
BEGIN { use_ok('POE::Component::IRC::Plugin::QueryDNS') };
use POE;

my $self = POE::Component::IRC->spawn( plugin_debug => 1 );
isa_ok ( $self, 'POE::Component::IRC' );

POE::Session->create(
	inline_states => { _start => \&test_start, },
	package_states => [
	  'main' => [ qw(irc_plugin_add irc_plugin_del) ],
	],
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  $self->yield( 'register' => 'all' );

  my $plugin = POE::Component::IRC::Plugin::QueryDNS->new();
  isa_ok ( $plugin, 'POE::Component::IRC::Plugin::QueryDNS' );
  
  unless ( $self->plugin_add( 'TestPlugin' => $plugin ) ) {
	fail( 'plugin_add' );
  	$self->yield( 'unregister' => 'all' );
  	$self->yield( 'shutdown' );
  }

  undef;
}

sub irc_plugin_add {
  my ($kernel,$heap,$desc,$plugin) = @_[KERNEL,HEAP,ARG0,ARG1];

  isa_ok ( $plugin, 'POE::Component::IRC::Plugin::QueryDNS' );
  
  unless ( $self->plugin_del( 'TestPlugin' ) ) {
  	fail( 'plugin_del' );
  	$self->yield( 'unregister' => 'all' );
  	$self->yield( 'shutdown' );
  }
  undef;
}

sub irc_plugin_del {
  my ($kernel,$heap,$desc,$plugin) = @_[KERNEL,HEAP,ARG0,ARG1];

  isa_ok ( $plugin, 'POE::Component::IRC::Plugin::QueryDNS' );
  
  $self->yield( 'unregister' => 'all' );
  $self->yield( 'shutdown' );
  undef;
}
