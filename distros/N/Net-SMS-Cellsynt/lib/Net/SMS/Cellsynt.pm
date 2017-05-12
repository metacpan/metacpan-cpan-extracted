#!/usr/bin/perl
# Copyright 2009-2011, 2015, Olof Johansson <olof@cpan.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::SMS::Cellsynt;
our $VERSION = '0.32';
use strict;
use warnings;
use WWW::Curl::Easy;
use URI;
use URI::Escape;
use URI::QueryParam;
use Carp;

=pod

=head1 NAME

Net::SMS::Cellsynt - Send SMS through Cellsynt SMS gateway

=head1 SYNOPSIS

 use Net::SMS::Cellsynt;

 $sms = Net::SMS::Cellsynt->new(
        origtype=>'alpha',
        orig=>'zibri',
 	username=>'foo',
	password=>'bar',
 );

 $sms->send_sms(
   to=>$recipient,
   text=>'this text is being sent to you bu Net::SMS::Cellsynt',
 );

=head1 DESCRIPTION

Net::SMS::Cellsynt provides a perl object oriented interface to the
Cellsynt SMS HTTP API, which allows you to send SMS from within your
script or application.

To use this module you must have a Cellsynt account.

=head1 CONSTRUCTOR

=head2 new( parameters )

=head3 MANDATORY PARAMETERS

=over 8

=item username => $username

Your Cellsynt username.

=item password => $password

Your Cellsynt password.

=item origtype => $origtype

Type of originator. This can be either "alpha", where you supply a
string in orig parameter that the recpient will see as sender (note
that the recipient cannot answer this types of SMS); numeric, where
you supply a telephone number in the orig parameter and shortcode
where you supply a numerical short code for a operator network.

=item orig => $orig

This is the "sender" the recpient sees when recieving the SMS.
Depending on the value of origtype this should be a string, a
telephone number or a numerical shortcode. (See origtype)

=back

=head3 OPTIONAL PARAMETERS

=over 8

=item ttl

This value determines how long the SMS can be tried to be delivered,
in seconds. If this value is above the operator's max value, the
operator's value is used. Default is not set.

=item concat

Setting this to a value above 1 will allow for longer SMS:es to be
sent. One SMS can use 153 bytes, and with this you can send up to
6 SMS:es (918 bytes).

=item simulate

If set to a value other than 0, the module will output the URI that
would be used if this wasn't a simulation, and return, when callng
the B<send_sms> subroutine. Default is 0.

=item uri

Set an alternative URI to a service implementing the Cellsynt API.
Default is "https://se-1.cellsynt.net/sms.php".

=back

=cut

sub new {
	my $class = shift;
	my $self = {
		uri => 'https://se-1.cellsynt.net/sms.php',
		simulate => 0,
		@_,
	};
	$self->{curl} = new WWW::Curl::Easy;

	bless $self, $class;
	return $self;
}

=head1 METHODS

=head2 send_sms(to=>$recipient, $text=>"msg")

Will send message "msg" as an SMS to $recipient, unless the
object has set the simulate object; then the send_msg will output
the URI that would be used to send the SMS.

$recipient is a telephone number in international format: The
Swedish telephone number 0700123456 will translate into
0046700123456 --- it is the caller's responsibility to convert
numbers into this format before calling send_sms.

The $text parameter is the SMS "body". This must be encoded using
ISO-8859-1. It must not be longer than 160 characters.

The method will return a hashref containing a status key. If the
status key is "ok", the key "id" is also present, containing the
tracking ID supplied by the SMS gateway. If the status key
matches /error-\w+/, the key "message" is also present. I.e.:

 { status => 'ok', id => 'abcdef123456' }
 { status => 'error-interal', message => 'example error message' }
 { status => 'error-gateway', message => 'example error message' }

The module differentiate between errors from the SMS gateway
provider and internal errors. The message in error-gateway comes
directly from the provider.

=cut

sub send_sms {
	my $self = shift;
	my $param = {
		@_,
	};

	my $base = $self->{uri};
	my $test = $self->{test};

	my $username = $self->{username};
	my $password = $self->{password};
	my $origtype = $self->{origtype};
	my $orig = $self->{orig};
	#my $text = uri_escape($param->{text});
	my $text = $param->{text};
	my $ttl = $param->{ttl};
	my $concat = $param->{concat};

	my $dest = $param->{to};

	my $uri = URI->new($base);

	if($dest !~ /^00/) {
		return {
			status => 'error-internal',
			message => 'Phone number not in expected format'
		};
	}

	$uri->query_param(username => $username);
	$uri->query_param(password => $password);
	$uri->query_param(destination => $dest);
	$uri->query_param(text => $text);
	$uri->query_param(originatortype => $origtype);
	$uri->query_param(originator => $orig);

	$uri->query_param(expiry => $ttl) if defined $ttl;
	$uri->query_param(concat => $concat) if defined $concat;

	# this username is used in the example script.
	if($username eq 'zibri') {
		return {
			status => 'error-internal',
			message => 'Don\'t run the example script as is',
		};
	}

	if($test) {
		return {
			status => 'ok-test',
			uri => $uri,
		};
	}

	my $body;
	$self->{curl}->setopt(CURLOPT_URL, $uri);
	$self->{curl}->setopt(CURLOPT_WRITEDATA, \$body);
	$self->{curl}->setopt(CURLOPT_FOLLOWLOCATION, 1);
	$self->{curl}->perform();

	if(not $body) {
		return {
			status => 'error-internal',
			message => 'SMS gateway does not follow '.
			           'protocol (empty body)',
		};
	} elsif($body =~ /^OK: (.*)/) {
		return {
			status => 'ok',
			id => $1,

			# Becuase of a bug in previous versions, we didn't
			# set an "id" key, but instead, the reference id
			# was reported via the "uri" key. For backwards
			# compatibility, we'll continue support uri as well,
			# but this will be removed in a future version.
			uri => $1,
		};
	} elsif($body=~/^Error: (.*)/) {
		return {
			status => 'error-gateway',
			message => $1,

			# Becuase of a bug in previous versions, we didn't
			# set a "message" key, but instead, the error text
			# was reported via the "uri" key. For backwards
			# compatibility, we'll continue support uri as well,
			# but this will be removed in a future version.
			uri => $1,
		};
	} else {
		return {
			status => 'error-internal',
			message => 'SMS gateway does not follow protocol',
		};
	}
}

=head2 sender(origtype=>$origtype, orig=>$orig)

Update sender. You can set either or both values. See constructor
documentation for valid values.

=cut

sub sender {
	my $self = shift;
	my $param = {
		@_,
	};

	$self->{origtype} = $param->{origtype} if $param->{origtype};
	$self->{orig} = $param->{orig} if $param->{orig};
}

1;

=head1 SEE ALSO

http://cellsynt.com/

=head1 AVAILABILITY

Latest stable version is available on CPAN. Current development
version is available on https://github.com/olof/Net-SMS-Cellsynt.

=head1 COPYRIGHT

Copyright (c) 2009-2011, 2015, Olof 'zibri' Johansson <olof@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
