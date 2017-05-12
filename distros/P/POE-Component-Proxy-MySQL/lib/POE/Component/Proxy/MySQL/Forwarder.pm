package     # ignore CPAN ..
   POE::Component::Proxy::MySQL::Forwarder;
use Moose;
use MooseX::MethodAttributes ();

use strict;    # for kwalitee
use warnings;  # for kwalitee

use Socket;
use POSIX qw(errno_h);
use POE qw( 
   Wheel::ReadWrite 
   Wheel::SocketFactory 
   Filter::Stream 
);
use MySQL::Packet qw(
   :encode 
   :decode 
   :COM 
   :CLIENT 
   :SERVER 
   :debug
);
use Module::Find;
use Data::Dumper;

my $VERSION = '0.01_01';

has 'namespace'               => (is => 'rw', isa => 'Str');
has 'packet_count'            => (is => 'rw', isa => 'Int');

has 'client_wheel'            => (is => 'rw', isa => 'Any');
has 'server_wheel'            => (is => 'rw', isa => 'Any');

has 'server_heap'             => (is => 'rw', isa => 'Any');

has 'heap'                    => (is => 'rw', isa => 'Any');

has 'client_input_data'       => (is => 'rw', isa => 'Any');
has 'server_input_data'       => (is => 'rw', isa => 'Any');

has 'server_request_callback' => (is => 'rw', isa => 'Str');

my @dispatchers;

my $max_connections_per_child = 256;

sub BUILD {
   my ($self, $opt) = @_;


   $self->server_heap($opt->{heap});
   
   my $server_heap = $self->server_heap;
   $server_heap->{active_connections}->{$$}++;
   $server_heap->{connections_per_child}->{$$}++;
   
   POE::Session->create(
      object_states => [
         $self =>  { 
            _start         => '_forwarder_start',
            _stop          => '_forwarder_stop',
            client_input   => '_forwarder_client_input',
            client_error   => '_forwarder_client_error',
            server_connect => '_forwarder_server_connect',
            server_input   => '_forwarder_server_input',
            server_error   => '_forwarder_server_error',
            dispatch_input => '_dispatch_input',  
         },
      ],
      args => [$opt->{socket}, $opt->{peer_addr}, $opt->{peer_port}, $opt->{remote_addr}, $opt->{remote_port}, $opt->{heap}]
   );

}


