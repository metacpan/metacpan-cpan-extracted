package Net::Azure::NotificationHubs;
use 5.008001;
use strict;
use warnings;
use Net::Azure::Authorization::SAS;
use Net::Azure::NotificationHubs::Request;
use JSON;
use HTTP::Tiny;
use URI;
use Carp;
use String::CamelCase qw/camelize wordsplit/;
use Class::Accessor::Lite (
    new => 0,
    ro  => [qw[
        agent
        serializer
        api_version
        authorizer
        apns_expiry
        hub_name
    ]],
);

our $VERSION             = "0.11";
our $DEFAULT_API_VERSION = "2015-04";
our $DEFAULT_TIMEOUT     = 60;

sub new {
    my ($class, %param) = @_;
    
    $param{agent}         = HTTP::Tiny->new(agent => sprintf('%s/%s', $class, $VERSION));
    $param{serializer}    = JSON->new->utf8(1);
    $param{api_version} ||= $DEFAULT_API_VERSION || croak 'api_version is required';

    if (!defined $param{authorizer}) {
        $param{authorizer} = eval {
            Net::Azure::Authorization::SAS->new(connection_string => $param{connection_string});
        };
        if ($@) {
            croak $@;
        };
    }

    bless {%param}, $class;
} 

sub _uri {
    my ($self, $path, %params) = @_;
    $path ||= '/';
    my $uri = URI->new($self->authorizer->endpoint);
    $uri->scheme('https');
    $uri->path($path);
    $uri->query_form(%params);
    $uri;
}

sub _req {
    my ($self, $path, $payload, %params) = @_;
    croak 'path is reuired'        if !defined $path;
    croak 'payload is required'    if !defined $payload;
    croak 'payload is not hashref' if ref($payload) ne 'HASH';
    $params{api_version} ||= $self->api_version;
    my $uri  = $self->_uri($path, %params);
    my $auth = $self->authorizer->token($uri->as_string);
    my $data = $self->serializer->encode($payload);
    my $req  = Net::Azure::NotificationHubs::Request->new(
        POST => $uri->as_string,
        { 
            'Authorization' => $auth,
            'Content-Type'  => 'application/atom+xml;charset=utf-8',
        },
        $data,
    );
    $req->agent($self->agent);
    $req;
}

sub send {
    my ($self, $payload, %param) = @_;
    my $path = sprintf "/%s/messages/", $self->hub_name;
    my $req = $self->_req($path, $payload);
    for my $key (keys %param) {
        next if !defined $param{$key};
        my $header_name = join('-', 'ServiceBusNotification', wordsplit(camelize($key)));
        $req->header($header_name => $param{$key});
    }
    if ($param{format} eq 'apple') {
        $req->header('ServiceBusNotification-Apns-Expiry' => $self->apns_expiry);
    }
    $req;
}


1;
__END__

=encoding utf-8

=head1 NAME

Net::Azure::NotificationHubs - A Client Class for Azure Notification Hubs 

=head1 SYNOPSIS

    use Net::Azure::NotificationHubs;
    my $nh = Net::Azure::NotificationHubs->new(
        connection_string => 'Endpoint=sb://...',
        hub_name          => 'myhub',
        apns_expiry       => '2017-10-10T00:00+09:00',
    );
    ## or use Net::Azure::Authorization::SAS for Authorization
    my $sas = Net::Azure::Authorization::SAS->new(connection_string => 'Endpoint=sb://...');
    $nh = Net::Azure::NotificationHubs->new(
        authorizer  => $sas
        hub_name    => 'myhub',
        apns_expiry => '2017-10-10T00:00+09:00',
    );
    ## send to apple push notification service
    my $payload = {aps => {alert => "Hello, Notification Hubs!"}};
    my $req = $nh->send($payload, format => 'apple');
    my $res = $req->do;
    ## send to google cloud messaging with tag specification
    my $payload = {data => {message => "Hello, Notification Hubs!"}};
    my $req = $nh->send($payload, format => 'gcm', tags => 'TargetId=12345');
    my $res = $req->do;


=head1 DESCRIPTION

Net::Azure::NotificationHubs is a cliant class for Azure Notification Hubs.

If you want to know more information about Azure Notification Hubs, please see L<https://msdn.microsoft.com/en-us/library/dn223264.aspx>. 

=head1 METHODS

=head2 new

    my $eh = Net::Azure::NotificationHubs->new(
        connection_string => 'Endpoint=sb://...',
        hub_name          => 'muhub',
        apns_expiry       => '2017-10-10T00:00+09:00',
    );

A constructor method.  

=over 4

=item connection_string

A string of 'CONNECTION STRING–PRIMARY KEY' or 'CONNECTION STRING–SECONDARY KEY' on the 'Shared access policies' blade of Event Hubs in Microsoft Azure Portal 

=item hub_name

A name string of Notification Hubs entity

=item apns_expiry (optional)

An expire time of the certification for APNS Notification that revealed from Apple.  

=back

=head2 send 

    my $req = $nh->send($payload, %param);
    $req->do;

Returns an object of Net::Azure::NotificationHubs::Reqest.

Send a message that contains specified payload to Azure Notification Hubs when do() method is called.

$payload is a hashref.

%param may be contains following parameters.

=over 4

=item tags

Set specified value to 'ServiceBusNotification-Tags' header.

=item format

Set specified value to 'ServiceBusNotification-Format' header.

=back

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

