
package SRS::EPP::Command::Delete::Domain;
{
  $SRS::EPP::Command::Delete::Domain::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Delete';

use MooseX::Params::Validate;
use SRS::EPP::Session;
use XML::EPP::Domain;

# for plugin system to connect
sub xmlns {
	XML::EPP::Domain::Node::xmlns();
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

	return XML::SRS::Domain::Update->new(
		filter => [$payload->name],
		action_id => $action_id,
		cancel => 1,
		full_result => 0,
	);
}

sub notify {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );
    
	my $message = $rs->[0]->message;
	my $response = $message->response;

	if ( !$response ) {

		# Lets just assume the domain doesn't exist
		return $self->make_response(code => 2303);
	}
	if ( $response->can("status") ) {
		if ( $response->status eq "Available" || $response->status eq 'PendingRelease' ) {
			return $self->make_response(code => 1000);
		}
	}
	return $self->make_response(code => 2400);
}

sub make_error_response {
    my $self = shift;
    
    my ( $srs_errors ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[XML::SRS::Error]' },
    );    
    

	# If we get an error about a missing UDAI, then this must be a
	#   domain the registrar doesn't own. Return an appropriate
	#   epp error
	foreach my $srs_error (@$srs_errors) {
		if ($srs_error->error_id eq 'MISSING_MANDATORY_FIELD') {
			if ($srs_error->details && $srs_error->details->[0] eq 'UDAI') {
				return $self->make_error(
					code    => 2201,
					message => 'Authorization Error',
				);
			}
		}
	}

	return $self->SUPER::make_error_response($srs_errors);
}

1;
