package MyWaiter;
use strict;
use parent qw( Net::Waiter );

use Data::Dumper;

sub dump_args
{
return;
  my ( $package, $filename, $line, $subroutine ) = caller( 1 );
  my @args = @_;
  shift( @args );
  print Dumper( { $subroutine => \@args }, "\n\n" );
}

sub on_listen_ok
{
  dump_args( @_ );
}

sub on_accept_error
{
  dump_args( @_, $! );
}

sub on_accept_ok
{
  my $sock = $_[1];
  dump_args( @_ );
  my $peerhost = $sock->peerhost();
  print "client connected from $peerhost\n";
}

sub on_fork_ok
{
  dump_args( @_ );
}

sub on_process
{
  my $sock = $_[1];
  dump_args( @_ );

  my $body = "hello world\n";
  my $clen = length $body;
  sleep 1;
  print $sock "HTTP/1.0 200 OK\ncontent-type: text/plain\ncontent-length: $clen\n\n$body";
  #return sleep rand 3;
}

sub on_close
{
  dump_args( @_ );
}

sub on_server_close
{
  dump_args( @_ );
}

sub on_ssl_error
{
  dump_args( @_ );
}

sub on_sig_child
{
  dump_args( @_ );
}

sub on_sig_usr1
{
  dump_args( @_ );
}

sub on_sig_usr2
{
  dump_args( @_ );
}

sub on_child_exit
{
  print "child grace exit [$$]\n";
}

sub on_prefork_child_idle
{
  print "child idle [$$]\n";
}

1;
