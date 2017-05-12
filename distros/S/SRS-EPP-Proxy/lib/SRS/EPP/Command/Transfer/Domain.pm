
package SRS::EPP::Command::Transfer::Domain;
{
  $SRS::EPP::Command::Transfer::Domain::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Transfer';

use MooseX::Params::Validate;
use Moose::Util::TypeConstraints();
use SRS::EPP::Session;
use XML::EPP::Domain;
use XML::SRS::TimeStamp;
use XML::SRS::Types;

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

	my $op = $message->argument->op;

	if ($op eq 'request') {
		# Get the auth info (could do some more validation here...)
		my $auth = $payload->auth_info();
		my $pass = $auth->pw();
		my $udaiType = Moose::Util::TypeConstraints::find_type_constraint("XML::SRS::UDAI");
		if ( !$udaiType->check($pass->content()) ) {
			return $self->make_response(code => 2202);
		}
		
		my %renew_params;
		if ($payload->period) {
			# If they've provided a period, we need to set the term to the one provided,
			#  and renew the domain
			$renew_params{term} = $payload->period->months;
			$renew_params{renew} = 1;
			$renew_params{cancel} = 0;
		}

		return (
			XML::SRS::Whois->new(
				domain => $payload->name,
				full => 0,
			),
			XML::SRS::Domain::Update->new(
				filter => [$payload->name],
				action_id => $self->client_id || $self->server_id,
				udai => $pass->content(),
				convert_contacts_to_handles => 1,
				%renew_params,
			),
		);
	}
	else {
		my $msg = "This server does not support pending transfers";
		return $self->make_response(code => 2102, extra => $msg);
	}	
}

sub notify {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );       
    
	my $epp = $self->message;
	my $payload = $epp->message->argument->payload;

	for (@$rs) {
		my $message = $_->message;
		my $response = $message->response;

		if ($response) {
			if ( $message->action() eq "Whois" ) {
				if ( $response->status eq "Available" ) {
					return $self->make_response(code => 2303);
				}
			}
			if ( $message->action() eq "DomainUpdate" ) {
				if ( $response->isa("XML::SRS::Domain") ) {
					my $exDate;
					
					# If the domain is PendingRelease, we return the cancelled date as the exDate
					$exDate = $response->cancelled_date if $response->status eq 'PendingRelease';
					
					# If the request updated the period, we return the billed until as the exDate
					$exDate = $response->billed_until if $payload->period;
					
					my $epp_resp = XML::EPP::Domain::Transfer::Response->new(
						name => $response->name,
						trStatus => 'serverApproved',
						requester => $response->registrar_id,
						requested =>
							$response->audit->when->begin->timestamptz,
						action_id =>  $response->registrar_id,
						action_date =>
							$response->audit->when->begin->timestamptz,
						($exDate ? (expiry_date => $exDate->timestamptz) : ()), 
					);

					return $self->make_response(
						code => 1000,
						payload => $epp_resp,
					);
				}
			}
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

	# If we get the below error, it's because we've tried to transfer a domain
	#  the registrar already owns. We don't want to return this to the client.
	foreach my $srs_error (@$srs_errors) {
		if ($srs_error->error_id eq 'CONVERT_TO_HANDLES_ONLY_FOR_TRANSFER') {

			my $epp = $self->message;
			my $message = $epp->message;
			my $payload = $message->argument->payload;

			return $self->make_response(
				Error => (
					code      => 2002,
					exception => XML::EPP::Error->new(
						value  => $payload->name,
						reason =>
							'Cannot transfer a domain you already own',
					),
					)
			);
		}
	}

	return $self->SUPER::make_error_response($srs_errors);
}

1;
