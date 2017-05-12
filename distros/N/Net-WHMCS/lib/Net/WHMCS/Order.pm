package Net::WHMCS::Order;
$Net::WHMCS::Order::VERSION = '0.08';

# ABSTRACT: WHMCS API Order

use Moo;
with 'Net::WHMCS::Base';

use Carp 'croak';

sub addorder {
    my ( $self, $params ) = @_;
    $params->{action} = 'addorder';
    foreach my $r (qw/clientid pid/) {
        croak "$r is required." unless exists $params->{$r};
    }
    return $self->build_request($params);
}

sub acceptorder {
    my ( $self, $params ) = @_;
    $params->{action} = 'acceptorder';
    foreach my $r (qw/orderid/) {
        croak "$r is required." unless exists $params->{$r};
    }
    return $self->build_request($params);
}

sub deleteorder {
    my ( $self, $params ) = @_;
    $params->{action} = 'deleteorder';
    croak "orderid is required." unless exists $params->{orderid};
    return $self->build_request($params);
}

sub getproducts {
    my ( $self, $params ) = @_;
    $params->{action} = 'getproducts';
    return $self->build_request($params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::WHMCS::Order - WHMCS API Order

=head1 VERSION

version 0.08

=head2 addorder

	$whmcs->order->addorder({
		clientid => 1,
		pid => 1,
		domain => 'whmcs.com',
		billingcycle => 'monthly',
		...
	});

L<http://docs.whmcs.com/API:Add_Order>

=head2 acceptorder

	$whmcs->order->acceptorder({
		orderid => 1
	});

L<http://docs.whmcs.com/API:Accept_Order>

=head2 deleteorder

	$client->deleteorder({
		orderid => 1
	});

L<http://docs.whmcs.com/API:Delete_Order>

=head2 getproducts

	$client->getproducts();

L<http://docs.whmcs.com/API:Get_Products>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
