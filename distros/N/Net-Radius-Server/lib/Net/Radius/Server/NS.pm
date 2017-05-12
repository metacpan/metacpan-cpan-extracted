package Net::Radius::Server::NS;

use 5.008;
use strict;
use warnings;
use Net::Radius::Packet;
use base qw/Net::Server::MultiType Net::Radius::Server/;
use Net::Radius::Server::Base qw/:all/;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 89 $ =~ /\d+/g)[0]/1000 };

# Verify that the required configuration keys are present. Initialize
# whatever we'll require for request processing, such as dictionaries,
# RADIUS setup file and 'secret' sources.
sub options
{
    my $self	= shift;
    my $prop	= $self->{server};
    my $ref 	= shift;

    $self->SUPER::options($ref, @_);

    for ( qw(nrs_rule_script nrs_secret_script nrs_dictionary_script) )
    {
	$prop->{$_} = [] unless exists $prop->{$_};
	$ref->{$_} = $prop->{$_};
    }
}

sub configure
{
    my $self = shift;		# A Net::Server-derived object
    my $s = $self->{server};
    
    $self->SUPER::configure(@_);

    # We need to have a few keys defined before proceeding.
    die __PACKAGE__, " definitions are missing\n"
	unless (exists $s->{nrs_rule_script}
		and exists $s->{nrs_secret_script}
		and exists $s->{nrs_dictionary_script});

    for (qw/nrs_dictionary_script nrs_rule_script nrs_secret_script/)
    {
	die __PACKAGE__, ": Exactly one $_ must be specified\n"
	    if @{$s->{$_}} != 1;
    }

    my ($d_method, $s_method, $rules);

    eval { $d_method = do ($s->{nrs_dictionary_script}->[0]) };
    warn "Dictionary script ", $s->{nrs_dictionary_script}->[0], 
    " produced output: $@\n" if $@;
    die "Dictionary script ", $s->{nrs_dictionary_script}->[0], 
    " must return a coderef (returned " 
	. ($d_method||'false/undef') . ")\n"
	unless ref($d_method) eq 'CODE';

    eval { $s_method = do ($s->{nrs_secret_script}->[0]) };
    warn "Secret script ", $s->{nrs_secret_script}->[0], 
    " produced output: $@\n" if $@;
    die "Secret script ", $s->{nrs_secret_script}->[0], 
    " must return a coderef (returned " 
	. ($s_method||'false/undef') . ")\n"
	unless ref($s_method) eq 'CODE';

    eval { $rules = do ($s->{nrs_rule_script}->[0]) };
    warn "Rule script produced output: $@\n" if $@;
    die "Rule script must return a listref (returned " 
	. ($rules||'false/undef') . ")\n"
	unless ref($rules) eq 'ARRAY';

    $self->{_nrs} = {
	secret		=> $s_method,
	dict		=> $d_method,
	rules		=> $rules,
    };
}

# Add the processing handler that is responsible for each packet
sub process_request
{
    my $self = shift;
    my $prop = $self->{server};
    my $data = { 
	packet		=> $prop->{udp_data}, 
	peer_addr	=> $prop->{peeraddr},
	peer_host	=> $prop->{peerhost},
	peer_port	=> $prop->{peerport},
	port		=> $prop->{sockport},
	sockaddr	=> $prop->{sockaddr},
	server		=> $self,
    };

    if (length($data->{packet}) < 18)
    {
	$self->log(2, "Packet too short - Ignoring");
	return;
    }

    $data->{secret}	= $self->{_nrs}->{secret}->($data);
    $data->{dict}	= $self->{_nrs}->{dict}->($data);
    $data->{response}	= new Net::Radius::Packet $data->{dict};
    $data->{request}	= Net::Radius::Packet->new($data->{dict}, 
						   $data->{packet});

    if (not defined $data->{request})
    {
	$self->log(2, "Failed to decode RADIUS packet (garbage?)");
	return;
    }

    $self->log(2, "Received from " . ($data->{peer_addr} || '[no peer]')
	       . ' (' . $data->{request}->code . ' '
	       . join(', ', map { "$_ => " . $data->{request}->attr($_) } 
		      grep { $_ !~ /(?i)password|-message/ }
		      $data->{request}->attributes)
	       . ') ');

    $self->log(4, "Request: " . $data->{request}->str_dump);

    # Verify that the authenticator in the packet matches the packet
    # data. Discard the packet if this check fails

    if (grep { $data->{request}->code eq $_ } 
	qw/Accounting-Request
	Disconnect-Request Disconnect-ACK Disconnect-NAK 
	CoA-Request CoA-ACK CoA-NAK/)
    {
	if (auth_acct_verify($data->{packet}, $data->{secret}))
	{
	    $self->log(4, $data->{request}->code . 
		       ' with good secret from ' .
		       $data->{peer_addr});
	}
	else
	{
	    # Bad secret - Ignore request
	    $self->log(2, $data->{request}->code . 
		       ' with bad secret from ' .
		       $data->{peer_addr});
	    return;
	}
    }

    my $res = undef;
    for my $r (@{$self->{_nrs}->{rules}})
    {
	$res = $r->eval($data);
	unless (defined $res)
	{
	    $self->log(4, $r->description . ": Did not match");
	    next;
	}

	if ($res & NRS_SET_DISCARD)
	{
	    $self->log(2, $r->description . ": Requested discard");
	    return;
	}

	if ($res & NRS_SET_SKIP)
	{
	    $self->log(4, $r->description . ": Requested skip");
	    next;
	}

	if ($res & NRS_SET_RESPOND)
	{
	    $self->log(4, $r->description . ": Requested respond");
	    last;
	}
    }

    unless (defined $res)
    {
	$self->log(2, "Discard: No matching rule");
	return;
    }

    if ($res & NRS_SET_RESPOND)
    {
	$self->log(2, "Sent " . $data->{response}->code . ' '
		   . join(', ', map { "$_ => " . $data->{response}->attr($_) } 
			  grep { $_ !~ /(?i)password|-message/ }
			  $data->{response}->attributes) . " to request from " 
		   . ($data->{peer_addr} || '[no peer]')
		   . ' (' . $data->{request}->code . ' '
		   . join(', ', map { "$_ => " . $data->{request}->attr($_) } 
			  grep { $_ !~ /(?i)password|-message/ }
			  $data->{request}->attributes)
		   . ') ');
	$self->log(3, "Responding");
	my $reply_packet = auth_resp($data->{response}->pack, 
				     $data->{secret});
	$self->{server}->{client}->send($reply_packet);
	$self->log(4, "Response: " . 
		   Net::Radius::Packet->new($data->{dict}, 
					    $reply_packet)->str_dump);
    }
    else
    {
	$self->log(2, "Ignoring request from " . 
		   ($data->{peer_addr} || '[no peer]')
		   . ' (' . $data->{request}->code . ' '
		   . join(', ', map { "$_ => " . $data->{request}->attr($_) } 
			  grep { $_ !~ /(?i)password|-message/ }
			  $data->{request}->attributes)
		   . ') ');
    }
}

