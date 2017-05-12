#=================================================================
#
# Copyright (C) 2003-2004 Byrne Reese (byrne at majordojo dot com)
# The Salesforce module is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.
#
#=================================================================

package Salesforce;

use Service;

$VERSION = 0.57;

##################################################################
# BEGIN PortType Definitions
# Notes:
package Salesforce::Soap;

use strict;
use Encode;

BEGIN {
    use vars qw($PARAMS);
    $PARAMS->{'login'} = { 'username' => 'SCALAR', 'password' => 'SCALAR', };
}

sub new {
    my ($class)  = shift;
    my (%params) = @_;
    bless {
        "style"     => 'document',
        "transport" => 'http://schemas.xmlsoap.org/soap/http',
        "address"   => $params{'address'},
        "encoding"  => $params{'encoding'}
    }, $class;
}

sub get_session_header {
    my $self = shift;
    return SOAP::Header->name( 'SessionHeader' =>
          \SOAP::Header->name( 'sessionId' => $self->{'sessionId'} ) );
}

sub login {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $r = $client->login(
        SOAP::Data->name( 'username' => $in{'username'} ),
        SOAP::Data->name( 'password' => $in{'password'} )
    );
    die $r->faultstring() if $r->fault();

    $self->{'sessionId'} = $r->valueof('//loginResponse/result/sessionId');
    $self->{'serverUrl'} = $self->{'address'} =
      $r->valueof('//loginResponse/result/serverUrl');
    $self->{'userId'} = $r->valueof('//loginResponse/result/userId');
    return 1;
}

sub query {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $r = $client->query(
        $self->get_session_header(),
        SOAP::Data->name( 'query' => $in{'query'} ),
        SOAP::Header->name(
            'QueryOptions' => \SOAP::Header->name( 'batchSize' => $in{'limit'} )
        )
    );
    return $r;

}

sub queryMore {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $r = $client->queryMore(
        $self->get_session_header(),
        SOAP::Data->name( 'queryLocator' => $in{'queryLocator'} ),
        SOAP::Header->name(
            'QueryOptions' => \SOAP::Header->name( 'batchSize' => $in{'limit'} )
        )
    );
    return $r;

}

