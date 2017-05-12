# NAME

Redmine::Fetch - It's new $module

# SYNOPSIS

    use Redmine::Fetch;

    my $rf = Redmine::Fetch->new( $server_uri, $api_key, $project_id, $filter);
    my $ticket = $rf->get_ticket_by_id(555);

# DESCRIPTION

This module provides API access to the Redmine REST API

Please reference the Redmine API docs to determine Parameters for Filters etc.

You can find the docs here: http://www.redmine.org/projects/redmine/wiki/Rest\_api

## new

Creates a new Object. Handle over the Redmine Config

- param: $api\_key String - API Key for Redmine
- param: $project\_id Integer - Redmine Project ID
- param: $filter String - Redmine filter string
- returns: $self Object - Redmine::Fetch object

## ua\_config

Returns a config hashref for the Redmine REST API.

- returns: $c Hash - Config Hash for the Redmine REST API

## redmine\_ua

Redmine Useragent. Abstracts PUT und GET Requests for the Redmine Rest API. Will dump errors per Data::Printer

- param: $mode String - 'get' || 'put' || 'delete' || 'post'
- param: $call String - calling API path
- param: $payload Hash || JSON - payload for PUT or GET request
- returns: $response Mojo::UserAgent Response - Antwort Objekt der Transaktion oder leerer String

## update\_or\_create\_wiki\_page

Update or create Wiki pages in Redmine Wiki

- param: $path String - Path to Wiki page
- param: $name String - name of Wiki page
- param: $content String - Content of the Wiki Page in Textile Markup
- param: $parent\_titel - Title of the parent Wiki Page
- returns: $response Mojo::UserAgent Response - Server answer, for further processing or empty String

## delete\_wiki\_page

deletes Wiki Page

- param: $path String - path to delete
- returns: $response Mojo::UserAgent Response - Server answer, for further processing or empty String

## create\_ticket

create ticket in Redmine Tracker

- param: $subject String - Subject of the Ticket
- param: $description String - Description of the Ticket
- param: $payload String - additional Ticket parameters as a hash (e.g. tracker\_id, priority, etc.)
- returns: $response Mojo::UserAgent Response - Server answer, for further processing or empty String

## delete\_ticket

delete a ticket in the Redmine Tracker

- param: $ticket\_id Integer - Ticket ID of the Redmine Ticket
- returns: $response Mojo::UserAgent Response - Server answer, for further processing or empty String

## get\_tickets

get list of Tickets

- param: $type String - Tracker Typ - e.g. \[ bugs, features, updates, faq \]
- param: $limit Scalar - maximal number of Listitems - default 500
- param: $sort String - sort for Redmine API as String
- returns: $ticket Hash - From json decoded hashref with ticket\_data

## get\_ticket\_by\_id

gets a Ticket by ID including the related Tickets

- param: $ticket\_id Scalar - Ticket ID in Redmine
- param: $build\_link\_callback - Anonymus function for URI generating
- returns: $ticket Hash - From json decoded hashref with ticket\_data

# LICENSE

Copyright (C) Jens Gassmann Software Entwicklung.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

- Jens Gassmann <jg@itnode.de>
- Patrick Simon <ps@itnode.de>
