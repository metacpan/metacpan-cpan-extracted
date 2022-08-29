# Item
# --------
# To be used with Shipment and ShippingOptions requests.
#
# This class is not meant to be created directly but thru
# the addItem functions of Shipment and ShippintOptions.
#
# Mandatory fields:
#	weight, length, height, width
package Net::MBE::Item {
    use Moo;
    use namespace::clean;
    use SOAP::Lite;
    use Arthas::Defaults::520;

    # Mandatory fields
	has weight => ( is => 'rw' );
	has length => ( is => 'rw' );
	has width => ( is => 'rw' );
	has height => ( is => 'rw' );

	sub BUILD($class, $args) {
        croak 'Provide-weight' if !$args->{weight};
        croak 'Provide-length' if !$args->{length};
        croak 'Provide-width' if !$args->{width};
        croak 'Provide-height' if !$args->{height};
	}

    sub getSoapParams($self) {
        return \SOAP::Data->value(
            SOAP::Data->name('Weight', $self->weight),
            SOAP::Data->name('Dimensions' =>  \SOAP::Data->value(
                SOAP::Data->name('Length', $self->length),
                SOAP::Data->name('Height', $self->height),
                SOAP::Data->name('Width', $self->width),
            )),
        );
    }
}

1;