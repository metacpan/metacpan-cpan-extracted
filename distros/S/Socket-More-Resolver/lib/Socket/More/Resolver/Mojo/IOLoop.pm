=head1 NAME

Socket::More::Resolver::Mojo::IOLoop - Resover Mojo::IOLoop integration

=head1 SYNOPSIS

  use Mojo::IOLoop;

  use Socket::More::Resolver;

  ... 

  getaddrinfo...

=head1 DESCRIPTION

Built in driver for integrating L<Socket::More::Resolver> into the
L<Mojo::IOLoop>.

If the event loop module is already in memory, it should automatically be
detected when useing L<Socket::More::Resolver>;

=cut

use warnings;
use strict;
package Socket::More::Resolver::Mojo::IOLoop;

use IO::Handle;
use Mojo::IOLoop;

# Circular reference to lexical scope variable.
my $circle=[];
my @watchers;
push @$circle, $circle, \@watchers;

sub {

  # Use singleton loop if none specified
  my $loop//=Mojo::IOLoop->singleton;
  $Socket::More::Resolver::Shared=1;
  # Code here to set up event handling on $loop that may be required
  my @fh=Socket::More::Resolver::to_watch;
  for(@fh){
    my $fh=$_;
    my $in_fd=fileno $fh;
    my $w=IO::Handle->new_from_fd($in_fd, "r");
    $loop->reactor->io($w, sub {
          Socket::More::Resolver::process_results $in_fd;
      }
    )->watch($w, 1, 0);
    push @watchers, $w;
  }


  # Add timer/monitor here
  $loop->recurring(1, \&Socket::More::Resolver::monitor_workers);
  
  # set clean up routine here
}



