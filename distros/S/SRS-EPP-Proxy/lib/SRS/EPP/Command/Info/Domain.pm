package SRS::EPP::Command::Info::Domain;
{
  $SRS::EPP::Command::Info::Domain::VERSION = '0.22';
}

use Moose;

extends 'SRS::EPP::Command::Info';

use MooseX::Params::Validate;
use SRS::EPP::Session;
use XML::EPP::Domain;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

use XML::EPP::Common;
use XML::EPP::Domain::NS;
use XML::EPP::Domain::HostAttr;
use XML::SRS::FieldList;
use XML::EPP::DNSSEC::DSData;

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
	my $payload = $epp->message->argument->payload;

	# we're not supporting authInfo, so get out of here with an
	# EPP response
	if ( $payload->has_auth_info ) {
		return $self->make_response(code => 2307);
	}

	my %ddq_fields = map { $_ => 1 }
		qw(delegate registered_date registrar_id billed_until
		audit_text effective_from registrant_contact
		admin_contact technical_contact status locked_date
		changed_by_registrar_id dns_sec cancelled_date);

	# We only want to return name servers if the 'hosts' attribute
	# is 'all' or 'del'
	$ddq_fields{name_servers} = 1
		if $payload->name->hosts eq 'all'
			|| $payload->name->hosts eq 'del';

	return (
		XML::SRS::Whois->new(
			domain => $payload->name->value,
			full => 0,
		),
		XML::SRS::Domain::Query->new(
			domain_name_filter => $payload->name->value,
			field_list => XML::SRS::FieldList->new(
				%ddq_fields,
			),
		),
	);
}

sub notify {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );          
    

	my $whois = $rs->[0]->message->response;
	my $domain = $rs->[1]->message->response;

	# if status is available, then the object doesn't exist
	if ( $whois->status eq 'Available' ) {
		return $self->make_response(code => 2303);
	}

	# if there was no domain, this registrar doesn't have access
	# to it
	unless ($domain) {
		return $self->make_response(code => 2201);
	}

	# we have a domain, therefore we have a full response :)
	# let's do this one bit at a time
	my $payload = $self->message->message->argument->payload;

	my $extension = $self->buildExtensionResponse($domain);

	return $self->make_response(
		code => 1000,
		payload => buildInfoResponse($domain),
		$extension ? (extension => $extension) : (),
	);
}

# Note, this is called by Poll (and should probably be in a role)
#  This means we have to be pretty defensive here - the domain
#  record we're dealing with may not have many fields, so we
#  have to check for the existence of most things
sub buildInfoResponse {
	my $domain = shift;

	# get some things out to make it easier on the eye below
	my $nsList;
	if ( $domain->nameservers ) {
		my @nameservers = map {
			convert_nameserver($_),
		} @{$domain->nameservers->nameservers};

		$nsList = XML::EPP::Domain::NS->new(
			ns => [@nameservers],
		);
	}

	my %contacts;
	for my $type (qw(registrant admin technical)) {
		my $method = 'contact_'.$type;
		my $contact = $domain->$method;

		next unless $contact && $contact->handle_id;

		if ($contact) {
			if ($type eq 'registrant') {
				$contacts{$type} = $contact->handle_id;
			}
			else {
				my $epp_type = $type eq 'technical'
					? 'tech' : $type;
				push @{$contacts{contact}},
					XML::EPP::Domain::Contact->new(
					value => $contact->handle_id,
					type => $epp_type,
					);
			}
		}
	}

	# If the domain's registered date is different to the audit
	#  time, we assume this domain has been updated at least once
	#  (which EPP thinks is important)
	my $domain_updated = 0;
	if (
		$domain->registered_date && 
		$domain->registered_date->timestamptz ne $domain->audit->when->begin->timestamptz
	) {
		$domain_updated = 1;
	}

	## Do we also want to include the auth_info (UDAI) data?
	my $auth_info;
	if ( my $udai = $domain->UDAI() ) {
		$auth_info = XML::EPP::Domain::AuthInfo->new(
			pw => XML::EPP::Common::Password->new(
				content => $udai,
			),
		);
	}
	
	# The 'exDate' we return depends on the domain's status
	my $exDate = $domain->status eq 'PendingRelease' ? $domain->cancelled_date : $domain->billed_until;

	return XML::EPP::Domain::Info::Response->new(
		name => $domain->name,
		roid => substr(md5_hex($domain->name), 0, 12) . '-DOM',
		status => [ getEppStatuses($domain) ],
		%contacts,
		($nsList ? (ns => $nsList) : ()),
		$domain->registrar_id() ? (client_id => sprintf("%03d",$domain->registrar_id())) : (), # clID
		$domain->registered_date() ? (created => ($domain->registered_date())->timestamptz) : (), # crDate
		$exDate ? (expiry_date => $exDate->timestamptz) : (), # exDate
		$domain_updated
		? (
			updated => # upDate
				($domain->audit->when->begin())->timestamptz,
			updated_by_id => # upID
				sprintf("%03d",$domain->audit->registrar_id)
			)
		: (),		
		($auth_info ? (auth_info => $auth_info) : ()),
	);
}

sub buildExtensionResponse {
	my $self = shift;
	my $domain = shift;
		
	if ($self->session->extensions->enabled->{dns_sec} && $domain->dns_sec && $domain->dns_sec->ds_list) {
		my @ds;
		foreach my $srs_ds (@{ $domain->dns_sec->ds_list }) {
			push @ds, XML::EPP::DNSSEC::DSData->new(
				key_tag => $srs_ds->key_tag,
				alg => $srs_ds->algorithm,
				digest_type => $srs_ds->digest_type,
				digest => $srs_ds->digest,
			);
		}
		
		my $response = XML::EPP::DNSSEC::InfoResponse->new(
			ds_data => \@ds,
		);
	}
}

sub getEppStatuses {
	my ($domain) = @_;

	my @status;
	if ( defined $domain->delegate() && $domain->delegate() == 0 ) {
		push @status, 'clientHold';
	}
	if ( $domain->status && $domain->status eq 'PendingRelease' ) {
		push @status, 'pendingDelete';
	}
	if ( defined $domain->locked_date() ) {
		push @status, qw(
			serverDeleteProhibited
			serverRenewProhibited
			serverTransferProhibited
			serverUpdateProhibited
		);
	}

	push @status, 'ok' unless @status;

	return (
		map {
			XML::EPP::Domain::Status->new( status => $_ );
			} @status
	);
}

sub convert_nameserver {
	my $ns = shift;
	my @addr = map { XML::EPP::Host::Address->new($_) }
		grep {defined} (
		$ns->ipv4_addr && +{
			value => $ns->ipv4_addr,
		},
		$ns->ipv6_addr && +{
			value => $ns->ipv6_addr,
			ip => "v6",
		},
		);
	XML::EPP::Domain::HostAttr->new(
		name => $ns->fqdn,
		@addr ? ( addrs => \@addr ) : (),
	);
}

1;
