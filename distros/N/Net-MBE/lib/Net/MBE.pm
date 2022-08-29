=head1 NAME

Net::MBE - Perl library to access Mailboxes Etc (MBE) online webservices.

=head1 SYNOPSIS

    use Net::MBE;
    use Net::MBE::DestinationInfo;
    use Net::MBE::ShippingParameters;

    my $mbe = Net::MBE->new({
        system => 'IT',
        username => 'XXXXX',
        passphrase => 'YYYYYYYY',
    });

    my $dest = Net::MBE::DestinationInfo->new({
        zipCode => '33085',
        country => 'IT', 
        state => 'PN'
    });

    my $shipparams = Net::MBE::ShippingParameters->new({
        destinationInfo => $dest,
        shipType => 'EXPORT',
        packageType => 'GENERIC',
    });
    $shipparams->addItem({
        weight => 1,
        length => 10,
        width  => 10,
        height => 10,
    });

    my $response = $mbe->ShippingOptions({
        internalReferenceID => '48147184XTST',
        shippingParameters => $shipparams,
    });

    use Data::Dump qw/dump/; print dump($response);

=head1 DESCRIPTION

Mailboxes Etc (MBE), formerly a UPS-owned chain of shipping service outlets, is now an Italian
independent company which operates in several european countries.

This library is for accessing their various web services for getting rates, etc.

Currently, ONLY getting shipping rates is implemented.

=head1 AUTHOR

Michele Beltrame, C<arthas@cpan.org>

=head1 LICENSE

This library is free software under the Mozilla Public License 2.0.

=cut

package Net::MBE {
    use Moo;
    use namespace::clean;
    use SOAP::Lite;
    #use SOAP::Lite +trace => [ qw/all -objects/ ];
    use MIME::Base64;
    use HTTP::Headers;
    use Arthas::Defaults::520;
    use version;

    our $VERSION = qv("v0.2.2");

	#$SOAP::Constants::DEFAULT_HTTP_CONTENT_TYPE = 'text/xml';
	#$SOAP::Constants::DO_NOT_USE_CHARSET = 1;

	has system => ( is => 'rw' );
	has endpoint => ( is => 'rw' );
	has credentials => ( is => 'rw' );
	has soapClient => ( is => 'rw' );
    
	# Creates a new instance of WSMBEOnline to access OnlineMBE web services.
	# ----------------------------------------------------------------------
	# Parameters:
	# 	$system		->	one of 'IT', 'ES', 'DE', 'FR', AT'. Allows correct
	# 						selection of OnlineMBE instance and endpoint.
	# 	$username	->	as supplied by MBE franchise.
	# 	$passphrase	->	as supplied by MBE franchise.
	sub BUILD($class, $args) {
		if ($args->{system} eq 'IT') {
			$class->endpoint( 'https://api.mbeonline.it/ws/e-link.wsdl' );
		} elsif ($args->{system} eq 'ES') {
			$class->endpoint( 'https://api.mbeonline.es/ws/e-link.wsdl' );
		} elsif ($args->{system} eq 'DE') {
			$class->endpoint( 'https://api.mbeonline.de/ws/e-link.wsdl' );
		} elsif ($args->{system} eq 'FR') {
			$class->endpoint( 'https://api.mbeonline.fr/ws/e-link.wsdl' );
		} elsif ($args->{system} eq 'PL') {
			$class->endpoint( 'https://api.mbeonline.pl/ws/e-link.wsdl' );
		}
		
        #use Data::Dump qw/dump/; die dump($args->{Username}, $args->{Passphrase});

        my $proxy = $class->{endpoint} =~ s/(\/e-link\.wsdl)$//xsr;
        my $soapClient = SOAP::Lite->new(
            readable   => 0,
            proxy => [
                $proxy,
                # credentials => [
                #     'api.mbeonline.it:443',
                #     undef,
                #     $args->{Username},
                #     $args->{Passphrase},
                # ],
                default_headers => HTTP::Headers->new(
                    'Content-type', 'text/xml; charset=utf-8', # MBE won't accept application/soap
                    'Authorization', 'Basic '.encode_base64($args->{username} . ':' . $args->{passphrase})
                ),
            ],
            #wsdl => $args->{endpoint},
        );

		# Server seems to only support 1.1, or at least only text/xml as content type
        $soapClient->soapversion('1.1');
        $soapClient->serializer->soapversion('1.1');

		$soapClient->ns('http://schemas.xmlsoap.org/soap/envelope/', 'SOAP-ENV');
        $soapClient->ns('http://www.onlinembe.eu/ws/','ns1');
        $soapClient->envprefix('SOAP-ENV');
        $soapClient->autotype(0);

        $class->soapClient($soapClient);
        $class->credentials({'Username' => '', Passphrase => ''});
	}


	# ShippingOptionsRequest
	# ----------------------
	# Gets shipping options for an indicated shipment parameters.
	#	$internalReferenceID	->	string that is returned as is by the server.
	#	$shippingParameters		->	object of type ShippingParameters with all
	#									the required info.
	sub ShippingOptions($self, $args) {
		croak 'Invalid-internalReferenceID' if !$args->{internalReferenceID};

        my $params = SOAP::Data->name('RequestContainer' => \SOAP::Data->value(
            SOAP::Data->name('System' => $self->system),
            SOAP::Data->name('Credentials' => \SOAP::Data->value(
                SOAP::Data->name('Username' => ''),
                SOAP::Data->name('Passphrase' => ''),
            )),
            SOAP::Data->name('InternalReferenceID', $args->{internalReferenceID}),
			SOAP::Data->name('ShippingParameters' => $args->{shippingParameters}->getSoapParams()),
        ));

        my $som = $self->soapClient->call("ShippingOptionsRequest", $params);
		croak 'Invalid-request' if !$som;
    	croak 'Request error: '.$som->fault->{ faultstring } if $som->fault;
		return $som->body->{ShippingOptionsRequestResponse}->{RequestContainer};
	}
}

1;
