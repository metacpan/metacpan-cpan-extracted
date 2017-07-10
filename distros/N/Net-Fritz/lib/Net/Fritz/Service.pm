use strict;
use warnings;
# Copyright (C) 2015  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later.

package Net::Fritz::Service;
# ABSTRACT: represents a TR064 service
$Net::Fritz::Service::VERSION = 'v0.0.8';

use Digest::MD5 qw(md5_hex);
use SOAP::Lite; # +trace => [ transport => sub { print $_[0]->as_string } ]; # TODO: remove

use Net::Fritz::Action;
use Net::Fritz::Data;

use Moo;

with 'Net::Fritz::IsNoError';


has fritz        => ( is => 'ro' );


has xmltree      => ( is => 'ro' );

sub _build_an_attribute {
    my $self = shift;
    my $attr = shift;
    my $xml  = $self->xmltree;

    my $val;

    if (exists $xml->{$attr}) {
	$val = $xml->{$attr}->[0];
    }

    return $val;
}


has scpd         => ( is => 'lazy', init_arg => undef );

sub _build_scpd {
    my $self = shift;

    my $url  = $self->fritz->upnp_url . $self->SCPDURL;

    my $response = $self->fritz->_ua->get($url);

    if ($response->is_success) {
	return Net::Fritz::Data->new(
	    $self->fritz->_xs->parse_string($response->decoded_content)
	    );
    }
    else {
	return Net::Fritz::Error->new($response->status_line);
    }
}


has action_hash  => ( is => 'lazy', init_arg => undef );

sub _build_action_hash {
    my $self = shift;

    my $scpd = $self->scpd;

    if ($scpd->error) {
	return {};
	# TODO: how to report this error? we return no object
    }
    else {
	my $hash = {};
	my $xml = $scpd->data->{actionList}->[0]->{action};

	foreach my $action (@{$xml}) {
	    $hash->{$action->{name}->[0]} = Net::Fritz::Action->new(
		xmltree => $action
		);
	}
	return $hash;
    }
}


has serviceType  => ( is => 'lazy', init_arg => undef );

sub _build_serviceType {
    my $self = shift;
    return $self->_build_an_attribute('serviceType');
}


has serviceId    => ( is => 'lazy', init_arg => undef );

sub _build_serviceId {
    my $self = shift;
    return $self->_build_an_attribute('serviceId');
}


has controlURL   => ( is => 'lazy', init_arg => undef );

sub _build_controlURL {
    my $self = shift;
    return $self->_build_an_attribute('controlURL');
}


has eventSubURL  => ( is => 'lazy', init_arg => undef );

sub _build_eventSubURL {
    my $self = shift;
    return $self->_build_an_attribute('eventSubURL');
}


has SCPDURL      => ( is => 'lazy', init_arg => undef );

sub _build_SCPDURL {
    my $self = shift;
    return $self->_build_an_attribute('SCPDURL');
}


sub call {
    my $self      = shift;
    my $action    = shift;
    my %call_args = (@_);

    if (! exists $self->action_hash->{$action}) {
	return Net::Fritz::Error->new("unknown action $action");
    }

    my $err = _hash_check(
	\%call_args,
	{ map { $_ => 0 } @{$self->action_hash->{$action}->args_in} },
	'unknown input argument',
	'missing input argument'
	);
    return $err if $err->error;

    my @args;
    foreach my $arg (keys %call_args) {
	push @args, SOAP::Data->name($arg)->value($call_args{$arg})->type('string');
    }

    my $url = $self->fritz->upnp_url . $self->controlURL;

    my $soap = SOAP::Lite->new(
	proxy    => [ $url, ssl_opts => $self->fritz->_sslopts, keep_alive => 1, ],
	uri      => $self->serviceType,
	readable => 1, # TODO: remove this
	);
    # Keep up to 4 connections open
    $soap->transport->conn_cache({ total_capacity => 4 });

    # expect the call to need authentication, so prepare an initial request
    my $auth = $self->_get_initial_auth;

    # SOAP::Lite just dies on transport error (eg. 401 Unauthorized), so eval this
    my $som;
    eval {
	$som = $soap->call($action, @args, $auth);
    };

    # if we got a 503 authentication error: fine!
    # now we gots us a nonce and can retry
    if (! $@
	and $som->fault
	and exists $som->fault->{detail}->{UPnPError}->{errorCode}
	and $som->fault->{detail}->{UPnPError}->{errorCode} == 503) {

	if (defined $self->fritz->username
	    and defined $self->fritz->password) {

	    $auth = $self->_get_real_auth($som->headers);

	    eval {
		$som = $soap->call($action, @args, $auth);
	    };
	}
	else {
	    return Net::Fritz::Error->new("authentication needed, but no credentials given");
	}
    }

    if ($@) {
	return Net::Fritz::Error->new($@);
    }
    elsif ($som->fault) {
	my @error = (
	    $som->fault->{faultcode},
	    $som->fault->{faultstring},
	    $som->fault->{detail}->{UPnPError}->{errorCode},
	    $som->fault->{detail}->{UPnPError}->{errorDescription}
	    );
	@error = map { defined $_ ? $_ : () } @error;
	return Net::Fritz::Error->new(join ' ', @error);
    }
    else {
	# according to the docs, $som->paramsin returns an array of hashes.  I don't see this :-/
	my $args_out = $som->body->{$action.'Response'};
	$args_out = {} unless ref $args_out; # fix empty responses

	$err = _hash_check(
	    $args_out,
	    { map { $_ => 0 } @{$self->action_hash->{$action}->args_out} },
	    'unknown output argument',
	    'missing output argument'
	    );
	return $err if $err->error;

	return Net::Fritz::Data->new($args_out);
    }
}

