package P5kkelabels;
$P5kkelabels::VERSION = '0.03';
use 5.010;

use Moo;
with qw/
    Role::REST::Client
    Role::REST::Client::Auth::Basic
/;

use constant API_ENDPOINT => 'https://app.pakkelabels.dk/api/public/v3/';


sub products {
    my ($self, $params) = @_;
    my $result = $self->get(API_ENDPOINT . 'products', $params);
    return $result;
}


sub pickup_points {
    my ($self, $params) = @_;
    my $result = $self->get(API_ENDPOINT . 'pickup_points', $params);
    return $result;
}


sub account_balance {
    my $self = shift;
    my $result = $self->get(API_ENDPOINT . 'account/balance');
    return $result;
}


sub account_payment_requests {
    my ($self, $params) = @_;
    my $result = $self->get(API_ENDPOINT . 'account/payment_requests', $params);
    return $result;
}


sub shipment_monitor {
    my ($self, $params) = @_;
    my $result = $self->get(API_ENDPOINT . 'shipment_monitor_statuses', $params);
    return $result;
}


sub return_portals {
    my ($self, $params) = @_;
    my $path = 'return_portals';
    $path .= "/$params->{id}" if defined $params and exists $params->{id};
    my $result = $self->get(API_ENDPOINT . $path);
    return $result;
}


sub return_portal_shipments {
    my ($self, $params) = @_;
    die "No id provided" unless my $id = $params->{id};

    my $path = "return_portals/$id/shipments";
    my $result = $self->get(API_ENDPOINT . $path, $params);
    return $result;
}


sub shipments {
    my ($self, $params) = @_;
    my $path = 'shipments';
    $path .= "/$params->{id}" if defined $params and exists $params->{id};

    my $result = $self->get(API_ENDPOINT . $path);
    return $result;
}


sub create_shipment {
    my ($self, $params) = @_;
    my $result = $self->post(API_ENDPOINT . 'shipments', $params);
    return $result;
}


sub shipment_labels {
    my ($self, $params) = @_;
    die "No id provided" unless $params->{id};

    my $path = "shipments/$params->{id}/labels";
    my $result = $self->get(API_ENDPOINT . $path);
    return $result;
}


sub print_queue_entries {
    my ($self, $params) = @_;
    my $result = $self->get(API_ENDPOINT . 'print_queue_entries');
    return $result;
}


sub imported_shipments {
    my ($self, $params) = @_;
    my $path = 'imported_shipments';
    $path .= "/$params->{id}" if defined $params and exists $params->{id};
    my $result = $self->get(API_ENDPOINT . $path);
    return $result;
}


sub create_imported_shipment {
    my ($self, $params) = @_;
    my $result = $self->post(API_ENDPOINT . 'imported_shipments', $params);
    return $result;
}


sub update_imported_shipment {
    my ($self, $params) = @_;
    my $result = $self->put(API_ENDPOINT . 'imported_shipments', $params);
    return $result;
}


sub delete_imported_shipment {
    my ($self, $params) = @_;
    my $result = $self->delete(API_ENDPOINT . 'imported_shipments', $params);
    return $result;
}


sub labels {
    my ($self, $params) = @_;
    my $path = "labels";
    my $result = $self->get(API_ENDPOINT . $path, $params);
    return $result;
}

1;

=pod

=encoding UTF-8

=head1 NAME

P5kkelabels - API interface to pakkelabels.dk

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

Implements the Pakkelabels.dk API as described in
https://app.pakkelabels.dk/api/public/v3/specification

All methods return a L<Role::REST::Client::Result> object.

=head1 NAME

P5kkelabels - REST API interface

=head1 METHODS

=head2 products

Get available products

=head2 pickup_points

Get available & nearest pickup points

=head2 account_balance

Get current balance

=head2 account_payment_request

Get payment requests

=head2 shipment_monitor

Get shipment monitor statuses

=head2 return_portals

Get return portals

Takes an optional id parameter

=head2 return_portal_shipments

Get Shipments for Return Portal with specific ID

Takes an id parameter

=head2 shipments

Get shipments

Takes an optional id parameter

=head2 create_shipment

Create a shipment

Takes the sipment information as parameter

=head2 shipment_labels

Get Labels for Shipment with specific ID

Takes an id parameter

=head2 print_queue_entries

Get print queue entries

=head2 imported_shipments

Get Imported Shipments

Takes an id parameter

=head2 create_imported_shipment

Create a shipment

Takes the sipment information as parameter

=head2 update_imported_shipment

Update a shipment

Takes the sipment information as parameter

=head2 delete_imported_shipment

Delete a shipment

Takes the sipment information as parameter

=head2 labels

Get Labels for specific ID's

=head1 BUGS

Please report any bugs or feature requests to bug-role-rest-client at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P5kkelabels.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: API interface to pakkelabels.dk

