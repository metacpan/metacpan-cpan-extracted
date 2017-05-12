package Net::CSTA;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::CSTA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';
use IO::Socket::INET;
use Net::CSTA::ASN qw(CSTAapdu);
use Convert::ASN1 qw(:io);

sub new {
   my $self = shift;
   my $class = ref $self || $self;
   my %me = @_;
   my $this = bless \%me,$class;
   $this->init();
}

package Net::CSTA::PDU;
use Net::CSTA::ASN qw(CSTAapdu);
use MIME::Base64;

sub decode {
   my $self = shift;
   my $class = ref $self || $self;
   my $pdu = shift;
   my $this = bless $CSTAapdu->decode($pdu),$class;
   $this->init();
}

sub _hexenc {
  join(":",map { sprintf("%2.2x",$_); } unpack("C*",$_[0]))
}

sub isError {
	my $self = shift;
	defined $self->{typeOfError};
}

sub _b64 {
	my $x = encode_base64($_[0]);
	
	chomp($x);
	$x;
}

sub _safe_copy {
	my $self = shift;
	
	my $copy;
	SWITCH: {
		UNIVERSAL::isa($self,'ARRAY') and do {
			$copy = [];
			foreach (@{$self})
			{
				push(@{$copy},_safe_copy($_));
			}
		},last SWITCH;
			
		UNIVERSAL::isa($self,'HASH') || UNIVERSAL::isa($self,'Net::CSTA::PDU') and do {
			$copy = {};
			foreach (keys %{$self})
			{
				$copy->{$_} = _safe_copy($self->{$_});
			}
		},last SWITCH;
		
		do {
			$copy = $self =~ /^[[:print:]^>^<^^=]*$/ ? $self : _hexenc($self);
		},last SWITCH;
	};
	
	$copy;
}

sub toXML {
	my $pdu = _safe_copy($_[0]);
	use XML::Simple; 
	
	XMLout($pdu,RootName=>'csta');
}

sub init {
	$_[0];
}

package Net::CSTA;

sub init {
   my $self = shift;
   $self->{_csock} = IO::Socket::INET->new(Proto=>'tcp',PeerHost=>$self->{Host},PeerPort=>$self->{Port})
     or die "Unable to connect to CSTA server at $self->{Host}:$self->{Port}: $!\n";
   $self->{_ssock} = IO::Socket::INET->new(Proto=>'udp',LocalHost=>'localhost',LocalPort=>$self->{LocalPort} || 3333)
     or die "Unable to create local UDP port: $!\n"; 
   $self->{_req} = $$;
   $self->{Debug} = 0 unless defined $self->{Debug};
   $self;
}

sub next_request {
   $_[0]->{_req}++;
}

sub this_request {
   $_[0]->{_req};
}

sub debug
{
	$_[0]->{Debug};
}

sub close 
{
   my $self = shift;
   my $sock = shift || $self->{_csock};
   shutdown($sock,2);
   close($sock);
}

sub write_pdu {
   my $self = shift;
   my $pdu = shift;
   my $len = length($pdu);
   my $sock = shift || $self->{_csock};

   if ($self->debug > 1)
   {
   	warn "C ---> S\n";
   	Convert::ASN1::asn_dump(*STDERR, $pdu);
   	Convert::ASN1::asn_hexdump(*STDERR, $pdu) if $self->debug > 2;
   }

   $sock->write(pack "n",$len);
   $sock->write($pdu);
}

sub read_pdu {
   my $self = shift;
   my $timeout = shift || undef;
   my $sock = shift || $self->{_csock};

   my $buf = "";
   
   my ($rin,$win,$ein) = ("","","");
   my ($rout,$wout,$eout) = ("","","");
   
   vec($rin,$sock->fileno,1) = 1;
   $ein = $rin | $win;
   
   my $n = select($rout=$rin,$wout=$win,$eout=$ein,$timeout); 
   return undef unless $n > 0;
 
   eval { 
      local $SIG{ALRM} = sub { die "alarm\n" };
      alarm ($timeout || 30);
      my $nread = $sock->sysread($buf,2);
      my $len = unpack "n",$buf;
      $sock->sysread($buf,$len);
      alarm 0;
   }; if ($@) {
      die unless $@ eq "alarm\n";
      warn "Caught timeout\n";
      return undef;
   }

   if ($self->debug > 1)
   {
  	warn "C <--- S\n";
   	Convert::ASN1::asn_dump(*STDERR, $buf);
   	Convert::ASN1::asn_hexdump(*STDERR, $buf) if $self->debug > 2;
   }
   $buf;
}

sub send_and_receive {
   my $self = shift;

   $self->send(@_);
   $self->receive();
}

sub request {
   my $self = shift;
   my %op = @_;

   $op{invokeID} = $self->next_request;
   $self->send_and_receive(svcRequest=>\%op);
}

sub send {
   my $self = shift;
   my $pdu = $CSTAapdu->encode(@_);

   $self->write_pdu($pdu);
}

sub receive {
   my $self = shift;
   my $pdu = $self->read_pdu(@_);
   return undef unless $pdu;

   Net::CSTA::PDU->decode($pdu);
}

sub recv_pdu {
  my $self = shift;
  my $sock = shift || $self->{_ssock};

  my $buf = "";
  my $nread = $sock->recv($buf,2);
  my $len = unpack "n",$buf;
  $sock->recv_pdu($buf,$len);

  if ($self->debug > 1)
  {
  	warn "C <--- S\n";
  	Convert::ASN1::asn_dump(*STDERR, $buf);
  	Convert::ASN1::asn_hexdump(*STDERR, $buf) if $self->debug > 2;
  }
  
  $buf;
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::CSTA - Perl extension for ECMA CSTA

=head1 SYNOPSIS

  use Net::CSTA;
  
  # Connect to the CSTA server
  my $csta = Net::CSTA->new(Host=>'csta-server',Port=>'csta-server-port');
  # Create a monitor for '555'
  my $number = 555;
  $csta->request(serviceID=>71,
  			     serviceArgs=>{monitorObject=>{device=>{dialingNumber=>$number}}})

  for (;;)
  {
  	 my $pdu = $csta->receive();
  	 print $pdu->toXML();
  }
  
=head1 DESCRIPTION

ECMA CSTA is an ASN.1 based protocol for Computer Integrated Telephony (CTI) using
CSTA it is possible to write code that communicates with a PBX. Typical applications
include receiving notifications for incoming calls, placing calls, redirecting calls
or placing conference calls.

=head1 BUGS

This module currently implements CSTA phase I - mostly because my PBX (MD110 with 
Application Link 4.0) only supports phase I. Supporting multiple versions will 
require some thought since the versions are largly incompatible.

The CSTA client opens a UDP port on 3333 to receive incoming usolicited notifications.
This is not implemented yet.

=head1 SECURITY CONSIDERATIONS

CSTA is a protocol devoid of any form of security. Take care to firewall your CSTA
server and throw away the key.

=head1 SEE ALSO

Convert::ASN1

http://www.ecma-international.org/activities/Communications/TG11/cstaIII.htm


=head1 AUTHOR

Leif Johansson, E<lt>leifj@it.su.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Leif Johansson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
