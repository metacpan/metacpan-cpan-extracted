package POE::Component::Server::MySQL;
use Moose;
use MooseX::MethodAttributes;

our $VERSION = "0.02";

use POE;
use POE::Kernel;
use POE qw(Component::Server::TCP);
use POE::Filter::Block;


use Socket qw(INADDR_ANY inet_ntoa inet_aton AF_INET AF_UNIX PF_UNIX);
use Errno qw(ECONNABORTED ECONNRESET);

use Carp qw( croak );
use Class::Inspector;

use Module::Find;
use Data::Dumper;

use Time::HiRes qw(gettimeofday tv_interval);

use POE::Component::Server::MySQL::Client;

has 'address'  => (is => 'rw', isa => 'Str');
has 'port'     => (is => 'rw', isa => 'Int');

has 'local_dsn' => (is => 'rw', isa => 'Str');
has 'local_user' => (is => 'rw', isa => 'Str');
has 'local_password' => (is => 'rw', isa => 'Str');

has 'listener' => (is => 'rw', isa => 'Any');
has 'session' => (is => 'rw', isa => 'Any');

sub DEBUG {1}

sub BUILD {
	my ($self, $opt) = @_;
   
   POE::Session->create(
     object_states => [
         $self =>  { 
            _start         => '_server_start',
            _stop          => '_server_stop',
            _socket_birth  => '_socket_birth',
            _socket_death  => '_socket_death',    
         }
     ],  
      inline_states => {
         _do_fork        => \&_do_fork,
      },
   );

   return $self;
}

sub _server_start {
   my ( $self, $kernel, $session, $heap ) = @_[ OBJECT, KERNEL, SESSION, HEAP];
   
   $self->port(23306) unless $self->port;
   $self->address('127.0.0.1') unless $self->address;
   
   print "Ready to accept clients in namespace ".ref($self)." on ".$self->address.":".$self->port." \n";
   
   $heap->{children}       = {};
   $heap->{is_a_child}     = 0;
   $heap->{max_processes}  = 5;
   
   $self->listener(POE::Wheel::SocketFactory->new(
      BindAddress  => $self->address,
      BindPort     => $self->port,
      Reuse        => 'yes',
      SuccessEvent => '_socket_birth',
      FailureEvent => '_socket_death',
   ));

   $kernel->yield('_do_fork');
}

sub _server_stop {
   my ( $self, $kernel, $session, $heap ) = @_[ OBJECT, KERNEL, SESSION, HEAP];
   print "Stop server \n";
   $self->listener(undef);
   $self->session(undef);

}

sub _do_fork {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  return if $heap->{is_a_child};

  while (scalar(keys %{$heap->{children}}) < $heap->{max_processes}) {
    my $pid = fork();

    unless (defined($pid)) {
      $kernel->delay(do_fork => 1);
      return;
    }

    if ($pid) {
      print "Server $$ forked child $pid\n";
      $heap->{children}->{$pid} = 1;
      $kernel->sig_child($pid, "got_sig_child");
      next;
    }

    $kernel->has_forked();
    $heap->{is_a_child} = 1;
    $heap->{children}   = {};
    return;
  }
}


