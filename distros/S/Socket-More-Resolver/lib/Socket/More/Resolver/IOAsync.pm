use v5.36;
package Socket::More::Resolver::Async;
use base qw(Socket::More::Resolver::Async IO::Async::Notifier );

use Socket::More::Resolver;

use IO::Async::Handle;


sub import {
  shift;
  shift;
  my %options=@_;

  # Create a shared resolver object
  unless($options{no_shared}){
      $Socket::More::Resolver::Shared= __PACKAGE__->new;
  }

}

sub _reexport {
    Socket::More::Resolver->import;
}

sub new {
  my $package=shift;
  my $self=bless {},$package;
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
          Socket::More::Resolver::process_results $fd_worker_map{$in_fd};
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
