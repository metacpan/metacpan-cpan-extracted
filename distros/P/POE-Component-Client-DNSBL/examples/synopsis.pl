  use strict;
  use POE qw(Component::Client::DNSBL);

  die "Please provide at least one IP address to lookup\n" unless scalar @ARGV;

  my $dnsbl = POE::Component::Client::DNSBL->spawn();

  POE::Session->create(
        package_states => [
            'main' => [ qw(_start _stop _response) ],
        ],
        heap => {
                  addresses => [ @ARGV ],
                  dnsbl => $dnsbl
        },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     $heap->{dnsbl}->lookup(
        event => '_response',
        address => $_,
     ) for @{ $heap->{addresses} };
     return;
  }

  sub _stop {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     $kernel->call( $heap->{dnsbl}->session_id(), 'shutdown' );
     return;
  }

  sub _response {
     my ($kernel,$heap,$record) = @_[KERNEL,HEAP,ARG0];
     if ( $record->{error} ) {
        print "An error occurred, ", $record->{error}, "\n";
        return;
     }
     if ( $record->{response} eq 'NXDOMAIN' ) {
        print $record->{address}, " is okay\n";
        return;
     }
     print join( " ", $record->{address}, $record->{response}, $record->{reason} ), "\n";
     return;
  }

