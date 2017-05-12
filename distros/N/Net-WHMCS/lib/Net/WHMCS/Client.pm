package Net::WHMCS::Client;
$Net::WHMCS::Client::VERSION = '0.08';

# ABSTRACT: WHMCS API Clients

use Moo;
with 'Net::WHMCS::Base';

use Carp 'croak';

sub getclientsdetails {
    my ( $self, $params ) = @_;
    $params->{action} = 'getclientsdetails';
    return $self->build_request($params);
}

sub addclient {
    my ( $self, $params ) = @_;
    $params->{action} = 'addclient';
    return $self->build_request($params);
}

sub updateclient {
    my ( $self, $params ) = @_;
    $params->{action} = 'updateclient';
    return $self->build_request($params);
}

sub deleteclient {
    my ( $self, $params ) = @_;
    $params->{action} = 'deleteclient';
    return $self->build_request($params);
}

sub closeclient {
    my ( $self, $params ) = @_;
    $params->{action} = 'closeclient';
    return $self->build_request($params);
}

sub getclients {
    my ( $self, $params ) = @_;
    $params ||= {};
    $params->{action} = 'getclients';
    return $self->build_request($params);
}

sub getclientpassword {
    my ( $self, $params ) = @_;
    $params->{action} = 'getclientpassword';
    return $self->build_request($params);
}

sub getclientsproducts {
    my ( $self, $params ) = @_;
    $params ||= {};
    $params->{action} = 'getclientsproducts';
    return $self->build_request($params);
}

sub updateclientproduct {
    my ( $self, $params ) = @_;
    $params ||= {};
    $params->{action} = 'updateclientproduct';
    croak 'serviceid is required.' unless $params->{serviceid};
    return $self->build_request($params);
}

sub upgradeproduct {
    my ( $self, $params ) = @_;
    $params ||= {};
    $params->{action} = 'upgradeproduct';
    foreach my $r (
        qw/clientid serviceid type newproductid newproductbillingcycle paymentmethod/
      )
    {
        croak "$r is required." unless $params->{$r};
    }
    return $self->build_request($params);
}

sub validatelogin {
    my ( $self, $params ) = @_;
    $params ||= {};
    $params->{action} = 'validatelogin';
    croak 'email is required.'    unless $params->{email};
    croak 'password2 is required' unless $params->{password2};
    return $self->build_request($params);
}

sub sendemail {
    my ( $self, $params ) = @_;
    $params ||= {};
    $params->{action} = 'sendemail';
    return $self->build_request($params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::WHMCS::Client - WHMCS API Clients

=head1 VERSION

version 0.08

=head2 getclientsdetails

	$client->getclientsdetails({
		clientid => 1,
		stats => 'true',
	})

L<http://docs.whmcs.com/API:Get_Clients_Details>

=head2 addclient

	$client->addclient({
		firstname => 'first',
		lastname => 'last',
		email => 'blabla@balbla.com',
		...
	})

L<http://docs.whmcs.com/API:Add_Client>

=head2 updateclient

	$client->updateclient({
		clientid => 1,
		firstname => 'first',
		lastname => 'last',
		email => 'blabla@balbla.com',
		...
	})

L<http://docs.whmcs.com/API:Update_Client>

=head2 deleteclient

	$client->deleteclient({
		clientid => 1
	})

L<http://docs.whmcs.com/API:Delete_Client>

=head2 closeclient

	$client->closeclient({
		clientid => 1
	})

L<http://docs.whmcs.com/API:Close_Client>

=head2 getclients

	$client->getclients()

L<http://docs.whmcs.com/API:Get_Clients>

=head2 getclientpassword

	$client->getclientpassword({
		userid => 1
	})

L<http://docs.whmcs.com/API:Get_Clients_Password>

=head2 getclientsproducts

	$client->getclientsproducts({
		clientid => 1
	})

L<http://docs.whmcs.com/API:Get_Clients_Products>

=head2 updateclientproduct

	$client->getclientsproducts({
		serviceid => 1,
		...
	});

L<http://docs.whmcs.com/API:Update_Client_Product>

=head2 upgradeproduct

	$client->upgradeproduct({
		clientid => 1,
		serviceid => 1,
		type => 'product',
		newproductid => 18,
		newproductbillingcycle => 'monthly',
		paymentmethod => 'paypal'
	});

L<http://docs.whmcs.com/API:Upgrade_Product>

=head2 validatelogin

	$client->validatelogin({
		email => 'user@domain.com',
		password2 => 'abc123'
	});

L<http://docs.whmcs.com/API:Validate_Login>

=head2 sendemail

	$client->sendemail({
		id => 1,
		messagename => 'blabla'
	})

L<http://docs.whmcs.com/API:Send_Email>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
