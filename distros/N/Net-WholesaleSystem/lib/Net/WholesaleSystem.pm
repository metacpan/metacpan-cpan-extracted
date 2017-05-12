package Net::WholesaleSystem;

BEGIN {
    $Net::WholesaleSystem::VERSION = '0.01';
}

# ABSTRACT: VentraIP Wholesale SSL API

use warnings;
use strict;
use Carp qw/croak/;
use SOAP::Lite;
use vars qw/$errstr/;

my %product_id = (
    'Trustwave Domain Validated SSL - 1 Year' => 55,
    'Trustwave Domain Validated SSL - 2 Year' => 56,
    'Trustwave Domain Validated SSL - 3 Year' => 57,
    'Trustwave Premium SSL - 1 year'          => 58,
    'Trustwave Premium SSL - 2 year'          => 59,
    'Trustwave Premium SSL - 3 year'          => 60,
    'Trustwave Enterprise SSL - 1 Year'       => 61,
    'Trustwave Enterprise SSL - 2 Year'       => 62,
    'Trustwave Enterprise SSL - 3 Year'       => 63,
    'Trustwave Premium Wildcard SSL - 1 Year' => 64,
    'Trustwave Premium Wildcard SSL - 2 Year' => 65,
    'Trustwave Premium Wildcard SSL - 3 Year' => 66,
    'Trustwave Premium EV SSL - 1 Year'       => 67,
    'Trustwave Premium EV SSL - 2 Year'       => 68
);

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : {@_};

    # validate
    $args->{resellerID} or croak 'resellerID is required';
    $args->{apiKey}     or croak 'apiKey is required';

    if ( $args->{is_ote} ) {
        $args->{url} ||= 'https://api-ote.wholesalesystem.com.au/?wsdl';
    }
    else {
        $args->{url} ||= 'https://api.wholesalesystem.com.au/?wsdl';
    }

    SOAP::Trace->import('all') if $args->{debug};

    # Init SOAP
    $SOAP::Constants::PREFIX_ENV = 'SOAP-ENV';
    my $soap = SOAP::Lite

      #->readable(1)
      ->ns( '', 'ns1' )->ns( 'http://xml.apache.org/xml-soap', 'ns2' )
      ->proxy( $args->{url} );

    #    $soap->outputxml('true'); # XML
    $soap->on_action( sub { qq("#$_[0]") } );
    $args->{soap} = $soap;

    bless $args, $class;
}

sub errstr { $errstr }

sub _check_soap {
    my ($som) = @_;

    if ( $som->fault ) {
        $errstr = $som->faultstring;
        return;
    }

    if ( $som->result and exists $som->result->{errorMessage} ) {
        $errstr = $som->result->{errorMessage};
        return;
    }

    return 1;
}

sub balanceQuery {
    my ($self) = @_;

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name('balanceQuery')->prefix('ns1');

    # the XML elements order matters
    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );

    my $som = $soap->call(
        $method,
        SOAP::Data->name(
            param0 => \SOAP::Data->value( $ele_resellerID, $ele_apiKey )
          )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result->{balance};
}

