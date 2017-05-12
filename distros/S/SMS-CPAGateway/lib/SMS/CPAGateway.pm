#!/usr/bin/perl
# SMS::CPAGateway
#
# Copyright Eskild Hustvedt 2008, 2010 <zerodogg@cpan.org>
# for Portu Media & Communications
# 
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.

package SMS::CPAGateway;
use Any::Moose;
use LWP::UserAgent;
use URI::Encode;
use constant { true => 1, false => undef };

our $VERSION = 0.01;

# - Public attributes -

has 'servers' => (
	is => 'rw',
	isa => 'ArrayRef[Str]',
	required => true,
);

has 'fromNo' => (
	isa => 'Int',
	is => 'rw',
	required => true,
);

has 'price' => (
	isa => 'Int',
	is => 'rw',
	required => true,
	default => 0,
);

has 'key' => (
	isa => 'Str',
	required => true,
	is => 'rw',
);

has 'id' => (
	isa => 'Str',
	is => 'rw',
	builder => '_buildID',
	lazy => 1,
);

has 'errors'=> (
	isa => 'ArrayRef[Str]',
	is => 'rw',
	default => sub { [] },
	writer => '_writeErrors',
);

has 'hadError' => (
	isa => 'Bool',
	is => 'rw',
	default => false,
	writer => '_setError',
);

# - Public methods -

# Purpose: Send an SMS
# Usage: object->send(RECIPIENT,MESSAGE,PRICE?);
# RECIPIENT is the recipient phone number, with +XX direction code.
# MESSAGE is the message.
# PRICE is the price
sub send
{
	my $self = shift;
	my $recipient = shift;
	my $message = shift;
	my $price = shift;
	if (not $recipient =~ /^\+/)
	{
		if ($recipient =~ /^00/)
		{
			$recipient =~ s/^00/+/;
		}
		else
		{
			$self->_appendError('Recipient does not start with +');
			return false;
		}
	}
	if(not defined $price)
	{
		$price = $self->price;
	}
	elsif(not $price =~ /^\d+$/)
	{
		$self->_appendError('Illegal price value. "'.$price.'"');
		return false;
	}
	$self->_recipient($recipient);
	return $self->_SMSSend($message,$price);
}

# --- INTERNAL METHODS AND ATTRIBUTES ---

has '_recipient' => (
	isa => 'Str',
	is => 'rw',
);

has '_prevID' => (
	isa => 'Str',
	is => 'rw',
	);

has '_ua' => (
	isa => 'Object',
	is => 'ro',
	lazy => true,
	default => sub { LWP::UserAgent->new() },
);

has '_uriE' => (
	isa => 'Object',
	is => 'ro',
	lazy => true,
	default => sub { URI::Encode->new() },
);

# Purpose: Construct a unique identifier
# Usage: id = this->_buildID();
sub _buildID
{
	my $self = shift;
	my $recipient = $self->_recipient;
	$recipient =~ s/\+/00/;
	my $id;
	# Should be below 100 chars long, so loop until we get it right
	while(!defined $id || length($id) > 99)
	{
		$id = $recipient.'-'.time().int(rand(10_000)).int(rand(100_000)).'-SMS::CPAGateway-'.$VERSION;
	}
	$self->_prevID($id);
	return $id;
}

# Purpose: Get our unique identifier
# Usage: id = self->_getID();
sub _getID
{
	my $self = shift;
	if(
		(not defined $self->_prevID)
			or
		(not $self->_prevID eq $self->id)
	)
	{
		return $self->id;
	}
	$self->id($self->_buildID());
	return $self->id;
}

sub _appendError
{
	my $self = shift;
	my $error = shift;
	my $errorList = $self->errors;
	if (ref($error))
	{
		$error = 'Error reply '.$error->{reply}.' when requesting URL '.$error->{URL}.' at '.time();
	}
	push(@{$errorList},$error);
	$self->_writeErrors($errorList);
	$self->_setError(true);
}

# Purpose: Handle errors in requests
# Usage: my $ret = $self->_errHandler(URI,reply);
#
# This method verifies the content of reply and returns true or false.
# false meaning that sending failed and we should retry. Errors are
# added to the error list via $self->_appendError
sub _errHandler
{
	my $self = shift;
	my $URL = shift;
	my $reply = shift;
	
	my $content = $reply->content;
	
	if ($content =~ /^\s*ok/i)
	{
		# All is well
		return true;
	}
	elsif ($content =~ /^\s*err/i)
	{
		$self->_appendError( { URL => $URL, reply => $content } );
		return false;
	}
	else
	{
		# Okay, this server isn't acting properly
		$self->_appendError('The server returned an unknown reply, so I am assuming failure: '.$content);
		return false;
	}
}

