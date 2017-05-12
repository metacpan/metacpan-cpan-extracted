  # A fairly simple example:
  use strict;
  use warnings;
  use POE qw(Component::Server::IRC);

  my %config = (
                servername => 'simple.poco.server.irc',
                nicklen    => 15,
                network    => 'SimpleNET'
  );

  my $pocosi = POE::Component::Server::IRC->spawn( config => \%config );

  POE::Session->create(
        package_states => [
           'main' => [qw(_start _default)],
        ],
        heap => { ircd => $pocosi },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{ircd}->yield( 'register' );
    # Anyone connecting from the loopback gets spoofed hostname
    $heap->{ircd}->add_auth( mask => '*@localhost', spoof => 'm33p.com', no_tilde => 1 );
    # We have to add an auth as we have specified one above.
    $heap->{ircd}->add_auth( mask => '*@*' );
    # Start a listener on the 'standard' IRC port.
    $heap->{ircd}->add_listener( port => 6667 );
    # Add an operator who can connect from localhost
    $heap->{ircd}->add_operator( { username => 'moo', password => 'fishdont' } );
    undef;
  }

  sub _default {
     my ( $event, $args ) = @_[ ARG0 .. $#_ ];
     print STDOUT "$event: ";
     foreach (@$args) {
     SWITCH: {
              if ( ref($_) eq 'ARRAY' ) {
                  print STDOUT "[", join ( ", ", @$_ ), "] ";
                  last SWITCH;
              }
              if ( ref($_) eq 'HASH' ) {
                  print STDOUT "{", join ( ", ", %$_ ), "} ";
                  last SWITCH;
              }
              print STDOUT "'$_' ";
          }
      }
      print STDOUT "\n";
      return 0;    # Don't handle signals.
  }
