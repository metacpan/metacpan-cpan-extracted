  use strict;
  use POE qw(Component::WWW::Shorten);

  my $poco = POE::Component::WWW::Shorten->spawn( alias => 'shorten', type => 'Metamark' );

  POE::Session->create(
        package_states => [
                'main' => [ qw(_start _shortened) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
        my ($kernel,$heap) = @_[KERNEL,HEAP];

        $kernel->post( 'shorten' => 'shorten' => 
          { 
                url => 'http://reallyreallyreallyreally/long/url',
                event => '_shortened',
                _arbitary_value => 'whatever',
          }
        );
        undef;
  }

  sub _shortened {
        my ($kernel,$heap,$returned) = @_[KERNEL,HEAP,ARG0];

        if ( $returned->{short} ) {
           print STDOUT $returned->{short} . "\n";
        }

        print STDOUT $returned->{_arbitary_value} . "\n";
        undef;
  }
