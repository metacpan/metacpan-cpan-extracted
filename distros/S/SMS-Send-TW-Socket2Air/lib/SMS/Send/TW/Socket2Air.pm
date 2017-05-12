package SMS::Send::TW::Socket2Air;

use strict;
use Carp;
use IO::Socket;
use LWP::UserAgent;
use Switch;
use Text::Iconv;
use base 'SMS::Send::Driver';

use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.01';
}

use constant {
   SENDBUF_SIZE => 266,
   RECVBUF_SIZE => 244,
   TYPE_SERV_CHECK => 0,
   TYPE_SERV_SEND => 1,
   TYPE_SERV_QUERY => 2,
   TYPE_SERV_GET => 3,
   TYPE_SERV_WAP_SEND => 13,
   TYPE_SERV_WAP_QUERY => 14,
   TYPE_SERV_SEND_INTL => 15,
   TYPE_SERV_CANCEL_SEND => 16,
   # Send now
   TRAN_SEND_NOW => '01',
   # Send now and stop sending message at
   TRAN_SEND_NOW_AND_STOP_SEND_AT => '02',
   # Ordered send
   TRAN_SEND_ORDER => '03',
   # Ordered send and stop sending message at
   TRAN_SEND_ORDER_AND_STOP_SEND_AT => '04',
   # Uncodumented coding
   CODING_ASCII => 0,
   CODING_BIG5 => 1,
   CODING_BINARY => 2,
   CODING_UCS2 => 3,
   CODING_UTF8 => 4,
   SMS_SERVER_IP => '202.39.54.130',
   SMS_SERVER_PORT => '8000',
};

# Preloaded methods go here.

sub new {
   my ($class, %params) = @_;
   my $agent;
   my $conn;

   foreach(qw/username password/) {
      Carp::croak("No $_ specified") unless(defined $params{"_$_"});
   }
   $params{'host_ip'} =  $params{'_host_ip'} || SMS_SERVER_IP;
   $params{'host_port'} = $params{'_host_port'} || SMS_SERVER_PORT;
   $params{'proxy_host'} = $params{'_proxy_host'} if (defined($params{'_proxy_host'}));
   $params{'proxy_port'} = $params{'_proxy_port'} if (defined($params{'_proxy_port'}));
   $params{'proxy_type'} = $params{'_proxy_type'} if (defined($params{'_proxy_type'}));

   if (defined($params{'proxy_type'})) {
       foreach(qw/proxy_host proxy_port/) {
	   Carp::croak("No $_ specified") unless(defined $params{"$_"});
       }
       switch($params{'proxy_type'}) {
	   case 'http' {
	       $agent = LWP::UserAgent->new(keep_alive => 1);
	       $agent->proxy(
		       http => "http://" . $params{'proxy_host'}. ':' . $params{'proxy_port'} . "/");
	       my $req = HTTP::Request->new(
		       CONNECT => "http://" . $params{'host_ip'} . ':' . $params{'host_port'}. "/");
	       my $res = $agent->request($req);

	       Carp::croak($res->status_line()) unless $res->is_success();
	       $conn = $res->{client_socket};
	   }
       }
   } else {
       $conn = IO::Socket::INET->new($params{'host_ip'} . ':' . $params{'host_port'});

       Carp::croak('Not able to connect to CHT Socket2Air Server') unless $conn->connected;
   }

   $params{'conn'} = $conn;
   $params{'agent'} = $agent if (defined($agent));
   $params{'auth'} = 0;

   my $self = bless { %params }, $class;

   return $self;
}

sub _send_packet {
   my $self   = shift;
   my %params = @_;

   my $send_buf = '';
   my $tmp;
   my $zero_buf = "\0"x266;   

   my $conn = $self->{'conn'};

   foreach (qw/msg_type/) {
      Carp::croak("No $_ specified") unless(defined $params{"$_"});
   }

   foreach (qw/msg_coding msg_priority msg_country_code msg_set_len msg_content_len/) {
      $params{"_$_"} = 0 unless (defined $params{"$_"});	    
   }

   foreach (qw/msg_set msg_content/) { 
      $params{"_$_"} = '' unless (defined $params{"$_"});	   
   }

   $send_buf = pack("CCCCCCa100a160", 
		   $params{'msg_type'},
		   $params{'msg_coding'},
		   $params{'msg_priority'},
		   $params{'msg_country_code'},
		   $params{'msg_set_len'},
		   $params{'msg_content_len'},
		   $params{'msg_set'},
		   $params{'msg_content'}
		   );

   # Fill 0...
   $send_buf = pack("a" . SENDBUF_SIZE, $send_buf);

   # Send to server 
   $conn->syswrite($send_buf, SENDBUF_SIZE);
}

