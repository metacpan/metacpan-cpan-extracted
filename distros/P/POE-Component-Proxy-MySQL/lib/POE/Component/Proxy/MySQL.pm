package POE::Component::Proxy::MySQL;
use Moose;
use MooseX::MethodAttributes;

our $VERSION = "0.04";

use strict;    # for kwalitee
use warnings;  # for kwalitee

with 'MooseX::Getopt';

use Socket;
use POSIX qw(errno_h);
use Data::Dumper;
use Module::Find;
use POE qw( 
   Wheel::ReadWrite 
   Wheel::SocketFactory 
   Filter::Stream 
);
use POE::Component::Proxy::MySQL::Forwarder;



has 'src_address'    => (is => 'rw', isa => 'Str', default => '127.0.0.1');
has 'src_port'       => (is => 'rw', isa => 'Int', default => 23306);

has 'dst_address'    => (is => 'rw', isa => 'Str', default => '127.0.0.1');
has 'dst_port'       => (is => 'rw', isa => 'Int', default => 3306);

has 'processes'      => (is => 'rw', isa => 'Int', default => 4);

has 'conn_per_child' => (is => 'rw', isa => 'Int', default => 4096);


sub DEBUG {1}

sub BUILD {
	my ($self, $opt) = @_;

   $self->processes($self->processes - 1);
   $self->processes(1) if $self->processes < 1;

   POE::Session->create(
     object_states => [
         $self =>  { 
            _start         => '_server_start',
            _stop          => '_server_stop',
            _do_fork       => '_do_fork',   
            accept_success => '_server_accept_success',
            accept_failure => '_server_accept_failure',   
            got_sig_int    => '_got_sig_int',
            got_sig_child  => '_got_sig_child',
            restart        => '_restart',    
            ticks          => '_ticks',   
         }
     ],
      args => [$self->src_address, $self->src_port, $self->dst_address, $self->dst_port]
   );

   return $self;
}



sub _server_start {
   my ($self, $heap, $session, $local_addr, $local_port, $remote_addr, $remote_port) =
    @_[OBJECT, HEAP, SESSION, ARG0, ARG1, ARG2, ARG3];
   
   print "Redirecting $local_addr:$local_port to $remote_addr:$remote_port\n";
   
   $heap->{local_addr}     = $local_addr;
   $heap->{local_port}     = $local_port;
   $heap->{remote_addr}    = $remote_addr;
   $heap->{remote_port}    = $remote_port;
   $heap->{is_a_child}     = 0;
   $heap->{processes}      ||= $self->processes;
   $heap->{conn_per_child} ||= $self->conn_per_child;
   $heap->{can_fork}       = 0;
   
   $heap->{server_wheel} = POE::Wheel::SocketFactory->new(
      BindAddress  => $local_addr,
      BindPort     => $local_port,
      Reuse        => 'yes',
      SuccessEvent => 'accept_success',
      FailureEvent => 'accept_failure',
   );

   $heap->{pid} = $$;
   
   if ($heap->{processes} > 0) {
      $_[KERNEL]->yield('_do_fork');
   }
}


sub _ticks {
   my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];
   
   if ($heap->{is_a_child}) {
      
      if ($heap->{connections_per_child}->{$$} >= $heap->{conn_per_child}
            && $heap->{is_a_child}) {
         $heap->{can_fork} = 1;
         $kernel->yield('_do_fork');
         $heap->{server_wheel}->pause_accept;
      }
      else {
          $kernel->delay_set('ticks', 10);
      }
      
   }

}

sub _restart {
   my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
   
   $_[KERNEL]->delay_set('tick', 60);
}

sub _got_sig_int {
   my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
   
  delete $heap->{server};
  $kernel->sig_handled();
}

sub _got_sig_child {
  my ($kernel, $heap, $child_pid) = @_[KERNEL, HEAP, ARG1];

  return unless delete $heap->{children}->{$child_pid};

  $kernel->yield("_do_fork") if exists $_[HEAP]->{server_wheel};
}

