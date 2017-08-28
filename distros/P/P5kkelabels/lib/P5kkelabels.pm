package P5kkelabels;
$P5kkelabels::VERSION = '0.02';
use 5.010;

use Moo;
with 'Role::REST::Client';

use constant API_ENDPOINT => 'https://app.pakkelabels.dk/api/public/v2/';


has 'api_user' => (
    is => 'ro',
);

has 'api_key' => (
    is => 'ro',
);

has 'token' => (
    is => 'ro',
    default => sub {
		my $self = shift;
        $self->server(API_ENDPOINT);
        my $result = $self->post('users/login', {api_user => $self->api_user, api_key => $self->api_key});
        return $result->data->{'token'};
    },
    lazy => 1,
);



sub _get  {
    my ( $self, $path, $data ) = @_;
    $data //= {};
    $data->{token} = $self->token;
    $self->get($path, $data);
};

sub _post  {
    my ( $self, $path, $data ) = @_;
    $data //= {};
    $data->{token} = $self->token;
    $self->post($path, $data);
};

sub balance {
    my $self = shift;
    my $result = $self->_get('users/balance');
    return $result->data->{balance};
}

sub pdf {
    my ($self, $id) = @_;
    my $result = $self->_get('shipments/pdf', {id => $id});
    return $result->data->{base64};
}

sub zpl {
    my ($self, $id) = @_;
    my $result = $self->_get('shipments/zpl', {id => $id});
    return $result->data->{base64};
}

sub shipments {
    my ($self, $params) = @_;
    my $result = $self->_get('shipments/shipments', $params);
    return $result->data;
}

sub imported_shipments {
    my ($self, $params) = @_;
    my $result = $self->_get('shipments/imported_shipments', $params);
    return $result->data;
}
sub create_imported_shipment {
    my ($self, $params) = @_;
    my $result = $self->_post('shipments/imported_shipment', $params);
    return $result->data;
}

sub create_shipment {
    my ($self, $params) = @_;
    my $result = $self->_post('shipments/shipment', $params);
    return $result->data;
}

sub create_shipment_own_customer_number {
    my ($self, $params) = @_;
    my $result = $self->_post('shipments/shipment_own_customer_number', $params);
    return $result->data;
}

sub freight_rates {
    my ($self, $params) = @_;
    my $result = $self->_get('shipments/freight_rates', $params);
    return $result->data;
}

sub payment_requests {
    my $self = shift;
    my $result = $self->_get('users/payment_requests');
    return $result->data;
}

sub gls_droppoints {
    my ($self, $params) = @_;
    my $result = $self->_get('shipments/gls_droppoints', $params);
    return $result->data;
}

sub pdk_droppoints {
    my ($self, $params) = @_;
    my $result = $self->_get('shipments/pdk_droppoints', $params);
    return $result->data;
}

sub dao_droppoints {
    my ($self, $params) = @_;
    my $result = $self->_get('shipments/dao_droppoints', $params);
    return $result->data;
}

sub pickup_points {
    my ($self, $params) = @_;
    my $result = $self->_get('pickup_points', $params);
    return $result->data;
}

sub add_to_print_queue {
    my ($self, $shipments) = @_;
    my $result = $self->_post('shipments/add_to_print_queue', {ids => join(',', @$shipments)});
    return $result->data;
}

sub pdf_multiple {
    my ($self, $shipments) = @_;
    my $result = $self->_get('shipments/pdf_multiple', {ids => join(',', @$shipments)});
    return $result->data;
}

1;

=pod

=encoding UTF-8

=head1 NAME

P5kkelabels - API interface to pakkelabels.dk

=head1 VERSION

version 0.02

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 NAME

P5kkelabels - REST API interface

=head1 METHODS

=head2 methods

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