sub _recv_packet {
   my $self   = shift;

   my $recv_buf = '';
   my $tmp;
   my %ret;

   my $conn = $self->{'conn'};

   $conn->sysread($recv_buf, RECVBUF_SIZE);

   # unpack
   ($ret{'ret_code'}, $ret{'ret_coding'}, 
    $ret{'ret_set_len'}, $ret{'ret_content_len'},
    $ret{'ret_set'}, $ret{'ret_content'}) = unpack("cccca80a160", $recv_buf);

   # Convert Message to UTF-8 
   my $from_code;
   switch($ret{'ret_coding'}) {
      case CODING_BIG5		{ $from_code = 'big5'; }
      case CODING_UCS2		{ $from_code = 'ucs-2'; }
      # UTF8 or ASCII
      else			{ $ret{'msg'} = $ret{'ret_content'}; }
   }
   if (defined($from_code)) {
      my $converter = Text::Iconv->new($from_code, "utf-8");
      $ret{'msg'} = $converter->convert($ret{'ret_content'});
   }
 
   return %ret;
}

sub send_sms {
   my $self   = shift;
   my %params = @_;

   my %ret;

   # Get the message and destination
   my $message   = $self->_MESSAGE( $params{text} );
   my $recipient = $self->_TO( delete $params{to} );
   my $conn = $self->{'conn'};
   my $msg_set;

   # Login
   if (not $self->{'auth'}) {
      $msg_set = $self->{'_username'} . "\0" . $self->{'_password'} . "\0"; 
      $self->_send_packet(
		      'msg_type' => TYPE_SERV_CHECK, 
		      'msg_set' => $msg_set,
		      'msg_set_len' => length($msg_set)
		      );	   
      %ret = $self->_recv_packet();
      Carp::croak($ret{'ret_content'}) unless(0 == $ret{'ret_code'});
      $self->{'auth'} = 1;
   }

   $msg_set = $recipient . "\0" . TRAN_SEND_NOW . "\0";
   $self->_send_packet(
		   'msg_type' => TYPE_SERV_SEND, 
		   'msg_coding' => CODING_UCS2, 
		   'msg_set' => $msg_set,
		   'msg_set_len' => length($msg_set),
		   'msg_content' => $message,
		   'msg_content_len' => length($message)
		   );
   %ret = $self->_recv_packet();

   return %ret;
}

sub _MESSAGE {

  my $class = ref $_[0] ? ref shift : shift;
  my $message = shift;
  my $converter = Text::Iconv->new("utf-8", "ucs-2");
  unless ( length($message) <= 160 ) {
    Carp::croak("Message length limit is 160 characters");
  }
  
  return $converter->convert($message);
}

sub _TO {
  my $class = ref $_[0] ? ref shift : shift;
  my $to = shift;

  # International numbers need their + removed
  $to =~ y/0123456789//cd;

  return $to;
}
1;
=head1 NAME

SMS::Send::TW::Socket2Air - SMS::Send driver for HiNet Socket2Air 

=head1 SYNOPSIS

use SMS::send;

my $sender = SMS::Send->new('TW::Socket2Air',
	_username   => 'UserName',
	_password   => 'Password',
	_proxy_host => 'proxy.to.specified',
	_proxy_port => 3128,
	_proxy_type => 'http',
	);

my $sent = $sender->send_sms(
	text => 'My very urgent message',
	to   => '0912345678',
	);

=head1 DESCRIPTION

SMS::Send::TW::Socket2Air is a SMS::Send driver which allows you to send messages through L<http://sms.hinet.net/new/>.

=head1 METHODS

=head2 new

The C<new> method takes a few parameters. C<_username> and C<_password> >
are mandatory. 

=head2 send_sms

Takes C<to> as recipient phonenumber, and C<text> as the utf-8 encoded text
that's supposed to be delivered.

=head1 SEE ALSO

=over 5

=item * L<Send::SMS>

=item * L<IO::Socket>

=item * L<LWP::UserAgent>

=head1 AUTHOR

Jui-Nan Lin, E<lt>jnlin@csie.nctu.edu.twE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Jui-Nan Lin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
