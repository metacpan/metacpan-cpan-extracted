use strict;
use warnings;
use POE qw(Component::Win32::Service);
use Data::Dumper;

$|=1;

my $poco = POE::Component::Win32::Service->spawn( alias => 'win32-service', debug => 1, options => { trace => 1 } );

POE::Session->create(
        package_states => [
                'main' => [ qw(_start _poll _result _sig_int) ],
        ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->alias_set('foo');
  $poe_kernel->yield( '_poll' );
  $poe_kernel->sig( 'INT', '_sig_int' );
  undef;
}

sub _poll {
  $poe_kernel->post( 'win32-service', 'services', { event => '_result' } );
  undef;
}

sub _result {
  print STDOUT Dumper( $_[ARG0] );
  $poe_kernel->delay( '_poll', 60 );
  undef;
}

sub _sig_int {
  $poe_kernel->post( 'win32-service', 'shutdown' );
  $poe_kernel->alarm_remove_all();
  $poe_kernel->sig( 'INT' );
  $poe_kernel->sig_handled();
}