sub _do_fork {
   my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
   
   return if $heap->{is_a_child} && !$heap->{can_fork};
   
   while (scalar(keys %{$heap->{children}}) < $heap->{processes}) {
      my $pid = fork();
      
      unless (defined($pid)) {
         $kernel->delay(do_fork => 1);
         return;
      }
      
      if ($pid) {
         $heap->{server_wheel}->pause_accept;
         $heap->{children}->{$pid} = 1;
         $kernel->sig_child($pid, "got_sig_child");
         next;
      }
      
      $heap->{connections_per_child}->{$$} = 0;
      $heap->{active_connections}->{$$} = 0;
   
      $heap->{server_wheel}->resume_accept;
      $kernel->has_forked();
      $heap->{is_a_child} = 1;
      $heap->{children}   = {};
      $_[KERNEL]->yield('ticks');
      return;
   }
}

sub _server_stop {
   my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
   
}

sub _server_accept_success {
   my ($self, $heap, $socket, $peer_addr, $peer_port) = @_[OBJECT, HEAP, ARG0, ARG1, ARG2];

   my $forwarder = POE::Component::Proxy::MySQL::Forwarder->new({
      socket         => $socket, 
      peer_addr      => $peer_addr, 
      peer_port      => $peer_port, 
      remote_addr    => $heap->{remote_addr}, 
      remote_port    => $heap->{remote_port}, 
      heap           => $heap,
      namespace      => ref($self),
   });

}

sub _server_accept_failure {
  my ($heap, $operation, $errnum, $errstr) = @_[HEAP, ARG0, ARG1, ARG2];

  delete $heap->{server_wheel} if $errnum == ENFILE or $errnum == EMFILE;
}

sub run {
   POE::Kernel->run();
}

=head1 NAME

POE::Component::Proxy::MySQL - A MySQL POE Proxy

=head1 DESCRIPTION

This modules helps building a MySQL proxy in which you can write
handler to deal with specific queries.

You can modifiy the query, write a specific response, relay a query
or do wahtever you want within each handler.

This is the evolution of POE::Component::DBIx::MyServer, it
uses Moose and POE.

=head1 SYNOPSYS

First you create a server class that extends POE::Component::Server::MySQL.

   package MyMySQL;
   use Moose;
   
   extends 'POE::Component::Server::MySQL';
   with 'MooseX::Getopt';

Then in a perl script you can instantiate your new server

   use MyMySQL;
   my $server = MyMySQL->new_with_options();
   $server->run;

In the MyMySQL namespace you can add roles which will act as handlers
for your trapped queries:

   package MyMySQL::Hello;
   
   use POE;
   use MooseX::MethodAttributes::Role;
   
   sub fortune : Regexp('qr{fortune}io') {
      my ($self) = $_[OBJECT];   
      
      my $fortune = `fortune`;
      chomp($fortune);
      
      $self->client_send_results(
         ['fortune'],
         [[$fortune]]
      );
   
   }


Then run your proxy

   perl mymysql.pl --src_address localhost --src_port 23306 --dst_address localhost --dst_port 3306


and finally

   [eriam@fbsd ~]# mysql -u root -pxxx --host localhost --port 23306
   Welcome to the MySQL monitor.  Commands end with ; or \g.
   Your MySQL connection id is 6
   Server version: 5.1.40 Source distribution
   
   Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
   
   mysql> fortune();
   +---------------------------------------------------------------------+
   | fortune                                                             |
   +---------------------------------------------------------------------+
   | How sharper than a hound's tooth it is to have a thankless serpent. |
   +---------------------------------------------------------------------+
   1 row in set (0,10 sec)

=over 4

=item DEBUG()

=item BUILD()

=item run()

=back

=head1 AUTHORS

Eriam Schaffter, C<eriam@cpan.org> with original work 
done by Philip Stoev in the DBIx::MyServer module.

=head1 BUGS

None that I know.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



1;

