
package SRS::EPP::Command::Delete::Contact;
{
  $SRS::EPP::Command::Delete::Contact::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Delete';

use MooseX::Params::Validate;
use SRS::EPP::Session;
use XML::EPP::Contact;

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
	my $message = $epp->message;

	my $payload = $message->argument->payload;
	my $action_id = $self->client_id || $self->server_id;

	return XML::SRS::Handle::Update->new(
		handle_id => $payload->id,
		action_id => $action_id,
		delete => 1,
	);
}

sub notify{
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );      
    
	my $message = $rs->[0]->message;
	my $response = $message->response;

	if ( !$response ) {

		# That means everything worked
		return $self->make_response(code => 1000);
	}

	return $self->make_response(code => 2400);
}

1;
