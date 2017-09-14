package Net::WHMCS::Order;
$Net::WHMCS::Order::VERSION = '0.09';
# ABSTRACT: WHMCS API Order

use Moo;
with 'Net::WHMCS::Base';

use Carp 'croak';

sub addorder {
    my ($self, $params) = @_;
    $params->{action} = 'AddOrder';
    foreach my $r (qw/clientid pid/) {
        croak "$r is required." unless exists $params->{$r};
    }
    return $self->build_request($params);
}

sub acceptorder {
    my ($self, $params) = @_;
    $params->{action} = 'AcceptOrder';
    foreach my $r (qw/orderid/) {
        croak "$r is required." unless exists $params->{$r};
    }
    return $self->build_request($params);
}

sub deleteorder {
    my ($self, $params) = @_;
    $params->{action} = 'DeleteOrder';
    croak "orderid is required." unless exists $params->{orderid};
    return $self->build_request($params);
}

sub getproducts {
    my ($self, $params) = @_;
    $params->{action} = 'GetProducts';
    return $self->build_request($params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::WHMCS::Order - WHMCS API Order

=head1 VERSION

version 0.09

=head2 addorder

	$whmcs->order->addorder({
		clientid => 1,
		pid => 1,
		domain => 'whmcs.com',
		billingcycle => 'monthly',
		...
	});

L<https://developers.whmcs.com/api-reference/addorder/>

=head2 acceptorder

	$whmcs->order->acceptorder({
		orderid => 1
	});

L<https://developers.whmcs.com/api-reference/acceptorder/>

=head2 deleteorder

	$client->deleteorder({
		orderid => 1
	});

L<https://developers.whmcs.com/api-reference/deleteorder/>

=head2 getproducts

	$client->getproducts();

L<https://developers.whmcs.com/api-reference/getproducts/>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
