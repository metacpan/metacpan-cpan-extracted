  use strict;
  use POE;
  use POE::Component::Server::NSCA;

  my $nagios_cmd = '/usr/local/nagios/var/rw/nagios.cmd';

  my $nscad = POE::Component::Server::NSCA->spawn(
        password => 'moocow',
        encryption => 1,
  );

  POE::Session->create(
        package_states => [
           'main' => [qw(_start _message)],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
     $poe_kernel->post( $nscad->session_id(), 'register', event => '_message', context => 'moooo!' );
     return;
  }

  sub _message {
     my ($message,$context) = @_[ARG0,ARG1];

     print "Received message from: ", $message->{peeraddr}, "\n";

     # Send the check to the Nagios command file

     my $time = time();
     my $string;

     if ( $message->{svc_description} ) {
        $string = "[$time] PROCESS_SERVICE_CHECK_RESULT";
        $string = join ';', $string, $message->{host_name}, $message->{svc_description},
                    $message->{return_code}, $message->{plugin_output};
     }
     else {
        $string = "[$time] PROCESS_HOST_CHECK_RESULT";
        $string = join ';', $string, $message->{host_name}, $message->{return_code},
                    $message->{plugin_output};
     }

     print { open my $fh, '>>', $nagios_cmd or die "$!\n"; $fh } $string, "\n";

     return;
  }
