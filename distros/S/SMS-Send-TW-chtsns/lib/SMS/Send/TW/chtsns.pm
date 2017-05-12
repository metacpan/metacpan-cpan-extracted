package SMS::Send::TW::chtsns;

use strict;
use Carp;
use IO::Socket;
use LWP::UserAgent;
use Switch;
use Text::Iconv;
use base 'SMS::Send::Driver';

use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.03';
}

use constant {
   SENDBUF_SIZE => 217,
   RECVBUF_SIZE => 189,
   TYPE_SERV_CHECK => 0,
   TYPE_SERV_EDIT_PASSWD => 1,
   TYPE_SERV_SEND => 2,
   TYPE_SERV_QUERY => 3,
   TYPE_SERV_GET => 4,
   TYPE_SERV_SEND_WITH_UDHI => 6,
   TRAN_SEND_NOW => 100,
   TRAN_SEND_ORDER => 101,
   # Uncodumented coding
   CODING_ASCII => 0x00,
   CODING_BIG5 => 0x01,
   CODING_BINARY => 0xf5,
   CODING_UNICODE => 0x08,
   SMS_SERVER_IP => '203.66.172.133',
   SMS_SERVER_PORT => '8001',
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

       Carp::croak('Not able to connect to CHT SMS Server') unless $conn->connected;
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
   my $zero_buf = "\0"x230;   

   my $conn = $self->{'conn'};

   foreach (qw/type/) {
      Carp::croak("No $_ specified") unless(defined $params{"$_"});
   }

   foreach (qw/coding length tran_type/) {
      $params{"_$_"} = 0 unless (defined $params{"$_"});	    
   }

   foreach (qw/pchID pchPasswd pchMsisdn pchMessageID pchMessage pchSendTime/) { 
      $params{"_$_"} = '' unless (defined $params{"$_"});	   
   }

   $send_buf = pack("CCCCZ9Z9Z13Z9a160Z13", 
		   $params{'type'},
		   $params{'coding'},
		   $params{'length'},
		   $params{'tran_type'},
		   $params{'pchID'},
		   $params{'pchPasswd'},
		   $params{'pchMsisdn'},
		   $params{'pchMessageID'},
		   $params{'pchMessage'},
		   $params{'pchSendTime'}
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
   ($ret{'code'}, $ret{'coding'}, $ret{'length'}, $ret{'send_msisdn'}, $ret{'recv_msisdn'},
    $ret{'buffer'}) = unpack("cccZ13Z13a160", $recv_buf);

   # Convert Message to UTF-8 
   my $from_code;
   switch($ret{'coding'}) {
      case CODING_ASCII		{ $ret{'msg'} = $ret{'buffer'}; }
      case CODING_BIG5		{ $from_code = 'big5'; }
      case CODING_UNICODE	{ $from_code = 'ucs-2'; }
   }
   if (defined($from_code)) {
      my $converter = Text::Iconv->new($from_code, "utf-8");
      $ret{'msg'} = $converter->convert($ret{'buffer'});
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

   # Login
   if (not $self->{'auth'}) {
      $self->_send_packet(
		      'type' => TYPE_SERV_CHECK, 
		      'pchID' => $self->{'_username'}, 
		      'pchPasswd' => $self->{'_password'}
		      );	   
      %ret = $self->_recv_packet();
      Carp::croak($ret{'buffer'}) unless(0 == $ret{'code'});
      $self->{'auth'} = 1;
   }

   $self->_send_packet(
		   'type' => TYPE_SERV_SEND, 
		   'coding' => CODING_UNICODE, 
		   'pchMsisdn' => $recipient, 
		   'pchMessage' => $message, 
		   'length' => length($message), 
		   'tran_type' => TRAN_SEND_NOW
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

SMS::Send::TW::chtsns - SMS::Send driver for SNS Service of CHT

=head1 SYNOPSIS

use SMS::send;

my $sender = SMS::Send->new('TW::chtsns',
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

SMS::Send::TW::chtsns is a SMS::Send driver which allows you to send messages through L<http://203.66.172.129/sns/sns_help.htm/>.

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