sub purchaseSSLCertificate {
    my $self = shift;

    my $args = scalar @_ % 2 ? shift : {@_};
    if ( exists $product_id{ lc $args->{product_id} } ) {
        $args->{product_id} = $product_id{ lc $args->{product_id} };
    }

    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );

    my @args = ( $ele_resellerID, $ele_apiKey );
    foreach my $k (
        qw/csr productID firstName lastName emailAddress address city state postCode country phone fax/
      )
    {
        push @args,
          SOAP::Data->name('item')
          ->type( ordered_hash => [ key => $k, value => $args->{$k} ] );
    }

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name('SSL_purchaseSSLCertificate')->prefix('ns1');
    my $som    = $soap->call( $method,
        SOAP::Data->name( param0 => \SOAP::Data->value(@args) )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

sub renewSSLCertificate {
    my $self = shift;

    my $args = scalar @_ % 2 ? shift : {@_};

    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );

    my @args = ( $ele_resellerID, $ele_apiKey );
    foreach my $k (
        qw/certID firstName lastName emailAddress address city state postCode country phone fax/
      )
    {
        push @args,
          SOAP::Data->name('item')
          ->type( ordered_hash => [ key => $k, value => $args->{$k} ] );
    }

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name('SSL_renewSSLCertificate')->prefix('ns1');
    my $som    = $soap->call( $method,
        SOAP::Data->name( param0 => \SOAP::Data->value(@args) )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

sub reissueCertificate {
    my ( $self, $certID, $newCSR ) = @_;

    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );
    my $ele_certID =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'certID', value => $certID ] );
    my $ele_newCSR =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'newCSR', value => $newCSR ] );

    my @args = ( $ele_resellerID, $ele_apiKey, $ele_certID, $ele_newCSR );

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name('SSL_reissueCertificate')->prefix('ns1');
    my $som    = $soap->call( $method,
        SOAP::Data->name( param0 => \SOAP::Data->value(@args) )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

sub generateCSR {
    my $self = shift;

    my $args = scalar @_ % 2 ? shift : {@_};

    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );

    my @args = ( $ele_resellerID, $ele_apiKey );
    foreach my $k (
        qw/numOfYears country state city organisation organisationUnit commonName emailAddress/
      )
    {
        push @args,
          SOAP::Data->name('item')
          ->type( ordered_hash => [ key => $k, value => $args->{$k} ] );
    }

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name('SSL_generateCSR')->prefix('ns1');
    my $som    = $soap->call( $method,
        SOAP::Data->name( param0 => \SOAP::Data->value(@args) )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

sub decodeCSR {
    my ( $self, $csr ) = @_;

    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );
    my $ele_csr =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'csr', value => $csr ] );

    my @args = ( $ele_resellerID, $ele_apiKey, $ele_csr );

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name('SSL_decodeCSR')->prefix('ns1');
    my $som    = $soap->call( $method,
        SOAP::Data->name( param0 => \SOAP::Data->value(@args) )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

sub getSSLCertificate {
    my ( $self, $certID ) = @_;
    $self->_actSSLCertificate( 'SSL_getSSLCertificate', $certID );
}

sub getCertSimpleStatus {
    my ( $self, $certID ) = @_;
    $self->_actSSLCertificate( 'SSL_getCertSimpleStatus', $certID );
}

sub cancelSSLCertificate {
    my ( $self, $certID ) = @_;
    $self->_actSSLCertificate( 'SSL_cancelSSLCertificate', $certID );
}

sub resendDVEmail {
    my ( $self, $certID ) = @_;
    $self->_actSSLCertificate( 'SSL_resendDVEmail', $certID );
}

sub resendIssuedCertificateEmail {
    my ( $self, $certID ) = @_;
    $self->_actSSLCertificate( 'SSL_resendIssuedCertificateEmail', $certID );
}

sub _actSSLCertificate {
    my ( $self, $act, $certID ) = @_;

    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );
    my $ele_certID =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'certID', value => $certID ] );
    my @args = ( $ele_resellerID, $ele_apiKey, $ele_certID );

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name($act)->prefix('ns1');
    my $som    = $soap->call( $method,
        SOAP::Data->name( param0 => \SOAP::Data->value(@args) )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

sub listAllCerts {
    my ($self) = @_;

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name('SSL_listAllCerts')->prefix('ns1');

    # the XML elements order matters
    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );

    my $som = $soap->call(
        $method,
        SOAP::Data->name(
            param0 => \SOAP::Data->value( $ele_resellerID, $ele_apiKey )
          )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

sub getDomainBeacon {
    my ( $self, $certID, $domainName ) = @_;
    $self->_actDomainBeacon( 'SSL_getDomainBeacon', $certID, $domainName );
}

sub checkDomainBeacon {
    my ( $self, $certID, $domainName ) = @_;
    $self->_actDomainBeacon( 'SSL_checkDomainBeacon', $certID, $domainName );
}

sub _actDomainBeacon {
    my ( $self, $act, $certID, $domainName ) = @_;

    my $ele_resellerID =
      SOAP::Data->name('item')
      ->type(
        ordered_hash => [ key => 'resellerID', value => $self->{resellerID} ] );
    my $ele_apiKey =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'apiKey', value => $self->{apiKey} ] );
    my $ele_certID =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'certID', value => $certID ] );
    my $ele_domainName =
      SOAP::Data->name('item')
      ->type( ordered_hash => [ key => 'domainName', value => $domainName ] );

    my @args = ( $ele_resellerID, $ele_apiKey, $ele_certID, $ele_domainName );

    my $soap   = $self->{soap};
    my $method = SOAP::Data->name($act)->prefix('ns1');
    my $som    = $soap->call( $method,
        SOAP::Data->name( param0 => \SOAP::Data->value(@args) )->type('ns2:Map')
    );

    _check_soap($som) or return;

    return $som->result;
}

1;

=pod

=head1 NAME

Net::WholesaleSystem - VentraIP Wholesale SSL API

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Net::WholesaleSystem;

    my $WholesaleSystem = Net::WholesaleSystem->new(
        resellerID => $resellerID,
        apiKey     => $apiKey
    );
    
    # get balance
    my $balance = $WholesaleSystem->balanceQuery or die $WholesaleSystem->errstr;
    print $balance;

=head2 DESCRIPTION

VentraIP Wholesale SSL API

=head3 new

    my $WholesaleSystem = Net::WholesaleSystem->new(
        resellerID => $resellerID,
        apiKey     => $apiKey
    );

=over 4

=item * C<resellerID> (required)

=item * C<apiKey> (required)

resellerID & apiKey, provided by VentraIP Wholesale

=item * C<is_ote>

