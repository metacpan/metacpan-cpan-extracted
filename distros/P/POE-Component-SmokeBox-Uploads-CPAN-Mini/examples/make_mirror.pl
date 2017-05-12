  use strict;
  use warnings;
  use POE qw(Component::SmokeBox::Uploads::CPAN::Mini);
  use Data::Dumper;

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start upload)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Uploads::CPAN::Mini->spawn(
        event => 'upload',
	remote => 'ftp://ftp.funet.fi/pub/CPAN/',
	'local' => '/home/ftp/CPAN/',
	class => 'CPAN::Mini::Devel',
	debug => 1,
    );
    return;
  }

  sub upload {
    print Dumper( $_[ARG0] );
    return;
  }