sub _socket_birth {
   my ( $self, $kernel, $session, $heap ) = @_[ OBJECT, KERNEL, SESSION, HEAP];
   my ($socket, $address, $port) = @_[ARG0, ARG1, ARG2];
   $address = inet_ntoa($address);

   my $client = POE::Component::Server::MySQL::Client->new({
      server_class   => ref($self),
   });
   
   print '$self->local_dsn = '.$self->local_dsn."\n";
   
   $client->local_dsn($self->local_dsn);
   $client->local_user($self->local_user);
   $client->local_password($self->local_password);
   
   POE::Session->create(
      object_states => [
         $client =>  { 
            client_input         => 'client_input',
            client_error         => 'client_error',
            shutdown             => 'shutdown',
            client_connect       => 'client_connect',
         }
      ],
      inline_states => {
         _start => sub {
            my ( $kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP];
   
            $heap->{client} = POE::Wheel::ReadWrite->new(
               Handle       => $socket,
               Driver       => POE::Driver::SysRW->new(),
               Filter       => POE::Filter::Block->new(
                  LengthCodec => [ \&_length_encoder, \&_length_decoder ]
               ),
               InputEvent   => 'client_input',
               ErrorEvent   => 'client_error',
            );
            
            $client->wheel($heap->{client});
            $client->session_id($session->ID);
            $client->session($session);

             # register system states
             my @methods = Class::Inspector->methods(
                 'POE::Component::Server::MySQL::Client',
                 'expanded',
                 'public'
             );

             foreach my $method (@{ $methods[0] }) {
                 my ($full, $class, $method, undef ) = @{ $method };
                 next if $method =~ /^send_/
                         or $method eq 'write'
                         or $method eq 'new_definition';
                 if ($class eq 'POE::Component::Server::MySQL::Client') {
                     $session->_register_state($method, $client);
                 }
             }       
         
            my @dispatchers;
         
            my @modules = findsubmod(ref($self));
            
            foreach my $module (@modules) {
               next unless $module;
               
               unless (Class::Inspector->loaded($module)) {
                  require Class::Inspector->filename($module);
               }
               
               my @methods = Class::Inspector->methods($module, 'expanded', 'public');
               
               foreach my $method (@{ $methods[0] }) {
                  my ($full, $class, $method, undef ) = @{ $method };
                  next unless $module->meta->get_method($method);
                   
                  my $attrs;
                  
                  eval {
                     $attrs = $module->meta->get_method($method)->attributes;
                  };
                  
                  next if $@;
                           
                  foreach my $attr (@{$attrs}) {
                     
                     if ($attr =~ /Regexp\(('|")(.*)('|")\)/io) { #"
                        my $eval_str = 'push @dispatchers, {
                           regexp   => '.$2.',
                           method   => $method,
                        };';                        
                        eval($eval_str);
                     }
                     elsif ($attr =~ /Match\(('|")(.*)('|")\)/io) { #"
                        push @dispatchers, {
                           match   => $2,
                           method   => $method,
                        };
                     }
                     elsif ($attr =~ /Default/io) {
                        $client->default({
                           default  => 1,
                           method   => $method,
                        });
                     }
                     
                     Moose::Util::apply_all_roles(ref($client), ($module));
                     $client->session->_register_state($method, $client);
                     
                  }
                  
               }
            
            }

            $client->dispatchers(\@dispatchers);   
             
            $kernel->yield('client_connect');
         },
         _child  => sub { },
      },
   );   

}

sub _socket_death {
   my ( $self, $kernel, $session, $heap ) = @_[ OBJECT, KERNEL, SESSION, HEAP];
   print "_socket_death \n";
}

sub run {
   POE::Kernel->run();
}

sub _length_encoder { 
   return; 

}

sub _length_decoder {
   my $stuff = shift;

   if (length($$stuff) > 1) {
      return length($$stuff);
   }
   else {
      return 1;
   }
}

=head1 NAME

POE::Component::Server::MySQL - A MySQL POE Server

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

   package MyMySQL::OnSteroids;
   use MooseX::MethodAttributes::Role;
   
   sub fortune : Regexp('qr{fortune}io') {
      my ($self) = @_;
      
   	my $fortune = `fortune`;
   	chomp($fortune);
   
      $self->send_results(['fortune'],[[$fortune]]);
   
   }

=head1 AUTHORS

Eriam Schaffter, C<eriam@cpan.org> with original work 
done by Philip Stoev in the DBIx::MyServer module.

=head1 BUGS

At least one, in specific cases the servers sends several 
packets instead of a single one. It works fine with most clients
but it crashes Toad for MySQL for example.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



1;

