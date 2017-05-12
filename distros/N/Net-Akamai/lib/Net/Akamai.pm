package Net::Akamai;

use Moose;

use Moose::Util::TypeConstraints;
use SOAP::Lite;
use Net::Akamai::RequestData;
use Net::Akamai::ResponseData;

=head1 NAME
    
Net::Akamai - Utility to interface with Akamai's API 
    
=head1 SYNOPSIS

 my $data = new Net::Akamai::RequestData(
	email=>'my@email.com', 
	user => 'myuser', 
	pwd => 'mypass'
 );
 $data->add_url('http://www.myurl.com');
 $data->add_url('http://www.myurl.com/somethingelse');
 my $ap = new Net::Akamai(req_data=>$data);
 my $res = $ap->purge;
 
 if (!$res->accepted) {
	die "$res";
 }
 elsif ($res->warning) {
	warn "$res";
 }

=head1 DESCRIPTION

Handles akamai purge request of multiple URLs

Patches welcome for extra functionality

=cut

our $VERSION = '0.15';

=head1 Attributes

=head2 soap_version 

SOAP::Lite version

=cut
has 'soap_version' => (
	is => 'ro', 
	isa => 'Str',
	default => sub { SOAP::Lite->VERSION },
);

=head2 proxy 

akamai purge proxy

=cut
has 'proxy' => (
	is => 'ro',
	isa => 'Str',
	default => 'https://ccuapi.akamai.com:443/soap/servlet/soap/purge',
);

=head2 uri 

akamai purge uri

=cut
has 'uri' => (
	is => 'ro',
	isa => 'Str',
	default => 'http://ccuapi.akamai.com/purge',
);

=head2 soap 

SOAP::Lite object

=cut
has 'soap' => (
	is => 'ro', 
	isa => 'SOAP::Lite',
	lazy_build => 1,
);
sub _build_soap {
	my $self = shift;
	return SOAP::Lite->new(
		proxy => $self->proxy,
		uri => $self->uri,
	);
}

=head2 req_data 

Net::Akamai::RequestData object to hold data associated with an akamai request

=cut
has 'req_data' => (
	is => 'ro', 
	isa => 'Net::Akamai::RequestData',
	handles => [qw/ add_url email user pwd /],
	lazy_build => 1,
);
sub _build_req_data {
	return Net::Akamai::RequestData->new();
}

coerce 'Net::Akamai::ResponseData'
	=> from 'HashRef'
	=> via { Net::Akamai::ResponseData->new($_) };

=head2 res_data

Net::Akamai::ResponseData object holds data associated with an akamai response

=cut
has 'res_data' => (
	is => 'rw', 
	isa => 'Net::Akamai::ResponseData',
	coerce    => 1,
);


=head1 Methods 

=head2 purge 

initiate the purge request

=cut
sub purge {
	my $self = shift;

	my $r = $self->soap->purgeRequest(
		SOAP::Data->name("name" => $self->req_data->user),
		SOAP::Data->name("pwd" => $self->req_data->pwd),
		SOAP::Data->name("network" => $self->req_data->network),
		SOAP::Data->name("opt" => $self->req_data->options),
		SOAP::Data->name("uri" => $self->req_data->urls)
	);

	# store in response object
	my $res = $r->result();
	$self->res_data({
		uri_index => $res->{uriIndex},
		result_code => $res->{resultCode},
		est_time => $res->{estTime},
		session_id => $res->{sessionID},
		result_msg => $res->{resultMsg}, 	
	});

	return $self->res_data();
}

=head1 TODO

=over

=item more tests and doc

=item support to read urls from file 

=item better error checking and failure reporting 

=back

=head1 AUTHOR

John Goulah  <jgoulah@cpan.org>

=head1 CONTRIBUTORS 

Aran Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
