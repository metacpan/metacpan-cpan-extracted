
package SRS::EPP::Command::Renew::Domain;
{
  $SRS::EPP::Command::Renew::Domain::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Renew';

use MooseX::Params::Validate;
use SRS::EPP::Session;
use XML::EPP::Domain;
use XML::SRS::TimeStamp;

# for plugin system to connect
sub xmlns {
	XML::EPP::Domain::Node::xmlns();
}

use MooseX::TimestampTZ qw(epoch);

sub dates_approx_match {
    my $self = shift;
    
    my ( $domain_date, $txn_date ) = pos_validated_list(
        \@_,
        { isa => 'XML::SRS::TimeStamp' },
        { isa => 'Str' },
    );    
    

	my $domain_epoch = $domain_date->epoch();
	my $txn_epoch = epoch "$txn_date 00:00:00Z";

	my $diff = $domain_epoch - $txn_epoch;
	return abs($diff) < (86400*2);
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

	$session->stalled($self);

	return XML::SRS::Whois->new(
		domain => $payload->name(),
	);
}

has 'billed_until' =>
	is => "rw",
	isa => "XML::SRS::TimeStamp",
	;

sub notify {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );     
    
	my $epp = $self->message;
	my $eppMessage = $epp->message;
	my $eppPayload = $eppMessage->argument->payload;

	my $message = $rs->[0]->message;
	my $response = $message->response or goto error_out;

	if ( !$self->billed_until() ) {

		# This must be a response to our query TXN

		if ( $response->status eq "Available" ) {
			return $self->make_response(
				code => 2303,
			);
		}
		my $billed_until = $response->billed_until
			or goto error_out;

		if (
			!$self->dates_approx_match(
				$billed_until,
				$eppPayload->expiry_date,
			)
			)
		{
			my $current = $billed_until->date;
			my $reason = "Not close enough to current "
				."expiry date ($current)";
			return $self->make_error(
				code => 2304,
				value => $eppPayload->expiry_date,
				reason => $reason,
			);
		}

		$self->billed_until( $response->billed_until() );

		$self->session->stalled(0);

		return XML::SRS::Domain::Update->new(
			filter => [$response->name],
			action_id => $self->client_id || $self->server_id,
			renew => 1,
			term => $eppPayload->period->months,
		);
	}

	# By now, we must be dealing with the response to our update TXN
	if ( $response->can("billed_until") ) {
		my $epp_resp = XML::EPP::Domain::Renew::Response->new(
			name => $response->name,
			expiry_date => $response->billed_until->timestamptz,
		);
		return $self->make_response(
			code => 1000,
			payload => $epp_resp,
		);
	}

error_out:
	return $self->make_response(code => 2400);
}

1;
