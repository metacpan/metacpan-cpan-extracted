  use strict;
  use POE qw(Component::SmokeBox::Uploads::NNTP);

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start upload)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Uploads::NNTP->spawn(
        event => 'upload',
    );
    return;
  }

  sub upload {
    print $_[ARG0], "\n";
    return;
  }

