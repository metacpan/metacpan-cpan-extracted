=head1 NAME

Socket::More::Resolver::IO::Async - Resolver IO::Async Integration

=head1 SYNOPSIS

  use IO::Async;

  use Socket::More::Resolver;

  ... 

  getaddrinfo...

=head1 DESCRIPTION

Built in driver for integrating L<Socket::More::Resolver> into the
L<IO::Async> event loop.

If the event loop module is already in memory, it should automatically be
detected when using L<Socket::More::Resolver>;

=cut

use warnings;
use strict;
package Socket::More::Resolver::IO::Async;
use parent qw(IO::Async::Notifier);
use IO::Async::Handle;

use Socket::More::Resolver ();   # no not run import

# Shared object,
my $_shared;


sub new {
  my $package=shift;
  return $_shared if $_shared;
  
  # 
  my $self=bless {}, $package;
  $self->{watchers}=[];
  $self;
}

sub _add_to_loop {
  my $self = shift;
  my ( $loop ) = @_;

  # Code here to set up event handling on $loop that may be required
  my @fh=Socket::More::Resolver::to_watch;
  my $watchers=$self->{watchers};
  for(@fh){
    my $fh=$_;
    my $w= IO::Async::Handle->new(
        read_handle=>$fh,
        on_read_ready=> sub {
          my $in_fd=fileno $fh;
          Socket::More::Resolver::process_results $in_fd;
      }
    );
    $loop->add($w);
    push @$watchers,$w;
  }
}
 
sub _remove_from_loop {
  my $self = shift;
  my ( $loop ) = @_;

  # Code here to undo the event handling set up above

  for($self->{watchers}->@*){
    $loop->remove($_); 
  }
  $self->{watchers}=[];
}

sub {
  $Socket::More::Resolver::Shared= __PACKAGE__->new;
}
