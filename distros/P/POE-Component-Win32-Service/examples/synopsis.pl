  use strict;
  use POE qw(Component::Win32::Service);

  my ($poco) = POE::Component::Win32::Service->spawn( alias => 'win32-service', debug => 1, options => { trace => 1 } );

  # Start your POE sessions

  POE::Session->create(
        package_states => [
                'main' => [ qw(_start result) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    $_[KERNEL]->post( 'win32-service' => restart => { host => 'win32server', 
                                               service => 'someservice',
                                               event => 'result' } );
    undef;
  }

  sub result {
    my ($kernel,$ref) = @_[KERNEL,ARG0];

    if ( $ref->{result} ) {
        print STDOUT "Service " . $ref->{service} . " was restarted\n";
    } else {
        print STDERR join(' ', @{ $ref->{error} } ) . "\n";
    }
    $kernel->post( 'win32-service' => 'shutdown' );
    undef;
  }

