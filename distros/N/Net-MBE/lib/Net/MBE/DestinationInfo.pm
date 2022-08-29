# DestinationInfo
# ------------------
# To be used with ShippingOptions request, thru ShippingParameters class.
# Mandatory fields:
#	zipCode, country
package Net::MBE::DestinationInfo {
    use Moo;
    use namespace::clean;
    use SOAP::Lite;
    use Arthas::Defaults::520;

    # Mandatory fields
	has zipCode => ( is => 'rw' );
	has country => ( is => 'rw' );

	# Optional fields
	has city => ( is => 'rw' );
	has state => ( is => 'rw' );
	has idSubzone => ( is => 'rw', default => sub { -1 } );

	sub BUILD($class, $args) {
        croak 'Provide-zipCode' if !$args->{zipCode};
        croak 'Provide-country' if !$args->{country};
	}

    sub getSoapParams($self) {
        my @fields = (
            SOAP::Data->name('ZipCode' => $self->zipCode),
            SOAP::Data->name('Country' => $self->country),
        );
        if ( $self->city ) { push @fields, SOAP::Data->name('City' => $self->city); }
        if ( $self->state ) { push @fields, SOAP::Data->name('State' => $self->state); }
        if ( $self->idSubzone ) { push @fields, SOAP::Data->name('idSubZone' => $self->idSubzone); }
        return \SOAP::Data->value(@fields);
    }
}

1;