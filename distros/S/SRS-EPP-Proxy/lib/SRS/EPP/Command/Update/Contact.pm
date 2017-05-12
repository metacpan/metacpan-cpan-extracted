package SRS::EPP::Command::Update::Contact;
{
  $SRS::EPP::Command::Update::Contact::VERSION = '0.22';
}

use Moose;

extends 'SRS::EPP::Command::Update';
with 'SRS::EPP::Common::Contact';

use MooseX::Params::Validate;

use feature 'switch';

# for plugin system to connect
sub xmlns {
	return XML::EPP::Contact::Node::xmlns();
}

sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );    
	$self->session($session);

	my $epp = $self->message;
	my $message = $epp->message;
	my $payload = $message->argument->payload;

	# Reject add or remove elements, since those are just statuses
	# which we don't support
	if ( $payload->add || $payload->remove) {
		return $self->make_response(code => 2307);
	}

	# Must supply a change element
	unless ( $payload->change ) {
		return $self->make_response(code => 2002);
	}

	my $contact = $payload->change;

	my $address;
	my $name;
	if ($contact->postal_info) {
		if ( my $resp = $self->validate_contact_postal($contact->postal_info) ) {
			return $resp;
		}

		if ( my $addr = $contact->postal_info->[0]->addr ) {
			$address = $self->translate_address($addr);

			# Blank out any optional fields they didn't provide in
			# the address. Otherwise the original values will be
			# left in by the SRS (EPP considers the address one
			# unit to be replaced)
			for my $field (qw/address2 region postcode/) {
				$address->$field('') unless $address->$field;
			}
		}

		$name = $contact->postal_info->[0]->name;
	}
	if ($contact->voice) {
		if ( my $resp = $self->validate_contact_voice($contact->voice)) {
			return $resp;
		}
	}

	return XML::SRS::Handle::Update->new(
		handle_id => $payload->id,
		action_id => $message->client_id || $self->server_id,
		($name ? (name => $name) : ()),
		($address ? (address => $address) : ()),
		($contact->voice ? (phone => $contact->voice->content) : ()),
		($contact->fax ? (fax => $contact->fax->content) : ()),
		($contact->email ? (email => $contact->email) : ()),
	);
}

sub notify{
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );
        
	return $self->make_response(code => 1000);
}

1;