# Purpose: Construct the request URI and attempt to submit it to the servers
# Usage: $ret = $self->_SMSSend(message,$price);
sub _SMSSend
{
	my $self = shift;
	my $message = shift;
	my $price = shift;
	# Construct URI
	my $URI = 	'?auth='.$self->_uriE->encode($self->key).
				'&id='.$self->_uriE->encode($self->_getID).
				'&from='.$self->_uriE->encode($self->fromNo).
				'&to='.$self->_uriE->encode($self->_recipient).
				'&type=text&data='.$self->_uriE->encode($message).
				'&price='.$price;

	foreach my $host (@{$self->servers})
	{
		if ($self->_attemptSend($host,$URI))
		{
			# We sent it and all went well
			return true;
		}
		# If not, we didn't send it and we ought to try the next server
	}
	# If we've gotten this far then all servers failed and we have to give up
	$self->_appendError('All servers failed. Giving up.');
	return false;
}

# Purpose: Attempt to send an SMS
# Usage: $ret =  $self->_attemptSend(host,URI);
sub _attemptSend
{
	my $self = shift;
	my $host = shift;
	my $URI = shift;

	my $request = $host.'/'.$URI;

	my $reply = $self->_ua->get($request);
	if ($reply->is_success())
	{
		return $self->_errHandler($request,$reply);
	}
	else
	{
		$self->_appendError('Server '.$host.' failed');
		return false;
	}
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

SMS::CPAGateway - Send an SMS through a gateway using the CPA Gateway protocol

=head1 SYNOPSIS

	use SMS::CPAGateway;
	use Data::Dumper qw(Dumper);

	my $sms = SMS::CPAGateway->new(
		# Parameters shown with their defaults
		price => 0,			# Can also be overriden on a per-message basis
		fromNo => undef,	# Value required at construction time
		key => undef,		# Value required at construction time
		servers => undef,	# Value required at construction time
		);
	if (! $sms->send($PHONENO,$MESSAGE))
	{
		# Some error occurred. All servers failed, it gave up sending.
		your_email_sending_sub(youremail,'Sending message to '.$PHONENO.' failed:'."\n\n".Dumper($sms->errors));
	}
	elsif ($sms->hadError)
	{
		# Some error occurred, but SMS::CPAGateway recovered from it. You can
		# log the errors if you wish, but there is no need to as the SMS
		# was successfully sent.
		#
		# This can happen ie. when the phone number supplied is strange (ie.
		# missing country prefix) or when either of the servers failed. If all
		# servers fail, send() will return false and trigger the above check
		# instead.
		log_errors(Dumper($sms->errors));
	} 

=head1 DESCRIPTION

This module offers a convenient way of sending an SMS from a Perl program
using any server(s) that understand the CPA Gateway protocol version 2, which
is the current release of the protocol.

This module and the author are not affiliated with Teletopia interactive
in any way.

=head1 METHODS

=over

=item I<new>

Constructs a new instance of the class. You can supply any of the attributes
listed below in the I<Attributes> section to this method during construction
time to initialize them.

The following attributes MUST be supplied at construction time: fromNo, key

=item I<send($number,$message,$price = $object-E<gt>price);>

Sends a message. It takes either two or three parameters. $number is the
recipient phone number and $message is the text message to send. $price
is the price of the message, this parameter is optional and defaults to
the value of the price attribute if it is undef.

The recipient phone number must include the direction code.

Usage:
	$sms->send('+0000000000','Message',0);

This returns true on success and false on failure. See also hadError and
errors.

=item I<hadError>

Returns true if an error has occured when sending since this object was
instantiated. This does NOT indicate that sending a message, or even the
last message, failed. The return value of send() indicates that. An error
could for instance be that a single server failed, and that we thus
fell back to either of the fallback servers.

=item I<errors>

Returns an array of error messages.

=item I<id>

This is used to set and get the id used for a message. Note than an ID can
only be used to send a single message, and if the same ID is attempted to be
used for multiple messages, the module will automatically generate a random
one instead.

If supplied with a string, sets the id for the next SMS to be sent to the
string supplied.

If called without any parameters, returns either of the following:

	- The id that is going to be used to send the first SMS (if you
		have not yet sent any SMS through the instance).
	- The id that was used to send the last SMS sent (as long as you have
		not already set an ID that will be used for the next one
		by calling this method with a string value).


=back

=head2 Attributes

=over

=item I<fromNo>

The from number. Must be a number that you are authorized by the server to
use.

=item I<price>

The price of an SMS. This defaults to 0. This can also be supplied as a parameter
to send()

=item I<key>

Your authorization key.

=item I<id>

The ID that is sent along with the message. If this is not supplied then
it will be automatically generated. See the id method.

=item I<servers>

An arrayref of servers to attempt. The list of servers are provided by the
service provider.

Example:
	 [ 'http://gateway1.example.com:12345', 'http://gateway2.example.com:12345', 'http://gateway3.example.com:12345' ]

=back

=head1 BUGS AND LIMITATIONS

The module has only been tested with UTF-8-compatible messages.

It doesn't provide any means of recieving SMS messages, as that is simply
done by HTTP POST requests to a web server, and there is very little a module
can add to that as there are a load of different ways to read parameters,
and there is little that has to be done with that data without entering
site-specific logic.

Please report any bugs or feature requests to
L<http://github.com/portu/SMS-CPAGateway/issues>.

=head1 SEE ALSO

L<http://cpa.teletopiainteractive.no/>

=head1 AUTHOR

Eskild Hustvedt, E<lt>zerodogg@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 by Eskild Hustvedt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.