sub _get_initial_auth {
    my $self = shift;

    my $userid = SOAP::Header->name('UserID')
	->value($self->fritz->username);

    return SOAP::Header
	->name('h:InitChallenge')
	->attr({'xmlns:h' => 'http://soap-authentication.org/digest/2001/10/',
		's:mustUnderstand' => '1'})
	->value(\$userid);
}

sub _get_real_auth {
    my $self = shift;

    my $parm = shift;

    my $secret = md5_hex( join (':',
				$self->fritz->username,
				$parm->{Realm},
				$self->fritz->password,
			  ) );

    my $auth = SOAP::Header->name('Auth')
	->value(
	md5_hex( $secret . ':' . $parm->{Nonce} )
	);

    my $nonce = SOAP::Header->name('Nonce')
	->value($parm->{Nonce});

    my $realm = SOAP::Header->name('Realm')
	->value($parm->{Realm});

    my $userid = SOAP::Header->name('UserID')
	->value($self->fritz->username);

    return SOAP::Header
	->name('h:ClientAuth')
	->attr({'xmlns:h' => 'http://soap-authentication.org/digest/2001/10/',
		's:mustUnderstand' => '1'})
	->value(\SOAP::Header->value($nonce, $auth, $userid, $realm));
}

sub _hash_check {
    my ($hash_a, $hash_b, $msg_a, $msg_b) = (@_);

    foreach my $arg (keys %{$hash_a}) {
	if (! exists $hash_b->{$arg}) {
	    return Net::Fritz::Error->new("$msg_a $arg");
	}
    }

    foreach my $arg (keys %{$hash_b}) {
	if (! exists $hash_a->{$arg}) {
	    return Net::Fritz::Error->new("$msg_b $arg");
	}
    }

    return Net::Fritz::Data->new();
}


sub dump {
    my $self = shift;

    my $indent = shift;
    $indent = '' unless defined $indent;

    my $text = "${indent}Net::Fritz::Service:\n";
    $indent .= '  ';
    $text .= "${indent}serviceType     = " . $self->serviceType . "\n";
    $text .= "${indent}controlURL      = " . $self->controlURL  . "\n";
    $text .= "${indent}SCPDURL         = " . $self->SCPDURL     . "\n";

    my @actions = values %{$self->action_hash};
    if (@actions) {
	$text .= "${indent}actions         = {\n";
	foreach my $action (@actions) {
	    $text .= $action->dump($indent . '  ');
	}
	$text .= "${indent}}\n";
    }

    return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Fritz::Service - represents a TR064 service

=head1 VERSION

version v0.0.8

=head1 SYNOPSIS

    my $fritz    = Net::Fritz::Box->new();
    my $device   = $fritz->discover();
    my $service  = $device->get_service('DeviceInfo:1');

    # call an action
    my $response = $service->call('GetSecurityPort');

    # show all data
    $service->dump();

=head1 DESCRIPTION

This class represents a TR064 service belonging to a
L<Net::Fritz::Device>.  A service consists of one or more
L<Net::Fritz::Action>s that interact with the underlying device.

=head1 ATTRIBUTES (read-only)

=head2 fritz

A L<Net::Fritz::Box> instance containing the current configuration
information (device address, authentication etc.).

=head2 xmltree

A complex hashref containing most information about this
L<Net::Fritz::Service>.  This is the parsed form of the TR064 XML
which describes the service.  It contains nearly all information
besides L</fritz> and L</scpd>.

=head2 scpd

A complex hashref containing all information about this
L<Net::Fritz::Service>.  This is the parsed form of the XML available
at L</SCPDURL> which describes the service and its
L<Net::Fritz::Action>s.

=head2 action_hash

A hashref containing all L<Net::Fritz::Action>s of this service
indexed by their L<Net::Fritz::Action/name>.

=head2 serviceType

The I<serviceType> (string) of this service which is used by
L<Net::Fritz::Device> to look up services.

=head2 serviceId

The I<serviceId> (string) of this service.

=head2 controlURL

The I<controlURL> (URL string) of this service which is needed to
L<call|Net::Fritz::Action/call> any L<Net::Fritz::Action>s of this
service.

=head2 eventSubURL

The I<eventSubURL> (URL string) of this service for subscribing to or
unsubscribing from events.

=head2 SCPDURL

The I<SCPDURL> (URL string) of the SCPD file of this service where
most of the other attributes are read from.

=head2 error

See L<Net::Fritz::IsNoError/error>.

=head1 METHODS

=head2 new

Creates a new L<Net::Fritz::Service> object.  You propably don't have
to call this method, it's mostly used internally.  Expects parameters
in C<key =E<gt> value> form with the following keys:

=over

=item I<fritz>

L<Net::Fritz::Box> configuration object

=item I<xmltree>

service information in parsed XML format

=back

=head2 call(I<action_name [I<parameter> => I<value>] [...])

Calls the L<Net::Fritz::Action> named I<action_name> of this service.
Response data from the service call is wrapped as L<Net::Fritz::Data>.
If the action expects parameters, they must be passed as
key=L<gt>value pairs.

If no matching action is found, the parameters don't match the action
or any other error occurs, a L<Net::Fritz::Error> is returned.

=head2 dump(I<indent>)

Returns some preformatted multiline information about the object.
Useful for debugging purposes, printing or logging.  The optional
parameter I<indent> is used for indentation of the output by
prepending it to every line.

Recursively descends into actions, so dumping a service also shows all
its actions as well.

=head2 errorcheck

See L<Net::Fritz::IsNoError/errorcheck>.

=head1 SEE ALSO

See L<Net::Fritz> for general information about this package,
especially L<Net::Fritz/INTERFACE> for links to the other classes.

=head1 AUTHOR

Christian Garbs <mitch@cgarbs.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Christian Garbs

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
