# ShippingParameters
# ------------------
# To be used with ShippingOptions request.
# Mandatory fields:
#	destinationInfo, shipType, packageType, items
package Net::MBE::ShippingParameters {
	use Moo;
    use namespace::clean;
    use SOAP::Lite;
	use Net::MBE::Item;
    use Arthas::Defaults::520;

	# Mandatory fields
	has destinationInfo => ( is => 'rw' );
	has shipType => ( is => 'rw' );
	has packageType => ( is => 'rw' );
	has items => ( is => 'rw', default => sub { [] } );

	# Optional fields
	has service => ( is => 'rw', default => sub { '' } );
	has courier => ( is => 'rw', default => sub { '' } );
	has courierService => ( is => 'rw', default => sub { '' } );
	has COD => ( is => 'rw' );
	has CODValue => ( is => 'rw', default => sub { 0 } );
	has CODPaymentMethod => ( is => 'rw', default => sub { '' } );
	has insurance => ( is => 'rw' );
	has insuranceValue => ( is => 'rw', default => sub { 0 } );
	has saturdayDelivery => ( is => 'rw' );
	has signatureRequired => ( is => 'rw' );

	sub BUILD($class, $args) {
        croak 'Provide-destinationInfo' if !$args->{destinationInfo};
        croak 'Provide-shipType' if !$args->{shipType};
        croak 'Provide-packageType' if !$args->{packageType};

	}

	sub addItem($self, $args) {
		push @{ $self->items }, Net::MBE::Item->new({
			weight	=> $args->{weight},
			length	=> $args->{length},
			height	=> $args->{height},
			width	=> $args->{width},
		})
	}

	sub getSoapParams($self) {
		my @fields = (
            SOAP::Data->name('DestinationInfo' => $self->destinationInfo->getSoapParams()),
            SOAP::Data->name('ShipType' => $self->shipType),
            SOAP::Data->name('PackageType' => $self->packageType),
        );

		# FIXME/TODO: This is an array of equally named tags, see if it works!!
		my @items;
		for my $item(@{ $self->items }) {
			push @items, SOAP::Data->name('Item' => $item->getSoapParams());
		}
		push @fields, SOAP::Data->name('Items' => \SOAP::Data->value(@items));

        if ( $self->service ) { push @fields, SOAP::Data->name('Service' => $self->service); }
        if ( $self->courier ) { push @fields, SOAP::Data->name('Courier' => $self->courier); }
        if ( $self->courierService ) { push @fields, SOAP::Data->name('CourierService' => $self->courierService); }
        if ( $self->COD ) { push @fields, SOAP::Data->name('COD' => $self->COD); }
        if ( $self->CODValue ) { push @fields, SOAP::Data->name('CODValue' => $self->CODValue); }
        if ( $self->CODPaymentMethod ) { push @fields, SOAP::Data->name('CODPaymentMethod' => $self->CODPaymentMethod); }
        if ( $self->insurance ) { push @fields, SOAP::Data->name('insurance' => $self->insurance); }
        if ( $self->insuranceValue ) { push @fields, SOAP::Data->name('insuranceValue' => $self->insuranceValue); }
        if ( $self->saturdayDelivery ) { push @fields, SOAP::Data->name('saturdayDelivery' => $self->saturdayDelivery); }
        if ( $self->signatureRequired ) { push @fields, SOAP::Data->name('signatureRequired' => $self->signatureRequired); }

        return \SOAP::Data->value(@fields);
	}
}

1;