42;

__END__

=head1 NAME

Net::Radius::Server::NS - Use Net::Server to provide a Net::Radius::Server

=head1 SYNOPSIS

  use Net::Radius::Server::NS;

=head1 DESCRIPTION

C<Net::Radius::Server::NS> leverages C<Net::Server> to receive,
process and respond RADIUS requests using the C<Net::Radius::Server>
framework.

The C<nrsd> script included in the C<Net::Radius::Server> distribution
ties in with this module and performs an invocation suitable for
running a production RADIUS server. Usually, the invocation will look
like the following example:

  nrsd --conf_file nrsd.cfg

The configuration file (or any other means of configuration supported
by Net::Server(3)) must include the following entries:

=over

=item nrs_rule_script      

Specify the name of a Perl script that will initialize the rules used
to process RADIUS requests. Rules will usually be objects of either
Net::Radius::Server::Rule(3) or a derived class.

Invocation of the script is done through a C<require>.

The script must return a reference to the list of rules to
apply. Rules will be applied using their respective C<-E<gt>eval()>
methods in the order they appear in the list. Each C<-E<gt>eval()>
method will receive the same, fully initialized invocation
hashref. See C<Net::Radius::Server> for more information in the
contents of the invocation hashref.

=item nrs_secret_script

Specify the name of a Perl script that will provide a method used to
determine what shared secret to use in decoding incoming RADIUS
packets.

Invocation of the script is done through a C<require>.

The script must return a reference to a function that will be called
for each request. The return value of this sub must be the RADIUS
shared secret that must be used to decode the request packet and to
encode the eventual response.

At the time this sub is invoked, the RADIUS packet is not yet
decoded. Therefore, only the following entries in the invocation
hashref are available: packet, peer_addr, peer_host, peer_port, port,
sockaddr and server.

See C<Net::Radius::Server> for more information in the contents of the
invocation hashref.

=item nrs_dictionary_script

Specify the name of a Perl script that will provide a method used to
determine what dictionary to use in decoding incoming RADIUS packets.

Invocation of the script is done through a C<require>.

The script must return a reference to a function that will be called
for each request. The return value of this sub must be the RADIUS
dictionary that must be used to decode the request packet and to
encode the eventual response. The RADIUS dictionary will usually be a
C<Net::Radius::Dictionary> object.

At the time this sub is invoked, the RADIUS packet is not yet
decoded. Therefore, only the following entries in the invocation
hashref are available: packet, peer_addr, peer_host, peer_port, port,
sockaddr, server and secret.

See C<Net::Radius::Server> for more information in the contents of the
invocation hashref.

=back

The output of any of the scripts will be logged, as these are not
expected to produce output under normal circumstances.

=head2 EXPORT

None by default.

=head1 HISTORY

  $Log$
  Revision 1.8  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.7  2006/12/14 16:25:33  lem
  Improved logging messages - Use log level 2 for normal
  operation. Level 1 is very un-verbose. Levels 3 and 4 provide
  increasing debug messages

  Revision 1.6  2006/12/14 15:52:25  lem
  Fix CVS tags


=head1 SEE ALSO

Perl(1), nrsd(8), Net::Server(3), Net::Radius::Dictionary(3),
Net::Radius::Server(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut
