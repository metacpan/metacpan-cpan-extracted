=head1 NAME

Socket::More::Resolver::AE - Resolver AnyEvent integration

=head1 SYNOPSIS

  use AnyEvent;

  use Socket::More::Resolver;

  ... 

  getaddrinfo...

=head1 DESCRIPTION

Built in driver for integrating L<Socket::More::Resolver> into the
L<Mojo::IOLoop>.

If the event loop module is already in memory, it should automatically be
detected when using L<Socket::More::Resolver>;

=cut

use warnings;
use strict;
package Socket::More::Resolver::AE;

# Circular reference to lexical scope variable.
my $circle=[];
my $_timer;   
my @watchers;
push @$circle, $circle, \$_timer, \@watchers;

  
# Return true value (code ref) on require
# NOTE  
sub {
  # Code here to set up event handling on $loop that may be required
  my @fh=Socket::More::Resolver::to_watch;
  for(@fh){
    #my $fh=$_;
    my $in_fd=fileno $_;
    my $w= AE::io $in_fd, 0, sub {
          Socket::More::Resolver::process_results $in_fd;
    };
    push @watchers, $w;
  }
  $Socket::More::Resolver::Shared=1; 
  #setup timer to monitor child existance
  $_timer=AE::timer 0, 1, \&Socket::More::Resolver::monitor_workers;

}

