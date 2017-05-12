   use strict;
   use warnings;
   use lib '../blib/lib';
   use POE qw(Component::Client::Whois);
   use Data::Dumper;

   die unless $ARGV[0];

   POE::Session->create(
        package_states => [
                'main' => [ qw(_start _response) ],
        ],
	heap => { query => $ARGV[0] },
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];

     POE::Component::Client::Whois->whois( query => $heap->{query},
                                           event => '_response',
                                           _arbitary => [ qw(moo moo moo) ] );
     undef;
   }

   sub _response {
        print STDERR Dumper( $_[ARG0] );
   }
