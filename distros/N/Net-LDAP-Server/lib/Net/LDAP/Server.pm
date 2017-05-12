# ===========================================================================
# Net::LDAP::Server
# 
# LDAP server side protocol handling
# 
# Alessandro Ranellucci <aar@cpan.org>
# Hans Klunder <hans.klunder@bigfoot.com>
# Copyright (c) 2005-2007.
# 
# See below for documentation.
# 
package Net::LDAP::Server;
use strict;
use warnings;

use Convert::ASN1 qw(asn_read);
use Net::LDAP::ASN qw(LDAPRequest LDAPResponse);
use Net::LDAP::Constant qw(LDAP_OPERATIONS_ERROR LDAP_UNWILLING_TO_PERFORM);
use Net::LDAP::Entry;
use Data::Dumper;

our $VERSION = '0.43';
use fields qw(in out);

our %respTypes=(
	'bindRequest' => 'bindResponse', 
	'unbindRequest' => '',
	'searchRequest' => 'searchResDone',
	'modifyRequest' => 'modifyResponse', 
	'addRequest'  => 'addResponse', 
	'delRequest' => 'delResponse',
	'modDNRequest' => 'modDNResponse',
	'compareRequest' => 'compareResponse',
	'extendedReq' => 'extendedResp',
	'abandonRequest' => ''
);
our %functions=(
	'bindRequest' => 'bind', 
	'unbindRequest' => 'unbind',
	'searchRequest' => 'search',
	'modifyRequest' => 'modify', 
	'addRequest'  => 'add', 
	'delRequest' => 'delete',
	'modDNRequest' => 'modifyDN',
	'compareRequest' => 'compare',
	'extendedReq' => 'extended',
	'abandonRequest' => 'abandon'
);
our @reqTypes = keys %respTypes;

sub new {
    my ($proto, $input, $output) = @_;
	my $class = ref($proto) || $proto;
	my $self = fields::new($class);

    #print STDERR Dumper($input);
    #print STDERR Dumper($output);

	$self->{in} = $input;
	$self->{out} = $output || $input;
	return $self;
}

sub handle {
	my Net::LDAP::Server $self = shift;
	my $in = $self->{in};
	my $out = $self->{out};
	
    #print STDERR Dumper($in);
    #print STDERR Dumper($out);

	asn_read($in, my $pdu);
	#print '-' x 80,"\n";
	#print "Received:\n";
	#Convert::ASN1::asn_dump(\*STDOUT,$pdu);
	my $request = $LDAPRequest->decode($pdu);
	my $mid = $request->{'messageID'} 
		or return 1;

	#print "messageID: $mid\n";
	#print Dumper($request);
	
	my $reqType;
	foreach my $type (@reqTypes) {
		if (defined $request->{$type}) {
			$reqType = $type;
			last;
		}
	}
	return 1 if !exists $respTypes{$reqType};  # unknown request type: let's hangup
	my $respType = $respTypes{$reqType};
    
	# here we can do something with the request of type $reqType
	my $reqData = $request->{$reqType};
	my $method = $functions{$reqType};
	my $result;
	if ($self->can($method)){
		if ($method eq 'search') {
			my @entries;
			eval { ($result,@entries) = $self->search($reqData, $request) };
		
			foreach my $entry (@entries) {
				my $data;
				# default is to return a searchResEntry
				my $sResType = 'searchResEntry';
				if (ref $entry eq 'Net::LDAP::Entry') {
					$data = $entry->{'asn'};		
				} elsif (ref $entry eq 'Net::LDAP::Reference') {
					$data = $entry->{'asn'};
					$sResType = 'searchResRef';
				} else{
					$data = $entry;
				}
				
				my $response;			
				#  is the full message specified?	
				if (defined $data->{'protocolOp'}) {
					$response = $data;
					$response->{'messageID'} = $mid;
				} else {
					$response = {
						'messageID' => $mid,
       				   	'protocolOp' => {
	       			   		 $sResType => $data
	       		   		}
	       		   	};		 
				}
				my $pdu = $LDAPResponse->encode($response);
				if ($pdu) {
					print $out $pdu;
				} else {
					$result = undef;
					last;
				}
			}
		} else {
			eval { $result = $self->$method($reqData, $request) };
		}
		$result = _operations_error() unless $result;
	} else {
		$result = {
			'matchedDN' => '',
			'errorMessage' => sprintf("%s operation is not supported by %s", $method, ref $self),
			'resultCode' => LDAP_UNWILLING_TO_PERFORM     
		};
	}
	
	# and now send the result to the client
	print $out &_encode_result($mid, $respType, $result) if $respType;
	
	return 0;
}	

