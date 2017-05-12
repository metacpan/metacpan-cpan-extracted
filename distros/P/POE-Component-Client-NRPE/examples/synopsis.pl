   # A simple 'check_nrpe' version 2 clone
   use strict;
   use POE qw(Component::Client::NRPE);
   use Getopt::Long;

   $|=1;

   my $command;
   my $hostname;
   my $return_code;

   GetOptions("host=s", \$hostname, "command=s", \$command);

   unless ( $hostname ) {
        $! = 3;
        die "No hostname specified\n";
   }

   POE::Session->create(
        inline_states => {
                _start =>
                sub {
                   POE::Component::Client::NRPE->check_nrpe(
                        host    => $hostname,
                        command => $command,
			event   => '_result',
                   );
                   return;
                },
                _result =>
                sub {
                   my $result = $_[ARG0];
                   print STDOUT $result->{data}, "\n";
                   $return_code = $result->{result};
                   return;
                },
        }
   );

   $poe_kernel->run();
   exit($return_code);
