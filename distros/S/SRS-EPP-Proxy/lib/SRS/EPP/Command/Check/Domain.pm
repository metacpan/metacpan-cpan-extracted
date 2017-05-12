
package SRS::EPP::Command::Check::Domain;
{
  $SRS::EPP::Command::Check::Domain::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Check';
use SRS::EPP::Session;
use XML::EPP::Domain;
use MooseX::Params::Validate;

# for plugin system to connect
sub xmlns {
	XML::EPP::Domain::Node::xmlns();
}

sub multiple_responses { 1 }

sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );     
    
	my $epp = $self->message;
	my $payload = $epp->message->argument->payload;

	my @domains = $payload->names;

	$self->log_info(
		"$self checking domains: @domains",
	);

	return map {
		XML::SRS::Whois->new(
			domain => $_,
			full => 0,
		);
	} @domains;
}

sub notify {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );
    
	my $epp = $self->message;
	my $payload = $epp->message->argument->payload;

	my @response_items;
	my @errors;
	my (@available, @unavailable);
	for my $response (@$rs) {
		my $domain = $response->message->response;

		my $available = $domain->is_available;

		my $name_status = XML::EPP::Domain::Check::Name->new(
			name => $domain->name,
			available => $available,
		);
		if ($available) {
			push @available, $domain->name;
		}
		else {
			push @unavailable, $domain->name;
		}
		my $result = XML::EPP::Domain::Check::Status->new(
			name_status => $name_status,
		);

		push @response_items, $result;

	}
	if (@available) {
		$self->log_info(
			"$self: available: @available",
		);
	}
	if (@unavailable) {
		$self->log_info(
			"$self: unavailable: @unavailable",
		);
	}

	my $r = XML::EPP::Domain::Check::Response->new(
		items => \@response_items,
	);

	return $self->make_response(
		code => 1000,
		payload => $r,
	);

}

1;
