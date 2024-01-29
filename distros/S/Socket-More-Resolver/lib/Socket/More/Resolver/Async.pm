use v5.36;
package Socket::More::Resolver::Async;
use parent qw(IO::Async::Notifier);
use IO::Async::Handle;

use Socket::More::Resolver ();# no_export=>1;

# Shared object,
my $_shared;

sub new;

#import actually creates a shared object if it doesn't exist
sub import {
  shift;
  return if $_shared;
  $_shared=new(__PACKAGE__,   @_);
}


sub getaddrinfo{
  my $self=shift;
  &Socket::More::Resolver::getaddrinfo;
}

sub getnameinfo{
  my $self=shift;
  &Socket::More::Resolver::getnameinfo;
}

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


1;