sub xml_encode {
    my ( $self, $string ) = @_;
    if ( defined $self->{'encoding'} and length( $self->{'encoding'} ) > 0 ) {
        my @array = split( //, Encode::decode( $self->{'encoding'}, $string ) );
        my $str;
        foreach my $c (@array) {
            $str .= sprintf( "&#x%x;", ord($c) );
        }
        return $str;
    }
    else {
        return $string;
    }
}

sub update {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("update")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com")
      ->attr( { 'xmlns:sfons' => 'urn:sobject.partner.soap.sforce.com' } );

    my $type = $in{'type'};
    delete( $in{'type'} );

    my $id = $in{'id'};
    delete( $in{'id'} );

    my @elems;
    push @elems,
      SOAP::Data->prefix('sforce')->name( 'Id' => $id )->type('sforce:ID');

    foreach my $key ( keys %in ) {
        my $val = $in{$key};
        my $typ = $Salesforce::Constants::TYPES{$type}->{$key};
        if ( $typ eq 'xsd:string' ) {
            $val = $self->xml_encode( $in{$key} );
        }
        elsif ( !defined $typ || length($typ) == 0 ) {
            $typ = 'xsd:string';
            $val = $self->xml_encode( $in{$key} );
        }
        push @elems,
          SOAP::Data->prefix('sforce')->name( $key => $val )->type($typ);

#push @elems, SOAP::Data->prefix('sforce')->name($key => $in{$key})->type($Salesforce::Constants::TYPES{$type}->{$key});
    }

    my $r = $client->call(
        $method => SOAP::Data->name( 'sObjects' => \SOAP::Data->value(@elems) )
          ->attr( { 'xsi:type' => 'sforce:' . $type } ),
        $self->get_session_header()
    );

    return $r;
}

# Added 12/29/2003
sub create {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("create")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com")
      ->attr( { 'xmlns:sfons' => 'urn:sobject.partner.soap.sforce.com' } );

    my $type = $in{'type'};
    delete( $in{'type'} );

    my @elems;
    foreach my $key ( keys %in ) {
        my $val = $in{$key};
        my $typ = $Salesforce::Constants::TYPES{$type}->{$key};
        if ( $typ eq 'xsd:string' ) {
            $val = $self->xml_encode( $in{$key} );
        }
        elsif ( !defined $typ || length($typ) == 0 ) {
            $typ = 'xsd:string';
            $val = $self->xml_encode( $in{$key} );
        }
        push @elems,
          SOAP::Data->prefix('sfons')->name( $key => $val )->type($typ);

#push @elems, SOAP::Data->prefix('sfons')->name($key => $in{$key})->type($Salesforce::Constants::TYPES{$type}->{$key});
    }

    my $r = $client->call(
        $method => SOAP::Data->name( 'sObjects' => \SOAP::Data->value(@elems) )
          ->attr( { 'xsi:type' => 'sfons:' . $type } ),
        $self->get_session_header()
    );

    return $r;
}

# Added 12/29/2003
sub delete {
    my $self = shift;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("delete")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my @elems;
    foreach my $id (@_) {
        push @elems, SOAP::Data->name( 'ids' => $id )->type('tns:ID');
    }

    my $r = $client->call(
        $method => @elems,
        $self->get_session_header()
    );

    return $r;
}

# added 1/3/2004
sub getServerTimestamp {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("getServerTimestamp")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com")
      ->attr( { 'xmlns:sfons' => 'urn:sobject.partner.soap.sforce.com' } );

    my $r = $client->call( $method => undef, $self->get_session_header() );

    return $r;
}

# Added 12/29/2003
sub getUserInfo {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("getUserInfo")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix('sforce')->name( 'getUserInfo' => $in{'user'} )
          ->type('xsd:string'),
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub getUpdated {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("getUpdated")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix('sforce')->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        SOAP::Data->prefix('sforce')->name( 'startDate' => $in{'start'} )
          ->type('xsd:dateTime'),
        SOAP::Data->prefix('sforce')
          ->name( 'endDate' => $in{'end'} )
          ->type('xsd:dateTime'),
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub getDeleted {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("getDeleted")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix('sforce')->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        SOAP::Data->prefix('sforce')->name( 'startDate' => $in{'start'} )
          ->type('xsd:dateTime'),
        SOAP::Data->prefix('sforce')
          ->name( 'endDate' => $in{'end'} )
          ->type('xsd:dateTime'),
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub describeSObject {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("describeSObject")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix('sforce')->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub describeGlobal {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("describeGlobal")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method => undef,
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub setPassword {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("setPassword")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix('sforce')->name( 'userId' => $in{'userId'} )
          ->type('xsd:string'),
        SOAP::Data->prefix('sforce')->name( 'password' => $in{'password'} )
          ->type('xsd:string'),
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub resetPassword {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("resetPassword")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix('sforce')->name( 'userId' => $in{'userId'} )
          ->type('xsd:string'),
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub retrieve {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("retrieve")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my @elems;

    foreach my $id ( @{ $in{'ids'} } ) {
        push @elems, SOAP::Data->prefix('sforce')->name( 'ids' => $id )
          ->type('xsd:string');
    }

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix('sforce')->name( 'fieldList' => $in{'fields'} )
          ->type('xsd:string'),
        SOAP::Data->prefix('sforce')->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        @elems,
        $self->get_session_header()
    );

    return $r;
}

# Added 11/2/2004
sub search {
    my $self = shift;
    my (%in) = @_;

    my $client =
      SOAP::Lite->readable(1)->deserializer( Salesforce::Deserializer->new )
      ->on_action( sub { return '""' } )->uri('urn:partner.soap.sforce.com')
      ->proxy( $self->{address} );

    my $method =
      SOAP::Data->name("search")->prefix("sforce")
      ->uri("urn:partner.soap.sforce.com");

    my $r = $client->call(
        $method => SOAP::Data->prefix('sforce')
          ->name( 'searchString' => $in{'searchString'} )->type('xsd:string'),
        $self->get_session_header()
    );

    return $r;
}

# END PortType Definitions
##################################################################

#################################################################
# BEGIN Service Definitions
package Salesforce::SforceService;
use strict;
use vars qw(@ISA);
@ISA = qw(Service);

sub new {
    my ($class)  = shift;
    my (%params) = @_;
    my ($self)   = Service->new(@_);
    $self->add_port(
        'name'        => 'Soap',
        'bindingName' => 'tns:SoapBinding',
        'binding'     => Salesforce::Soap->new(
            'address'  => 'https://www.salesforce.com/services/Soap/u/4.0',
            'encoding' => $params{'encoding'}
        )
    );
    return ( bless( $self, $class ) );
}

# END Service Definitions
##################################################################

##################################################################
# BEGIN Type Definitions
# Notes:
package Salesforce::LoginResult;
use strict;

sub BEGIN {
    no strict 'refs';
    for my $method (qw(serverUrl sessionId userId)) {
        my $field = '_' . $method;
        *$method = sub {
            my $self = shift;
            @_
              ? ( $self->{$field} = shift, return $self )
              : return $self->{$field};
          }
    }
}

# END Type Definitions
##################################################################

##################################################################
# BEGIN Deserializer
package Salesforce::Deserializer;
use SOAP::Lite;

use strict;
use vars qw(@ISA);
@ISA = qw(SOAP::Deserializer);
use strict 'refs';

sub new {
    my $class    = shift;
    my $self     = $class->SUPER::new(@_);
    my (%params) = @_;
    return $self;
}

BEGIN {
    use vars qw($XSD_NSPREFIX $XSI_NSPREFIX $SOAPENV_NSPREFIX
      $SOAPENC_NSPREFIX $NSPREFIX);

    $XSD_NSPREFIX     = "xsd";
    $XSI_NSPREFIX     = "xsi";
    $SOAPENV_NSPREFIX = "SOAP-ENV";
    $SOAPENC_NSPREFIX = "SOAP-ENC";
    $NSPREFIX         = "wsisup";

    no strict 'refs';
    for my $class (qw(LoginResult)) {
        my $method_name = "as_" . $class;
        my $class_name  = "Salesforce::" . $class;
        my $method_body = <<END_OF_SUB;
sub $method_name {
    my (\$self,\$f,\$name,\$attr) = splice(\@_,0,4);
    my \$ns = pop;
    my \$${class} = Salesforce::${class}->new;
    foreach my \$elem (\@_) {
	\$elem = shift \@\$elem if (ref(\$elem->[0]) eq 'ARRAY');
	my (\$name2, \$attr2, \$value2, \$ns2) = splice(\@{\$elem},0,4);
	my (\$pre2,\$type2) = (\${attr2}->{\$XSI_NSPREFIX.":type"} =~ /([^:]*):(.*)/);
        if (\$pre2 && \$pre2 eq \$XSD_NSPREFIX) {
	    \$${class}->{'_'.\$name2} = \$value2;
	} else {
	    my \$cmd = '\$self->as_'.\$type2.'(\$f,\@\$value2);';
	    \$${class}->{'_'.\$name2} = eval \$cmd;
        }
    }
    return \$${class};
}
END_OF_SUB

        #    print STDERR $method_body;
        #    *$method_name = eval $method_body;
        eval $method_body;
    }
}

sub as_Array {
    my $self = shift;
    my $f    = shift;
    my @Array;
    foreach my $elem (@_) {
        my ( $name, $attr, $value, $ns ) = splice( @$elem, 0, 4 );
        my $attrv = ${attr}->{ $XSI_NSPREFIX . ":type" };
        my ( $pre, $type ) = ( $attrv =~ /([^:]*):(.*)/ );
        my $result;
        if ( $pre eq $XSD_NSPREFIX ) {
            $result = $value;
        }
        else {
            my $cmd =
              '$self->as_' . $type . '(1, $name, $attr, @$value, $ns );';

            #	    print STDERR $cmd . "\n";
            $result = eval $cmd;
        }
        push( @Array, $result );
    }
    return \@Array;
}

# END Deserializer
##################################################################

package Salesforce::Constants;

BEGIN {
    use vars qw(%TYPES);
    %TYPES = (
        'Account' => {
            'SLA__c'               => 'xsd:string',
            'UpsellOpportunity__c' => 'xsd:string',
            'Type'                 => 'xsd:string',
            'BillingStreet'        => 'xsd:string',
            'ShippingCountry'      => 'xsd:string',
            'LastModifiedDate'     => 'xsd:dateTime',
            'Website'              => 'xsd:string',
            'ShippingStreet'       => 'xsd:string',
            'ParentId'             => 'tns:ID',
            'Ownership'            => 'xsd:string',
            'SLASerialNumber_c'    => 'xsd:string',
            'OwnerId'              => 'tns:ID',
            'Phone'                => 'xsd:string',
            'LastModifiedById'     => 'tns:ID',
            'NumberOfEmployees'    => 'xsd:int',
            'TickerSymbol'         => 'xsd:string',
            'AnnualRevenue'        => 'xsd:double',
            'SystemModstamp'       => 'xsd:sateTime',
            'Industry'             => 'xsd:string',
            'Active__c'            => 'xsd:string',
            'ShippingState'        => 'xsd:string',
            'BillingCountry'       => 'xsd:string',
            'Sic'                  => 'xsd:string',
            'SLAExpirationDate__c' => 'xsd:date',
            'ShippingCity'         => 'xsd:string',
            'ShippingPostalCode'   => 'xsd:string',
            'NumberofLocations__c' => 'xsd:double',
            'CustomerPriority__c'  => 'xsd:string',
            'AccountNumber'        => 'xsd:string',
            'BillingCity'          => 'xsd:string',
            'Rating'               => 'xsd:string',
            'CreatedDate'          => 'xsd:dateTime',
            'BillingPostalCode'    => 'xsd:string',
            'Site'                 => 'xsd:string',
            'BillingState'         => 'xsd:string',
            'CreatedById'          => 'tns:ID',
            'Description'          => 'xsd:string',
            'Name'                 => 'xsd:string',
            'Fax'                  => 'xsd:string'
        },
        'Campaign' => {
            'Status'                   => 'xsd:string',
            'NumberOfWonOpportunities' => 'xsd:int',
            'IsActive'                 => 'xsd:boolean',
            'NumberOfContacts'         => 'xsd:int',
            'Type'                     => 'xsd:string',
            'LastModifiedDate'         => 'xsd:dateTime',
            'NumberOfConvertedLeads'   => 'xsd:int',
            'StartDate'                => 'xsd:date',
            'CurrencyIsoCode'          => 'xsd:string',
            'ExpectedResponse'         => 'xsd:double',
            'BudgetedCost'             => 'xsd:double',
            'EndDate'                  => 'xsd:date',
            'ActualCost'               => 'xsd:double',
            'OwnerId'                  => 'xsd:string',     #'tns:ID',
            'NumberOfResponses'        => 'xsd:int',
            'LastModifiedById'         => 'xsd:string',     #'tns:ID',
            'CreatedDate'              => 'xsd:dateTime',
            'NumberOfOpportunities'    => 'xsd:int',
            'NumberSent'               => 'xsd:double',
            'AmountWonOpportunities'   => 'xsd:double',
            'ExpectedRevenue'          => 'xsd:double',
            'NumberOfLeads'            => 'xsd:int',
            'CreatedById'              => 'xsd:string',     #'tns:ID',
            'AmountAllOpportunities'   => 'xsd:double',
            'Name'                     => 'xsd:string',
            'Description'              => 'xsd:string',
            'SystemModstamp'           => 'xsd:dateTime'
        },
        'CampaignMember' => {
            'Status'           => 'xsd:string',
            'CampaignId'       => 'xsd:string',             #'tns:ID',
            'HasResponded'     => 'xsd:boolean',
            'LastModifiedById' => 'xsd:string',             #'tns:ID',
            'CreatedDate'      => 'xsd:dateTime',
            'LastModifiedDate' => 'xsd:dateTime',
            'CreatedById'      => 'xsd:string',             #'tns:ID',
            'ContactId'        => 'xsd:string',             #'tns:ID',
            'LeadId'           => 'xsd:string',             #'tns:ID',
            'SystemModstamp'   => 'xsd:dateTime'
        },
        'Lead' => {
            'FirstName'              => 'xsd:string',
            'Street'                 => 'xsd:string',
            'Status'                 => 'xsd:string',
            'CampaignId'             => 'xsd:string',       #'tns:ID',
            'LeadSource'             => 'xsd:string',
            'ConvertedContactId'     => 'xsd:string',       #'tns:ID',
            'MobilePhone'            => 'xsd:string',
            'LastModifiedDate'       => 'xsd:dateTime',
            'Website'                => 'xsd:string',
            'Email'                  => 'xsd:string',
            'PostalCode'             => 'xsd:string',
            'RecordTypeId'           => 'xsd:string',
            'OwnerId'                => 'xsd:string',       #'tns:ID',
            'LastModifiedById'       => 'xsd:string',       #'tns:ID',
            'Phone'                  => 'xsd:string',
            'ConvertedOpportunityId' => 'xsd:string',       #'tns:ID',
            'NumberOfEmployees'      => 'xsd:int',
            'AnnualRevenue'          => 'xsd:double',
            'Industry'               => 'xsd:string',
            'SystemModstamp'         => 'xsd:dateTime',
            'City'                   => 'xsd:string',
            'State'                  => 'xsd:string',
            'ConvertedAccountId'     => 'xsd:string',       #'tns:ID',
            'Title'                  => 'xsd:string',
            'LastName'               => 'xsd:string',
            'CurrencyIsoCode'        => 'xsd:string',
            'Company'                => 'xsd:string',
            'Rating'                 => 'xsd:string',
            'Salutation'             => 'xsd:string',
            'IsConverted'            => 'xsd:boolean',
            'CreatedDate'            => 'xsd:dateTime',
            'Country'                => 'xsd:string',
            'CreatedById'            => 'xsd:string',       #'tns:ID',
            'IsUnreadByOwner'        => 'xsd:boolean',
            'Description'            => 'xsd:string',
            'HasOptedOutOfEmail'     => 'xsd:boolean',
            'Fax'                    => 'xsd:string'
        }
    );
}

1;    # Never forget the return value for the perl module :)
__END__

=pod

=head1 NAME

Salesforce - this class provides a simple abstraction layer between SOAP::Lite and Salesforce.com.

=head1 DESCRIPTION

This class provides a simple abstraction layer between SOAP::Lite and Salesforce.com. Because SOAP::Lite does not support complexTypes, and document/literal encoding is limited, this module works around those limitations and provides a more intuitive interface a developer can interact with.

=head1 METHODS

=over 

=item login( HASH )

The C<login> method returns a 1 if the login attempt was successful, and 0 otherwise. Upon a successful login, the sessionId is saved and the serverUrl set properly so that developers need not worry about setting these values manually.

The following are the accepted input parameters:

=over

=item username

A Salesforce.com username.

=item password

The password for the user indicated by C<username>.

=back

=item query( HASH )

Executes a query against the specified object and returns data that matches the specified criteria.

=over 

=item query

The query string to use for the query. The query string takes the form of a I<basic> SQL statement. For example, "SELECT Id,Name FROM Account".

See also: http://www.sforce.com/us/docs/sforce40/sforce_API_calls_SOQL.html#wp1452841

=item limit

This sets the batch size, or size of the result returned. This is helpful in producing paginated results, or fetch small sets of data at a time.

=back

=item queryMore( HASH )

Retrieves the next batch of objects from a C<query>.

=over 

=item queryLocator

The handle or string returned by C<query>. This identifies the result set and cursor for fetching the next set of rows from a result set.

=item limit

This sets the batch size, or size of the result returned. This is helpful in producing paginated results, or fetch small sets of data at a time.

=back

=item update( HASH )

Updates one or more existing objects in your organization's data. This subroutine takes as input a single perl HASH containing the fields (the keys of the hash) and the values of the record that will be updated.

The hash must contain the 'Id' key in order to identify the record to update.

=item create( HASH )

Adds one or more new individual objects to your organization's data. This takes as input a HASH containing the fields (the keys of the hash) and the values of the record you wish to add to your arganization.

The hash must contain the 'Type' key in order to identify the type of the record to add.

=item delete( ARRAY )

Deletes one or more individual objects from your organization's data. This subroutine takes as input an array of SCALAR values, where each SCALAR is an sObjectId.

=item getServerTimestamp()

Retrieves the current system timestamp (GMT) from the sforce Web service.

=item getUserInfo( HASH )

Retrieves personal information for the user associated with the current session.

=over

=item user

A user ID

=back

=item getUpdated( HASH )

Retrieves the list of individual objects that have been updated (added or changed) within the given timespan for the specified object.

=over

=item type

Identifies the type of the object you wish to find updates for.

=item start

A string identifying the start date/time for the query

=item end

A string identifying the end date/time for the query

=back

=item getDeleted( HASH )

Retrieves the list of individual objects that have been deleted within the given timespan for the specified object.

=over

=item type

Identifies the type of the object you wish to find deletions for.

=item start

A string identifying the start date/time for the query

=item end

A string identifying the end date/time for the query

=back

=item describeSObject( HASH )

Describes metadata (field list and object properties) for the specified object.

=over

=item type

The type of the object you wish to have described.

=back

=item describeGlobal()

Retrieves a list of available objects for your organization's data.

=item setPassword( HASH )

Sets the specified user's password to the specified value.

=over

=item userId

A user Id.

=item password

The new password to assign to the user identified by C<userId>.

=back

=item resetPassword( HASH )

Changes a user's password to a server-generated value.

=over

=item userId

A user Id.

=back

=item retrieve( HASH )

=over

=item fields

A comma delimitted list of field name you want retrieved.

=item type

The type of the object being queried.

=item id

The id of the object you want returned.

=back

=item search( HASH )

=over

=item searchString

The search string to be used in the query. For example, "find {4159017000} in phone fields returning contact(id, phone, firstname, lastname), lead(id, phone, firstname, lastname), account(id, phone, name)"

=back

=back


=head1 EXAMPLES

=head2 login()

    use Salesforce;
    my $service = new Salesforce::SforceService;
    my $port = $service->get_port_binding('Soap');
    $port->login('username' => $user,'password' => $pass)
       || die "Could not login to salesforce.com";

=head2 search()

    my $service = new Salesforce::SforceService;
    my $port = $service->get_port_binding('Soap');
    my $result = $port->login('username' => $user, 'password' => $pass);
    $result = $port->search('searchString' => 'find {4159017000} in phone fields returning contact(id, phone, firstname, lastname), lead(id, phone, firstname, lastname), account(id, phone, name)');

=head1 SUPPORT

Please visit Salesforce.com's user/developer forums online for assistance with
this module. You are free to contact the author directly if you are unable to
resolve your issue online.

=head1 AUTHORS

Byrne Reese <byrne at majordojo dot com>

=head1 COPYRIGHT

Copyright 2003-2004 Byrne Reese. All rights reserved.
