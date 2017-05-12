   use strict;
   use POE qw(Component::Client::NSCA);
   use Data::Dumper;

   POE::Session->create(
        inline_states => {
                _start =>
                sub {
                   POE::Component::Client::NSCA->send_nsca(
                        host    => $hostname,
                        event   => '_result',
                        password => 'moocow',
                        encryption => 1, # Lets use XOR
                        message => {
                                        host_name => 'bovine',
                                        svc_description => 'chews',
                                        return_code => 0,
                                        plugin_output => 'Chewing okay',
                        },
                   );
                   return;
                },
                _result =>
                sub {
                   my $result = $_[ARG0];
                   print Dumper( $result );
                   return;
                },
        }
   );

   $poe_kernel->run();
   exit 0;

