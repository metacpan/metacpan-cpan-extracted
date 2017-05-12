use strict;
use Net::Netmask;
use POE qw(Component::Proxy::SOCKS);

$|=1;

POE::Session->create(
   package_states => [ 
	'main' => [ qw(_start _default socksd_registered) ],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{socksd} = POE::Component::Proxy::SOCKS->spawn( alias => 'socksd', ident => 0 );
  return;
}

sub socksd_registered {
  my $socksd = $_[ARG0];
  my $all = Net::Netmask->new2('any');
  my $loopback = Net::Netmask->new2('127.0.0.1');
  my $local = Net::Netmask->new2('192.168.1.0/24');
  $socksd->add_denial( $all );
  $socksd->add_exemption( $loopback );
  $socksd->add_exemption( $local );
  return;
}

sub _default {
  my ($event, $args) = @_[ARG0 .. $#_];
  my @output = ( "$event: " );

  foreach my $arg ( @$args ) {
    if ( ref($arg) eq 'ARRAY' ) {
       push( @output, "[" . join(" ,", @$arg ) . "]" );
    } else {
       push ( @output, "'$arg'" );
    }
  }
  print STDOUT join ' ', @output, "\n";
  return 0;
}
