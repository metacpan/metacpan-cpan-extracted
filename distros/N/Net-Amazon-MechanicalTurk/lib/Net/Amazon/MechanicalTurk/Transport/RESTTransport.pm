package Net::Amazon::MechanicalTurk::Transport::RESTTransport;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::BaseObject;
use Net::Amazon::MechanicalTurk::Transport;
use Net::Amazon::MechanicalTurk::DataStructure;
use LWP 6;
use LWP::UserAgent 6;
use LWP::Protocol::https 6;
use HTTP::Request::Common;
use Mozilla::CA;
use Net::SSLeay 1.33;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::Transport };

Net::Amazon::MechanicalTurk::Transport::RESTTransport->attributes(qw{
    userAgent
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    my $softwareName = "MTurkPerlSDK/" . $Net::Amazon::MechanicalTurk::VERSION;
    if (!defined($self->userAgent)) {
        $self->userAgent(LWP::UserAgent->new());
        $self->userAgent->agent(
            $softwareName .
            " " .
            $self->userAgent->_agent
        );
    }
    $self->userAgent->default_headers->push_header(
        'X-Amazon-Software' => $softwareName
    );
}

sub call {
    my ($self, $client, $operation, $params) = @_;

    my $httpParams = Net::Amazon::MechanicalTurk::DataStructure->toProperties($params);

    if ($self->debug) {
        $self->debugMessage("Calling url " . $client->serviceUrl . " with parameters:");
        foreach my $key (sort keys %$httpParams) {
            $self->debugMessage("    [$key] = [$httpParams->{$key}]");
        }
    }

    my $hostname = 'invalid';
    if($client->serviceUrl =~ /([^:]*:\/\/)?([^\/]+\.[^\/]+)/g) {
      $hostname = $2;
    }
    if($hostname eq 'invalid') {
      die "Invalid service url"
    }

    my $request = POST $client->serviceUrl, $httpParams ;
    $request->header("If-SSL-Cert-Subject" => "/CN=$hostname");
    my $response = $self->userAgent->request($request);

    if ($self->debug) {
        $self->debugMessage("HTTP Response " . $response->status_line);
        $self->debugMessage($response->headers->as_string);
        $self->debugMessage("HTTP Content:");
        $self->debugMessage($response->content);
    }

    if (!$response->is_success) {
        # ServiceUnavailable errors have an XML response and come back as a 503.
        if ($response->code eq "503" and $response->content =~ /<\s*Errors\s*>/s) {
            return $response->content;
        }
        die "HTTP Error calling $operation - " . $response->status_line;
    }

    return $response->content;
}

return 1;
