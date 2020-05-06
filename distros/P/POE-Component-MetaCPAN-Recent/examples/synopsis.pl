  use strict;
  use POE qw(Component::MetaCPAN::Recent);

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start upload)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::MetaCPAN::Recent->spawn(
        event => 'upload',
        delay => 60,
    );
    return;
  }

  sub upload {
    use Data::Dumper;
    print Dumper( $_[ARG0] );
    return;
  }

