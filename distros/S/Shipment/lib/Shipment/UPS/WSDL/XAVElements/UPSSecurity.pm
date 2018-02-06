
package Shipment::UPS::WSDL::XAVElements::UPSSecurity;
$Shipment::UPS::WSDL::XAVElements::UPSSecurity::VERSION = '3.01';
use strict;
use warnings;

{    # BLOCK to scope variables

    sub get_xmlns {'http://www.ups.com/XMLSchema/XOLTWS/UPSS/v1.0'}

    __PACKAGE__->__set_name('UPSSecurity');
    __PACKAGE__->__set_nillable();
    __PACKAGE__->__set_minOccurs();
    __PACKAGE__->__set_maxOccurs();
    __PACKAGE__->__set_ref();

    use base qw(
      SOAP::WSDL::XSD::Typelib::Element
      SOAP::WSDL::XSD::Typelib::ComplexType
    );

    our $XML_ATTRIBUTE_CLASS;
    undef $XML_ATTRIBUTE_CLASS;

    sub __get_attr_class {
        return $XML_ATTRIBUTE_CLASS;
    }

    use Class::Std::Fast::Storable constructor => 'none';
    use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

    Class::Std::initialize();

    {    # BLOCK to scope variables

        my %UsernameToken_of : ATTR(:get<UsernameToken>);
        my %ServiceAccessToken_of : ATTR(:get<ServiceAccessToken>);

        __PACKAGE__->_factory(
            [   qw(        UsernameToken
                  ServiceAccessToken

                  )
            ],
            {   'UsernameToken'      => \%UsernameToken_of,
                'ServiceAccessToken' => \%ServiceAccessToken_of,
            },
            {

                'UsernameToken' =>
                  'Shipment::UPS::WSDL::XAVElements::UPSSecurity::_UsernameToken',

                'ServiceAccessToken' =>
                  'Shipment::UPS::WSDL::XAVElements::UPSSecurity::_ServiceAccessToken',
            },
            {

                'UsernameToken'      => 'UsernameToken',
                'ServiceAccessToken' => 'ServiceAccessToken',
            }
        );

    }    # end BLOCK


    package Shipment::UPS::WSDL::XAVElements::UPSSecurity::_ServiceAccessToken;
    $Shipment::UPS::WSDL::XAVElements::UPSSecurity::_ServiceAccessToken::VERSION
      = '3.01';
    use strict;
    use warnings;
    {
        our $XML_ATTRIBUTE_CLASS;
        undef $XML_ATTRIBUTE_CLASS;

        sub __get_attr_class {
            return $XML_ATTRIBUTE_CLASS;
        }

        use Class::Std::Fast::Storable constructor => 'none';
        use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

        Class::Std::initialize();

        {    # BLOCK to scope variables

            sub get_xmlns {'http://www.ups.com/XMLSchema/XOLTWS/UPSS/v1.0'}

            my %AccessLicenseNumber_of : ATTR(:get<AccessLicenseNumber>);

            __PACKAGE__->_factory(
                [   qw(        AccessLicenseNumber

                      )
                ],
                {'AccessLicenseNumber' => \%AccessLicenseNumber_of,},
                {   'AccessLicenseNumber' =>
                      'SOAP::WSDL::XSD::Typelib::Builtin::string',
                },
                {

                    'AccessLicenseNumber' => 'AccessLicenseNumber',
                }
            );

        }    # end BLOCK


    }


    package Shipment::UPS::WSDL::XAVElements::UPSSecurity::_UsernameToken;
    $Shipment::UPS::WSDL::XAVElements::UPSSecurity::_UsernameToken::VERSION =
      '3.01';
    use strict;
    use warnings;
    {
        our $XML_ATTRIBUTE_CLASS;
        undef $XML_ATTRIBUTE_CLASS;

        sub __get_attr_class {
            return $XML_ATTRIBUTE_CLASS;
        }

        use Class::Std::Fast::Storable constructor => 'none';
        use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

        Class::Std::initialize();

        {    # BLOCK to scope variables

            sub get_xmlns {'http://www.ups.com/XMLSchema/XOLTWS/UPSS/v1.0'}

            my %Username_of : ATTR(:get<Username>);
            my %Password_of : ATTR(:get<Password>);

            __PACKAGE__->_factory(
                [   qw(        Username
                      Password

                      )
                ],
                {   'Username' => \%Username_of,
                    'Password' => \%Password_of,
                },
                {   'Username' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
                    'Password' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
                },
                {

                    'Username' => 'Username',
                    'Password' => 'Password',
                }
            );

        }    # end BLOCK


    }


}    # end of BLOCK


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::UPS::WSDL::XAVElements::UPSSecurity

=head1 VERSION

version 3.01

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
UPSSecurity from the namespace http://www.ups.com/XMLSchema/XOLTWS/UPSS/v1.0.

=head1 NAME

Shipment::UPS::WSDL::XAVElements::UPSSecurity

=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * UsernameToken

 $element->set_UsernameToken($data);
 $element->get_UsernameToken();

=item * ServiceAccessToken

 $element->set_ServiceAccessToken($data);
 $element->get_ServiceAccessToken();

=back

=head1 METHODS

=head2 new

 my $element = Shipment::UPS::WSDL::XAVElements::UPSSecurity->new($data);

Constructor. The following data structure may be passed to new():

 {
   UsernameToken =>  {
     Username =>  $some_value, # string
     Password =>  $some_value, # string
   },
   ServiceAccessToken =>  {
     AccessLicenseNumber =>  $some_value, # string
   },
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=head1 AUTHOR

Andrew Baerg <baergaj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andrew Baerg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
