  use strict;
  use POE qw(Component::SmokeBox::Recent);

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start recent)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Recent->recent(
        url => 'ftp://ftp.funet.fi/pub/CPAN/',
        event => 'recent',
    );
    return;
  }

  sub recent {
    my $hashref = $_[ARG0];
    if ( $hashref->{error} ) {
        print $hashref->{error}, "\n";
        return;
    }
    print $_, "\n" for @{ $hashref->{recent} };
    return;
  }

