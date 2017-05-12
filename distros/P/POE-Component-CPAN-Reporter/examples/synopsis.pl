   use strict;
   use POE qw(Component::CPAN::Reporter Component::SmokeBox::Recent);
   use Getopt::Long;

   $|=1;

   my ($perl, $jobs, $recenturl);

   GetOptions( 'perl=s' => \$perl, 'jobs=s' => \$jobs, 'recenturl' => \$recenturl );

   my @pending;
   if ( $jobs ) {
     open my $fh, "<$jobs" or die "$jobs: $!\n";
     while (<$fh>) {
           chomp;
           push @pending, $_;
     }
     close($fh);
   }

   my $smoker = POE::Component::CPAN::Reporter->spawn( alias => 'smoker' );

   POE::Session->create(
         package_states => [
            'main' => [ qw(_start _stop _results _recent) ],
         ],
         heap => { perl => $perl, pending => \@pending },
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     if ( @{ $heap->{pending} } ) {
       $kernel->post( 'smoker', 'submit', { event => '_results', perl => $heap->{perl}, module => $_ } )
         for @{ $heap->{pending} };
     }
     else {
       POE::Component::SmokeBox::Recent->recent(
           url => $recenturl || 'http://www.cpan.org/',
           event => 'recent',
       );
       $kernel->post( 'smoker', 'recent', { event => '_recent', perl => $heap->{perl} } )
     }
     undef;
   }

   sub _stop {
     $poe_kernel->call( 'smoker', 'shutdown' );
     undef;
   }

   sub _results {
     my $job = $_[ARG0];
     print STDOUT "Module: ", $job->{module}, "\n";
     print STDOUT "$_\n" for @{ $job->{log} };
     undef;
   }

   sub _recent {
     my ($kernel,$heap,$job) = @_[KERNEL,HEAP,ARG0];
     die $job->{error}, "\n" if $job->{error};
     $kernel->post( 'smoker', 'submit', { event => '_results', perl => $heap->{perl}, module => $_ } )
         for @{ $job->{recent} };
     undef;
   }