sub _forwarder_start {
  my ($self, $heap, $session, $socket, $peer_host, $peer_port, $remote_addr,
    $remote_port)
    = @_[OBJECT, HEAP, SESSION, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5];
   
   $heap->{log}                  = $session->ID;
   $peer_host                    = inet_ntoa($peer_host);
   $heap->{peer_host}            = $peer_host;
   $heap->{peer_port}            = $peer_port;
   $heap->{remote_addr}          = $remote_addr;
   $heap->{remote_port}          = $remote_port;
   
   $self->heap($heap);

   my @modules = findsubmod($self->namespace);
   
   foreach my $module (@modules) {
      next unless $module;

      eval('use '.$module); # to be replaced some day
         die $@ if $@;
         
      foreach my $method ($module->meta->get_method_list) {
         next unless $module->meta->get_method($method);
       
         my $module_prefix = $module;
         $module_prefix =~ s/::/_/g;

         
         ref($self)->meta->add_method(
            $module_prefix."_".$method,
            $module->meta->get_method($method)
         );
         
      }

      $module->meta->apply( $self->meta );

      foreach my $method ($module->meta->get_method_list) {
         next unless $module->meta->get_method($method);
         
         my $attrs;
         
         eval {
            $attrs = $module->meta->get_method($method)->attributes;
         };
         
         next if $@;
         
         my $module_prefix = $module;
         $module_prefix =~ s/::/_/g;
         
         $_[KERNEL]->state( $module_prefix."_".$method, $self );
                  
         foreach my $attr (@{$attrs}) {
            
            if ($attr =~ /Regexp\(('|")(.*)('|")\)/io) { # "
               my $eval_str = 'push @dispatchers, {
                  regexp   => '.$2.',
                  method   => $method,
                  class    => $module,
               };';                        
               eval($eval_str);
            }
            elsif ($attr =~ /Match\(('|")(.*)('|")\)/io) { # "
               push @dispatchers, {
                  match    => $2,
                  method   => $method,
                  class    => $module,
               };
            }
            
         }
         
      }  
      
   }
   
   $heap->{state} = 'connecting';
   $heap->{queue} = [];
   
   $heap->{driver} = POE::Driver::SysRW->new;
   $heap->{filter} = POE::Filter::Stream->new;

   $heap->{client_wheel} = POE::Wheel::ReadWrite->new(
      Handle     => $socket,
      Driver     => $heap->{driver},
      Filter     => $heap->{filter},
      InputEvent => 'client_input',
      ErrorEvent => 'client_error',
   );
   
   $heap->{server_wheel} = POE::Wheel::SocketFactory->new(
      RemoteAddress => $remote_addr,
      RemotePort    => $remote_port,
      SuccessEvent  => 'server_connect',
      FailureEvent  => 'server_error',
   );

   my $server_heap = $self->server_heap;
   
   $self->client_wheel($heap->{client_wheel});
   $self->server_wheel($heap->{server_wheel});
   
}

sub _forwarder_stop {
   my $heap = $_[HEAP];
  
   $heap->{server_heap}->{active_connections}->{$$}--;
}

sub _forwarder_client_input {
   my ($self, $heap, $session, $kernel, $input) = 
      @_[OBJECT, HEAP, SESSION, KERNEL, ARG0];

   $self->client_input_data($input);
         
   if ($heap->{state} eq 'connecting') {
      push @{$heap->{queue}}, $input;
   }
   else {
      
      $self->packet_count(unpack('C', substr($input, 3, 1))); 
      
      my $command = unpack('C', substr($input, 4, 1)); 
   
      if ($command == COM_QUERY) {
         
         my $query  = $input;
         $query = substr($query, 5);
         chomp($query);
      
         my $event;
         my @placeholders;
         my $dispatcher;
                  
         foreach my $tmp_dispatcher (@dispatchers) {
            if (ref($tmp_dispatcher->{regexp}) eq 'Regexp') {
               if (@placeholders = $query =~ $tmp_dispatcher->{regexp}) {
                  $dispatcher = $tmp_dispatcher;
                  last;
               }
            }
            elsif (exists($tmp_dispatcher->{match})) {
               if ($query eq $tmp_dispatcher->{match}) {
                  $dispatcher = $tmp_dispatcher;
                  last;
               }
            }
         }
         
         if ($dispatcher->{class} && $dispatcher->{method}) {

            my $specific_method = $dispatcher->{class};
            $specific_method =~ s/::/_/g;
            $specific_method = $specific_method.'_'.$dispatcher->{method};
            
            $self->packet_count($self->packet_count + 1);
            $kernel->call($_[SESSION], $specific_method, $query, \@placeholders);
                        
            print $@ if $@;
            
         }
         else {
            $self->release_client;
         }
         
      }
      else {
         $self->release_client;
      }
   }
}


sub _forwarder_client_error {
  my ($self, $kernel, $heap, $operation, $errnum, $errstr) =
    @_[OBJECT, KERNEL, HEAP, ARG0, ARG1, ARG2];

   my $server_heap = $self->server_heap;
   $server_heap->{active_connections}->{$$}--;   

  delete $heap->{client_wheel};
  delete $heap->{server_wheel};

  $self->client_wheel(undef);
  $self->server_wheel(undef);

}

sub _forwarder_server_connect {
   my ($self, $kernel, $session, $heap, $socket) 
      = @_[OBJECT, KERNEL, SESSION, HEAP, ARG0];
   
   my ($local_port, $local_addr) = unpack_sockaddr_in(getsockname($socket));
   $local_addr = inet_ntoa($local_addr);
   
   $heap->{server_wheel} = POE::Wheel::ReadWrite->new(
      Handle     => $socket,
      Driver     => POE::Driver::SysRW->new( BlockSize => 4096 ),
      Filter     => POE::Filter::Stream->new,
      InputEvent => 'server_input',
      ErrorEvent => 'server_error',
   );
   
   $self->server_wheel($heap->{server_wheel});
   
   $heap->{state} = 'connected';
   
   foreach my $pending (@{$heap->{queue}}) {
      $kernel->call($session, 'client_input', $pending);
   }
   $heap->{queue} = [];
}

sub _forwarder_server_input {
   my ($self, $heap, $input) = @_[OBJECT, HEAP, ARG0];

   $self->server_input_data($input);
   
   $self->release_server;

}

sub _forwarder_server_error {
  my ($kernel, $heap, $operation, $errnum, $errstr) =
    @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

  delete $heap->{client_wheel};
  delete $heap->{server_wheel};
}

sub _server_send_query {
   my ($self, $opt) = (@_);
   
   my $wheel = $self->server_wheel;
         
   unless (exists($opt->{callback})) {
     $opt->{callback} = '';
   }
   else {
      my ($package, $filename, $line) = caller;
      
      $package =~ s/::/_/g;
      $opt->{callback} = $package.'_'.$opt->{callback};
   }
   
   my $heap = $self->heap;
   
   $heap->{server_request_callback} = $opt->{callback};

   if ($opt->{callback} ne '') {
      $wheel->event(InputEvent => 'dispatch_input');
   }
   else {
      $wheel->event(InputEvent => 'server_input');
   }
   
   my $packet_body = mysql_encode_com_query($opt->{query});
   my $packet_head = mysql_encode_header($packet_body);
   $wheel->put($packet_head.$packet_body);
   
}

sub _dispatch_input {
   my ($self, $heap, $session, $kernel, $input) = 
      @_[OBJECT, HEAP, SESSION, KERNEL, ARG0];
   
   my (@resultset, $result);
   
   if (length($input) == 4096) {
      
      (@resultset, $result) = $self->read_resultset($self->server_input_data.$input);
      
      if ($result->{'field_count'}) {
         # OK
         
         $heap->{'input'} = $input;
         
         my $query;
         
         my $wheel = $self->server_wheel;
         $wheel->event(InputEvent => 'server_input');
            
         if ($heap->{server_request_callback}) {
            if (ref($heap->{server_request_callback}) eq 'CODE') {
               my $code = $heap->{server_request_callback};
               &$code;
            }
            else {
               $kernel->call($session, $heap->{server_request_callback}, \@resultset, $result, $input);
            }
         }         
         
         $self->server_input_data('');
         
      }
      else {
         $self->server_input_data($self->server_input_data.$input);
      }
      
   }
   else {
      
      (@resultset, $result) = $self->read_resultset($self->server_input_data.$input);
      
      $heap->{'input'} = $input;
      
      my $query;
      
      my $wheel = $self->server_wheel;
      $wheel->event(InputEvent => 'server_input');
         
      if ($heap->{server_request_callback}) {
         if (ref($heap->{server_request_callback}) eq 'CODE') {
            my $code = $heap->{server_request_callback};
            &$code;
         }
         else {
            $kernel->call($session, $heap->{server_request_callback}, \@resultset, $result, $input);
         }
      }
      
      $self->server_input_data('');
            
   }



}


sub _read_resultset {
   my ($self, $input) = (@_);
   
   my $rc;
   my $packet;
      
   my $field_count;   
   my @headers;
   my @resultset;
   
   no warnings;
   
   $rc = mysql_decode_header($packet, $input);
      
   if ($rc > 0) {
      $input = substr($input, 4);
      $rc = mysql_decode_result($packet, $input);
      if ($rc > 0) {         
         if ($packet->{field_count}) {
            
            $field_count = $packet->{field_count};
            
            $input = substr($input, $packet->{packet_size});
            
            for (my $i = 1; $i <= $field_count; $i++) {
               
               $packet = ();
               $rc = mysql_decode_header($packet, $input);
               if ($rc > 0) {
                  $input = substr($input, 4);
                  $rc = mysql_decode_field($packet, $input);
                  if ($rc > 0) {
                     push @headers, $packet->{name};
                     $input = substr($input, $packet->{packet_size});
                  }
               }
            }
            
            push @resultset, \@headers;
            
            $input = substr($input, 9);
       
            while (length($input) > 4) {
               
               $packet = ();
               
               $rc = mysql_decode_header($packet, $input);
               
               $input = substr($input, 4);
               
               last if mysql_test_end($packet, $input);
               
               $rc = mysql_decode_row($packet, $input);
               
               if ($rc > 0) {
                  
                  if ($packet->{'end'}) {
                     last;
                  }
                  else {
                     $input = substr($input, $packet->{packet_size});
                     
                     push @resultset, $packet->{row};
                     
                  }
               }
            }
            
            
         }
         elsif ($packet->{error}) {
            print "mysql_decode_result error\n";
            print Dumper($packet);
            $self->client_send_error($packet->{message});
         }
         else {
            return (@resultset, $packet);
         }
      }
   }  
   else {
      return (@resultset, $packet);
   } 
   
   return (@resultset, {
      field_count => $field_count,
   });
}



sub client_send_ok {
   my ($self, $message, $affected_rows, $insert_id, $printing_count) = @_;
   
   my $data;
   
   $affected_rows    = 0 unless defined $affected_rows;
   $printing_count   = 0 unless defined $printing_count;
   
   $data .= "\0";
   $data .= _length_coded_binary($affected_rows);
   $data .= _length_coded_binary($insert_id);
   $data .= pack('v', SERVER_STATUS_AUTOCOMMIT);
   $data .= pack('v', $printing_count);
   $data .= _length_coded_string($message);
   
   return $self->_write_to_client( $data, 1);
}

sub _add_header {
   my ($self, $message, $reinit) = @_;
   
   my $header;
   $header .= substr(pack('V',length($message)),0,3);
   $header .= chr($self->packet_count % 256);
   
   if ($reinit) {
      $self->packet_count(0);
   }
   else {
      $self->packet_count($self->packet_count + 1);
   }
   
   return $header.$message;
}

sub release_client {
   my ($self) = @_;
   
   $self->_release($self->server_wheel, $self->client_input_data);
   $self->client_input_data('');
}

sub release_server {
   my ($self) = @_;

   $self->_release($self->client_wheel, $self->server_input_data);
   $self->server_input_data('');
   
}

sub _release {
   my ($self, $wheel, $data) = @_;
   
   defined($wheel) and $wheel->put($data);
}


sub _write_to_client {
   my ($self, $message, $reinit) = @_;

   $message = $self->_add_header($message, $reinit);
   
   $self->client_wheel->put($message);
   
   return $message;
}

sub _length_coded_string {
	my ($string) = @_;
	return chr(0) if (not defined $string or $string eq '');
	return _length_coded_binary(length($string)).$string;
}

sub _length_coded_binary {
	my ($number) = @_;
	
	if (not defined $number) {
		return chr(251);
	}
    elsif ($number < 251) {
		return chr($number);
	}
    elsif ($number < 0x10000) {
		return chr(252).pack('v', $number);
	}
    elsif ($number < 0x1000000) {
		return chr(253).substr(pack('V', $number), 0, 3);
	}
    else {
		return chr(254).pack('V', $number >> 32).pack('V', $number & 0xffffffff);
	}
}

sub _send_eof {
    my ($self, $warning_count, $server_status, $reinit) = @_;

	my $payload;

	$server_status =  SERVER_STATUS_AUTOCOMMIT |
	                  SERVER_QUERY_NO_INDEX_USED if not defined $server_status;

   $warning_count = 0 if !defined $warning_count;

	$payload .= chr(0xfe);
	$payload .= pack('v', $warning_count) if defined $warning_count;
	$payload .= pack('v', $server_status) if defined $server_status;

   return $self->_write_to_client( $payload, $reinit);
}


sub client_send_results {
   my ($self, $definitions, $data, $opt) = @_;

   unless (ref($data) eq 'ARRAY') {
      $self->client_send_error('Internal error');
      return;
   }
   $self->_send_header_packet(scalar(@{$definitions}), scalar(@{$data}));
   $self->_send_definitions($definitions, $opt);
   $self->_send_eof();
   $self->_send_rows($data);
   $self->_send_eof(undef,undef,1);
}



sub client_send_error {
   my ($self, $message, $errno, $sqlstate) = @_;
   
   $message = 'Unknown MySQL error' if not defined $message;
   $errno = 2000 if not defined $errno;
   $sqlstate = 'HY000' if not defined $sqlstate;
   
   my $payload = chr(0xff);
   $payload .= pack('v', $errno);
   $payload .= '#';
   $payload .= $sqlstate;
   $payload .= $message."\0";
   
   return $self->_write_to_client( $payload, 1);
}

sub _send_header_packet {
   my ($self, $n_fields, $n_rows) = @_;

   my $packet = _length_coded_binary($n_fields);

   $self->_write_to_client($packet);   
}

sub _send_definitions {
   my ($self, $definitions, $skip_envelope) = @_;

	my $last_send_result;
	
   foreach my $definition (@{$definitions}) {
      $definition = { 
         name  => $definition,
         type  => 15,
      } unless ref($definition) eq 'HASH';
      $self->_send_definition($definition);
   }

}

sub _send_definition {
   my ($self, $definition) = @_;

   no warnings;

	my $payload = join('', map { _length_coded_string($_) } (
		$definition->{catalog}, 
		$definition->{db}, 
		$definition->{table},
		$definition->{org_table}, 
		$definition->{name}, 
		$definition->{org_name}
	));
   
   $payload .= chr(0x0c);
   $payload .= pack('v', 11);
   $payload .= pack('V', $definition->{length});
   $payload .= chr($definition->{type});
   $payload .= defined $definition->{flags} ? pack('v', $definition->{flags}) : pack('v', 0);
   $payload .= defined $definition->{decimals} ? chr($definition->{decimals}) : pack('v', 0);
   $payload .= pack('v', 0);

   $self->_write_to_client($payload);
}


sub _send_rows {
   my ($self, $rows, $opt) = @_;

	foreach my $row (@$rows) {

        my $small_data;
        if (ref($row) eq 'ARRAY') {
            foreach (@$row) {
                if (not defined $_) {
                    $small_data .= chr(251);
                }
                else {
                    $small_data .= _length_coded_string($_);
                }
            }
        }
        elsif (ref($row) eq 'HASH') {
            foreach (values %{ $row }) {
                if (not defined $_) {
                    $small_data .= chr(251);
                }
                else {
                    $small_data .= _length_coded_string($_);
                }
            }
        }

        if (defined $small_data) {
            $self->_write_to_client($small_data);
        }
	}
	
}


1;