sub _encode_result {
	my ($mid, $respType, $result) = @_;
	
	my $response = {
		'messageID' => $mid,
      	'protocolOp' => {
			$respType => $result
		}
	};
	my $pdu = $LDAPResponse->encode($response);
	
	# if response encoding failed return the error
	if (!$pdu) {
		$response->{'protocolOp'}->{$respType} = _operations_error();
		$pdu = $LDAPResponse->encode($response);
	};
	
	return $pdu;
}

sub _operations_error {
	my $err = $@;
	$err =~ s/ at .+$//;
	return {
		'matchedDN' => '',
		'errorMessage' => $err,
		'resultCode' => LDAP_OPERATIONS_ERROR          
	};
}

1;

__END__

=head1 NAME

Net::LDAP::Server - LDAP server side protocol handling

=head1 SYNOPSIS

  package MyServer;
  use Net::LDAP::Server;
  use Net::LDAP::Constant qw(LDAP_SUCCESS);
  use base 'Net::LDAP::Server';
  sub search {
      my $self = shift;
      my ($reqData, $fullRequest) = @_;
      print "Searching\n";
      ...
      return {
          'matchedDN' => '',
          'errorMessage' => '',
          'resultCode' => LDAP_SUCCESS
      }, @entries;
  }
  
  package main;
  my $handler = MyServer->new($socket);
  $handler->handle;

  # or with distinct input and output handles
  package main;
  my $handler = MyServer->new( $input_handle, $output_handle );
  $handler->handle;

=head1 ABSTRACT

This class provides the protocol handling for an LDAP server. You can subclass
it and implement the methods you need (see below). Then you just instantiate 
your subclass and call its C<handle> method to establish a connection with the client.

=head1 SUBCLASSING

You can subclass Net::LDAP::Server with the following lines:

  package MyServer;
  use Net::LDAP::Server;
  use base 'Net::LDAP::Server';

Then you can add your custom methods by just implementing a subroutine
named after the name of each method. These are supported methods:

=over 4

=item C<bind>

=item C<unbind>

=item C<search>

=item C<add>

=item C<modify>

=item C<delete>

=item C<modifyDN>

=item C<compare>

=item C<abandon>

=back

For any method that is not supplied, Net::LDAP::Server will return an 
C<LDAP_UNWILLING_TO_PERFORM>.

=head2 new()

You can also subclass the C<new> constructor to do something at connection time:

  sub new {
     my ($class, $sock) = @_;
     my $self = $class->SUPER::new($sock);
     printf "Accepted connection from: %s\n", $sock->peerhost();
     return $self;
  }

Note that $self is constructed using the L<fields> pragma, so if you want to add
data to it you should add a line like this in your subclass:

  use fields qw(myCustomField1 myCustomField2);

=head2 Methods

When a method is invoked it will be obviously passed C<$self> as generated by 
C<new>, and two variables:

=over 4

=item *
the Request datastructure that is specific for this method (e.g. BindRequest);

=item *
the full request message (useful if you want to access I<messageID> or I<controls> parts)

=back

You can look at L<Net::LDAP::ASN> or use L<Data::Dumper> to find out what is 
presented to your method:

  use Data::Dumper;
  sub search {
     print Dumper \@_;
  }

If anything goes wrong in the module you specify (e.g. it died or the result 
is not a correct ldapresult structure) Net::LDAP::Server will return an 
C<LDAP_OPERATIONS_ERROR> where the errorMessage will specify what went 
wrong. 

All methods should return a LDAPresult hashref, for example:

  return({
      'matchedDN' => '',
      'errorMessage' => '',
      'resultCode' => LDAP_SUCCESS
  });

C<search> should return a LDAPresult hashref followed by a list of entries 
(if applicable). Entries may be coded either as searchResEntry or 
searchRefEntry structures or as L<Net::LDAP::Entry> or L<Net::LDAP::Reference>
objects.

=head1 CLIENT HANDLING

=head2 handle()

When you get a socket from a client you can instantiate the class and handle 
the request:

  my $handler = MyServer->new($socket);
  $handler->handle;

Or, alternatively, you can pass two handles for input and output, respectively.

  my $handler = MyServer->new(*STDIN{IO},*STDOUT{IO});
  $handler->handle;

See examples in I<examples/> directory for sample servers, using L<IO::Select>,
L<Net::Daemon> or L<Net::Server>.

=head1 DEPENDENCIES

 Net::LDAP::ASN
 Net::LDAP::Constant

=head1 SEE ALSO

=over 4

=item L<Net::LDAP>

=item Examples in C<examples> directory.

=back

=head1 BUGS AND FEEDBACK

There are no known bugs. You are very welcome to write mail to the maintainer 
(aar@cpan.org) with your contributions, comments, suggestions, bug reports 
or complaints.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alessandro Ranellucci E<lt>aar@cpan.orgE<gt>
The original author of a Net::LDAP::Daemon module is 
Hans Klunder E<lt>hans.klunder@bigfoot.comE<gt>

=cut
