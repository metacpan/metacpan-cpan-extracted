package SRS::EPP::Command::Info::Contact;
{
  $SRS::EPP::Command::Info::Contact::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Info';

use MooseX::Params::Validate;
use SRS::EPP::Session;
use XML::EPP::Contact;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

use XML::EPP::Contact::Info::Response;
use XML::EPP::Contact::PostalInfo;
use XML::EPP::Contact::Addr;
use XML::EPP::Contact::Status;

# for plugin system to connect
sub xmlns {
	XML::EPP::Contact::Node::xmlns();
}

sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );    
    
	$self->session($session);
	my $epp = $self->message;
	my $payload = $epp->message->argument->payload;

	# we're not supporting authInfo, so get out of here with an
	# EPP response
	if ( $payload->has_auth_info ) {
		return $self->make_response(code => 2307);
	}

	return XML::SRS::Handle::Query->new(
		handle_id_filter => $payload->id,
	);
}

has 'code' => (
	is => "rw",
	isa => "Int",
);

sub zero_pad {
	my $registrar_id = shift;
	sprintf("%03d", $registrar_id);
}

sub notify {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );    
    
	my $message = $rs->[0]->message;
	my $response = $message->response;

	if ( $self->code ) {
		return $self->make_response(code => $self->code);
	}

	unless ($response) {

		# assume the contact doesn't exist
		return $self->make_response(code => 2303);
	}

	# make the Info::Response object
	my %addr = (
		street => [
			$response->address->address1,
			$response->address->address2||(),
		],
		city   => $response->address->city,
		cc     => $response->address->cc,
	);

	# state or province
	$addr{sp} = $response->address->region
		if defined $response->address->region;

	$addr{pc} = $response->address->postcode
		if defined $response->address->postcode;

	# Compare the contact's creation date against the audit time,
	# to tell us if it has been updated
	my $contact_updated = 0;
	if (
		$response->created_date->timestamptz ne
		$response->audit->when->begin->timestamptz
		)
	{
		$contact_updated = 1;
	}

	# generate this required field
	my $roid = substr(
		md5_hex(
			$response->registrar_id . $response->handle_id
		),
		0,
		12
	) . '-CON';

	# build the response
	my $r = XML::EPP::Contact::Info::Response->new(
		id => $response->handle_id,
		postal_info => [
			XML::EPP::Contact::PostalInfo->new(
				name => $response->name,
				addr => XML::EPP::Contact::Addr->new(
					%addr,
				),
                type => "int",
			),
		],
		roid => $roid,
		$self->_maybe_phone_number($response->phone, "voice"),
		$self->_maybe_phone_number($response->fax, "fax"),
		email => $response->email,
		created => $response->created_date->timestamptz,
		client_id => zero_pad($response->registrar_id),
		creator_id => zero_pad($response->registrar_id),
		status => [XML::EPP::Contact::Status->new(status => 'ok')],
		(
			$contact_updated
			? (
				updated_by_id => zero_pad(
					$response->audit->registrar_id,
				),
				updated => $response->audit->when->begin->timestamptz,
				)
			: ()
		),
	);

	return $self->make_response(
		code => 1000,
		payload => $r,
	);
}

sub _maybe_phone_number {
	my $self = shift;
	my $srs_number = shift;
	my $field_name = shift;
	if ( !$srs_number ) {
		return ();
	}
	else {
		my $e164 = $self->_translate_phone_number($srs_number);
		return ($field_name => $e164);
	}
}

# Translate a SRS number to an EPP number
sub _translate_phone_number {
	my $self = shift;
	my $srs_number = shift;

	# The SRS local number field can contain anything
	# alphanumeric. We grab anything numeric from the beginning of
	# the string (including spaces, dashes, etc. which we strip
	# out) and call that part the phone number.  Anything after
	# that goes into the 'x' field of the E164 object.
	$srs_number->subscriber =~ m{(^[\d\s\-\.]*)(.*?)$};
	my ($local_number, $x) = ($1, $2);

	# If we didn't get anything assigned to either field, our
	# regex could be wrong. Just stick the whole thing in $x
	$x = $srs_number->subscriber unless $local_number || $x;

	# Strip out anything non-numeric from $local_number
	$local_number =~ s/[^\d]//g;

	my $global_number = "+" . $srs_number->cc . "."
		. $srs_number->ndc . $local_number;

	return XML::EPP::Contact::E164->new(
		content => $global_number,
		(
			$x ? (x => $x) : (),
		),
	);
}

1;