if C<is_ote> is set to 1, we use https://api-ote.wholesalesystem.com.au/?wsdl instead of https://api.wholesalesystem.com.au/?wsdl

=item * C<debug>

enable SOAP::Trace->import('all')

=back

=head3 balanceQuery

    my $balance = $WholesaleSystem->balanceQuery or die $WholesaleSystem->errstr;

Account Balance Query allows you to obtain the account balance.

=head3 getSSLCertificate

    my $cert = $WholesaleSystem->getSSLCertificate($certID);

to obtain information for a SSL certificate you?ve recently purchased

=head3 getCertSimpleStatus

    my $cert = $WholesaleSystem->getCertSimpleStatus($certID);

=head3 decodeCSR

    my $data = $WholesaleSystem->decodeCSR($csr);

decode the certificate signing request (CSR) you have provided to ensure all the details are correct before purchasing the SSL.

=head3 generateCSR

    my $data = $WholesaleSystem->generateCSR(
        'numOfYears' => '3',
        'country' => 'AU',
        'state'   => 'VIC',
        'city'    => 'Melbourne',
        'organisation' => 'VentraIP',
        'organisationUnit' => 'Systems Admin',
        'commonName' => 'forums.ventraip.com.au',
        'emailAddress' => 'webmaster@ventraip.com.au'
    );

generate the user a Private Key of 2048 bits in size, a Self Signed Certificate and a CSR request.

=head3 purchaseSSLCertificate

    my $cert = $WholesaleSystem->purchaseSSLCertificate(
        csr => $csr,
        productID => 55,
        firstName => 'John',
        lastName  => 'Doe',
        emailAddress => 'john@doe.com',
        address => 'PO Box 119',
        city => 'Beaconsfield',
        state => 'VIC',
        postCode => '3807',
        country => 'AU',
        phone => '+61.390245343',
        fax => '+61.380806481',
    ) or die $WholesaleSystem->errstr;

purchase an SSL certificate

=head3 reissueCertificate

    my $output = $WholesaleSystem->reissueCertificate($certID, $newCSR);

re-issue the SSL certificate using a new certificate signing request (CSR)

=head3 cancelSSLCertificate

    my $output = $WholesaleSystem->cancelSSLCertificate($certID);

cancel an SSL certificate that has not been processed (eg. still pending approval).

=head3 renewSSLCertificate

    my $output = $WholesaleSystem->renewSSLCertificate(
        certID => $certID,
        firstName => 'John',
        lastName  => 'Doe',
        emailAddress => 'john@doe.com',
        address => 'PO Box 119',
        city => 'Beaconsfield',
        state => 'VIC',
        postCode => '3807',
        country => 'AU',
        phone => '+61.390245343',
        fax => '+61.380806481',
    ) or die $WholesaleSystem->errstr;

renew an SSL certificate

=head3 resendDVEmail

    my $output = $WholesaleSystem->resendDVEmail($certID);

resend the approval email for an SSL certificate

=head3 resendIssuedCertificateEmail

    my $output = $WholesaleSystem->resendIssuedCertificateEmail($certID);

resend the original completed certificate email to the customer. This is helpful should
your customer loose the details of their SSL and you need to provide the information again.

=head3 listAllCerts

    my @certs = $WholesaleSystem->listAllCerts;

obtain a list of all SSL certificates related to your account

=head3 getDomainBeacon

    my $output = $WholesaleSystem->getDomainBeacon($certID, $domain);

obtain a list of all SSL certificates related to your account

The domain beacon is used for verification of premium SSL certificates to prove ownership of the domain and ensure the
requester has access to the domain in question. The domain beacon file must be saved as the filename returned from the
API request and the 'beacon' saved in the file.

=head3 checkDomainBeacon

    my $output = $WholesaleSystem->checkDomainBeacon($certID, $domain);

Upon requesting the domain beacon from 'SSL_getDomainBeacon' this function will then process the SSL for validation against
the certificate ID supplied.

=head3 Certificate Product IDs

    55 Trustwave Domain Validated SSL - 1 Year
    56 Trustwave Domain Validated SSL - 2 Year
    57 Trustwave Domain Validated SSL - 3 Year
    58 Trustwave Premium SSL - 1 year
    59 Trustwave Premium SSL - 2 year
    60 Trustwave Premium SSL - 3 year
    61 Trustwave Enterprise SSL - 1 Year
    62 Trustwave Enterprise SSL - 2 Year
    63 Trustwave Enterprise SSL - 3 Year
    64 Trustwave Premium Wildcard SSL - 1 Year
    65 Trustwave Premium Wildcard SSL - 2 Year
    66 Trustwave Premium Wildcard SSL - 3 Year
    67 Trustwave Premium EV SSL - 1 Year
    68 Trustwave Premium EV SSL - 2 Year

=head1 AUTHOR

VentraIP Wholesale <customercare@ventraipwholesale.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by VentraIP Wholesale.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
