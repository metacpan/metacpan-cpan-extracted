   use strict;
   use warnings;
   use POE qw(Component::Server::Ident);

   POE::Component::Server::Ident->spawn ( Alias => 'Ident-Server' );

   POE::Session->create ( 
        package_states => [
                'main' => [qw(_start identd_request)],
        ],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
      $poe_kernel->post( 'Ident-Server' => 'register' );
      undef;
   }


   sub identd_request {
      my ($kernel,$sender,$peeraddr,$port1,$port2) = @_[KERNEL,SENDER,ARG0,ARG1,ARG2];
      my ($val1,$val2);
      $val1 = $val2 = int(rand(99999));
      $val1 =~ tr/0-9/A-Z/;
      $kernel->call ( $sender => ident_server_reply => 'OTHER' => "$val1$val2" );
      undef;
   }
