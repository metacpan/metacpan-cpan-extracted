[![Build Status](https://travis-ci.org/ytnobody/p5-Net-Azure-NotifcationHubs.svg?branch=master)](https://travis-ci.org/ytnobody/p5-Net-Azure-NotifcationHubs)
# NAME

Net::Azure::NotificationHubs - A Client Class for Azure Notification Hubs 

# SYNOPSIS

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

# DESCRIPTION

Net::Azure::NotificationHubs is a cliant class for Azure Notification Hubs.

If you want to know more information about Azure Notification Hubs, please see [https://msdn.microsoft.com/en-us/library/dn223264.aspx](https://msdn.microsoft.com/en-us/library/dn223264.aspx). 

# METHODS

## new

    my $eh = Net::Azure::NotificationHubs->new(
        connection_string => 'Endpoint=sb://...',
        hub_name          => 'muhub',
        apns_expiry       => '2017-10-10T00:00+09:00',
    );

A constructor method.  

- connection\_string

    A string of 'CONNECTION STRING–PRIMARY KEY' or 'CONNECTION STRING–SECONDARY KEY' on the 'Shared access policies' blade of Event Hubs in Microsoft Azure Portal 

- hub\_name

    A name string of Notification Hubs entity

- apns\_expiry (optional)

    An expire time of the certification for APNS Notification that revealed from Apple.  

## send 

    my $req = $nh->send($payload, %param);
    $req->do;

Returns an object of Net::Azure::NotificationHubs::Reqest.

Send a message that contains specified payload to Azure Notification Hubs when do() method is called.

$payload is a hashref.

%param may be contains following parameters.

- tags

    Set specified value to 'ServiceBusNotification-Tags' header.

- format

    Set specified value to 'ServiceBusNotification-Format' header.

head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
