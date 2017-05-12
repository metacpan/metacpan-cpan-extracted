package Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Net::DashCS::Typemaps::EmergencyProvisioningService
    if not Net::DashCS::Typemaps::EmergencyProvisioningService->can('get_class');

sub START {
    $_[0]->set_proxy('https://service.dashcs.com/dash-api/soap/emergencyprovisioning/v1') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Net::DashCS::Typemaps::EmergencyProvisioningService')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub addLocation {
    my ($self, $body, $header) = @_;
    die "addLocation must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'addLocation',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::addLocation )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getAuthenticationCheck {
    my ($self, $body, $header) = @_;
    die "getAuthenticationCheck must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getAuthenticationCheck',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::getAuthenticationCheck )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getProvisionedLocationByURI {
    my ($self, $body, $header) = @_;
    die "getProvisionedLocationByURI must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getProvisionedLocationByURI',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::getProvisionedLocationByURI )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub validateLocation {
    my ($self, $body, $header) = @_;
    die "validateLocation must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'validateLocation',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::validateLocation )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub provisionLocation {
    my ($self, $body, $header) = @_;
    die "provisionLocation must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'provisionLocation',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::provisionLocation )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub removeURI {
    my ($self, $body, $header) = @_;
    die "removeURI must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'removeURI',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::removeURI )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getProvisionedLocationHistoryByURI {
    my ($self, $body, $header) = @_;
    die "getProvisionedLocationHistoryByURI must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getProvisionedLocationHistoryByURI',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::getProvisionedLocationHistoryByURI )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub removeLocation {
    my ($self, $body, $header) = @_;
    die "removeLocation must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'removeLocation',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::removeLocation )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getURIs {
    my ($self, $body, $header) = @_;
    die "getURIs must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getURIs',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::getURIs )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub addPinCode {
    my ($self, $body, $header) = @_;
    die "addPinCode must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'addPinCode',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::addPinCode )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getLocationsByURI {
    my ($self, $body, $header) = @_;
    die "getLocationsByURI must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getLocationsByURI',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Net::DashCS::Elements::getLocationsByURI )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort - SOAP Interface for the EmergencyProvisioningService Web Service

=head1 SYNOPSIS

 use Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort;
 my $interface = Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort->new();

 my $response;
 $response = $interface->addLocation();
 $response = $interface->getAuthenticationCheck();
 $response = $interface->getProvisionedLocationByURI();
 $response = $interface->validateLocation();
 $response = $interface->provisionLocation();
 $response = $interface->removeURI();
 $response = $interface->getProvisionedLocationHistoryByURI();
 $response = $interface->removeLocation();
 $response = $interface->getURIs();
 $response = $interface->addPinCode();
 $response = $interface->getLocationsByURI();



=head1 DESCRIPTION

SOAP Interface for the EmergencyProvisioningService web service
located at https://staging-service.dashcs.com/dash-api/soap/emergencyprovisioning/v1.

=head1 SERVICE EmergencyProvisioningService



=head2 Port EmergencyProvisioningPort



=head1 METHODS

=head2 General methods

=head3 new

Constructor.

All arguments are forwarded to L<SOAP::WSDL::Client|SOAP::WSDL::Client>.

=head2 SOAP Service methods

Method synopsis is displayed with hash refs as parameters.

The commented class names in the method's parameters denote that objects
of the corresponding class can be passed instead of the marked hash ref.

You may pass any combination of objects, hash and list refs to these
methods, as long as you meet the structure.

List items (i.e. multiple occurences) are not displayed in the synopsis.
You may generally pass a list ref of hash refs (or objects) instead of a hash
ref - this may result in invalid XML if used improperly, though. Note that
SOAP::WSDL always expects list references at maximum depth position.

XML attributes are not displayed in this synopsis and cannot be set using
hash refs. See the respective class' documentation for additional information.



=head3 addLocation



Returns a L<Net::DashCS::Elements::addLocationResponse|Net::DashCS::Elements::addLocationResponse> object.

 $response = $interface->addLocation( { # Net::DashCS::Types::addLocation
    uri =>  { # Net::DashCS::Types::uri
      callername =>  $some_value, # string
      uri =>  $some_value, # string
    },
    location =>  { # Net::DashCS::Types::location
      activatedtime =>  $some_value, # dateTime
      address1 =>  $some_value, # string
      address2 =>  $some_value, # string
      callername =>  $some_value, # string
      comments =>  $some_value, # string
      community =>  $some_value, # string
      customerorderid =>  $some_value, # string
      latitude =>  $some_value, # double
      legacydata =>  { # Net::DashCS::Types::legacyLocationData
        housenumber =>  $some_value, # string
        predirectional =>  $some_value, # string
        streetname =>  $some_value, # string
        suite =>  $some_value, # string
      },
      locationid =>  $some_value, # string
      longitude =>  $some_value, # double
      plusfour =>  $some_value, # string
      postalcode =>  $some_value, # string
      state =>  $some_value, # string
      status =>  { # Net::DashCS::Types::locationStatus
        code => $some_value, # locationStatusCode
        description =>  $some_value, # string
      },
      type => $some_value, # locationType
      updatetime =>  $some_value, # dateTime
    },
  },,
 );

=head3 getAuthenticationCheck



Returns a L<Net::DashCS::Elements::getAuthenticationCheckResponse|Net::DashCS::Elements::getAuthenticationCheckResponse> object.

 $response = $interface->getAuthenticationCheck( { # Net::DashCS::Types::getAuthenticationCheck
  },,
 );

=head3 getProvisionedLocationByURI



Returns a L<Net::DashCS::Elements::getProvisionedLocationByURIResponse|Net::DashCS::Elements::getProvisionedLocationByURIResponse> object.

 $response = $interface->getProvisionedLocationByURI( { # Net::DashCS::Types::getProvisionedLocationByURI
    uri =>  $some_value, # string
  },,
 );

=head3 validateLocation



Returns a L<Net::DashCS::Elements::validateLocationResponse|Net::DashCS::Elements::validateLocationResponse> object.

 $response = $interface->validateLocation( { # Net::DashCS::Types::validateLocation
    location =>  { # Net::DashCS::Types::location
      activatedtime =>  $some_value, # dateTime
      address1 =>  $some_value, # string
      address2 =>  $some_value, # string
      callername =>  $some_value, # string
      comments =>  $some_value, # string
      community =>  $some_value, # string
      customerorderid =>  $some_value, # string
      latitude =>  $some_value, # double
      legacydata =>  { # Net::DashCS::Types::legacyLocationData
        housenumber =>  $some_value, # string
        predirectional =>  $some_value, # string
        streetname =>  $some_value, # string
        suite =>  $some_value, # string
      },
      locationid =>  $some_value, # string
      longitude =>  $some_value, # double
      plusfour =>  $some_value, # string
      postalcode =>  $some_value, # string
      state =>  $some_value, # string
      status =>  { # Net::DashCS::Types::locationStatus
        code => $some_value, # locationStatusCode
        description =>  $some_value, # string
      },
      type => $some_value, # locationType
      updatetime =>  $some_value, # dateTime
    },
  },,
 );

=head3 provisionLocation



Returns a L<Net::DashCS::Elements::provisionLocationResponse|Net::DashCS::Elements::provisionLocationResponse> object.

 $response = $interface->provisionLocation( { # Net::DashCS::Types::provisionLocation
    locationid =>  $some_value, # string
  },,
 );

=head3 removeURI



Returns a L<Net::DashCS::Elements::removeURIResponse|Net::DashCS::Elements::removeURIResponse> object.

 $response = $interface->removeURI( { # Net::DashCS::Types::removeURI
    uri =>  $some_value, # string
  },,
 );

=head3 getProvisionedLocationHistoryByURI



Returns a L<Net::DashCS::Elements::getProvisionedLocationHistoryByURIResponse|Net::DashCS::Elements::getProvisionedLocationHistoryByURIResponse> object.

 $response = $interface->getProvisionedLocationHistoryByURI( { # Net::DashCS::Types::getProvisionedLocationHistoryByURI
    uri =>  $some_value, # string
  },,
 );

=head3 removeLocation



Returns a L<Net::DashCS::Elements::removeLocationResponse|Net::DashCS::Elements::removeLocationResponse> object.

 $response = $interface->removeLocation( { # Net::DashCS::Types::removeLocation
    locationid =>  $some_value, # string
  },,
 );

=head3 getURIs



Returns a L<Net::DashCS::Elements::getURIsResponse|Net::DashCS::Elements::getURIsResponse> object.

 $response = $interface->getURIs( { # Net::DashCS::Types::getURIs
  },,
 );

=head3 addPinCode



Returns a L<Net::DashCS::Elements::addPinCodeResponse|Net::DashCS::Elements::addPinCodeResponse> object.

 $response = $interface->addPinCode( { # Net::DashCS::Types::addPinCode
    uri =>  $some_value, # string
    pincode =>  $some_value, # string
  },,
 );

=head3 getLocationsByURI



Returns a L<Net::DashCS::Elements::getLocationsByURIResponse|Net::DashCS::Elements::getLocationsByURIResponse> object.

 $response = $interface->getLocationsByURI( { # Net::DashCS::Types::getLocationsByURI
    uri =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Mar 31 10:23:39 2010

=cut
