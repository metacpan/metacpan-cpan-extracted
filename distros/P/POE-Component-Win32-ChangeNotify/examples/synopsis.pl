   use strict;
   use POE;
   use POE::Component::Win32::ChangeNotify;

   my $poco = POE::Component::Win32::ChangeNotify->spawn( alias => 'blah' );

   POE::Session->create(
        package_states => [ 
                'main' => [ qw(_start notification) ],
        ],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];

     $kernel->post( 'blah' => monitor => 
     {
        'path' => '.',
        'event' => 'notification',
        'filter' => 'ATTRIBUTES DIR_NAME FILE_NAME LAST_WRITE SECURITY SIZE',
        'subtree' => 1,
     } );

     undef;
   }

   sub notification {
     my ($kernel,$hashref) = @_[KERNEL,ARG0];

     if ( $hashref->{error} ) {
        print STDERR $hashref->{error} . "\n";
     } else {
        print STDOUT "Something changed in " . $hashref->{path} . "\n";
     }
     $kernel->post( 'blah' => 'shutdown' );
     undef;
   }

