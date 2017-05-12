package Net::Prizm;

use strict;
use vars qw($DEBUG $VERSION @uris %services $AUTOLOAD %schemas);
use SOAP::Lite 0.71;

$VERSION = '0.04';

$DEBUG = 0;

@uris = qw(CustomerIfService NetworkIfService LogEventIfService);

=head1 NAME

Net::Prizm - Perl client interface to Motorola Canopy Prizm

=head1 SYNOPSIS

use Net::Prizm;
use Net::Prizm qw(CustomerInfo LogEventInfo
                  ClientDevice ConfigurationTemplate ElementLinkInfo
                  Network PerformanceData);

$prizm = new Net::Prizm { url => 'https://prizm.example.net:8443/prizm/nbi',
                          namespace => 'CustomerIfService',
                          username => 'prizmuser',
                          password => 'associatedpassword',
                        }
  
$err_or_som = $prizm->getCustomers(['import_id'], ['50'], ['<']);

if (ref($err_or_som)){
  my $result = $err_or_som->result;
  foreach my $customer (@$result) {
    print $customer->contact, "\n";
  }
}else{
  print "$err_or_som\n";
}
 
=head1 DESCRIPTION

Net::Prizm is a module implementing a Perl interface to Motorola's Canopy
Prizm SOAP interface.  It is compatible with version 3.0r1 of that software
and requires the WSDL from Motorola.

Net::Prizm enables you to simply access the SOAP interface of your Prizm
server.  

=head1 BASIC USAGE

Import the Net::Prizm module with

use Net::Prizm (@list_of_classes);

Net::Prizm will create any of the following classes for you

CustomerInfo LogEventInfo PrizmElement ClientDevice ConfigurationTemplate
ElementLinkInfo Network PerformanceData 
    
=cut

sub import {
  my $class = shift;
  my @classes = @_;
  my $me = __PACKAGE__;
  my (%EXPORT_OK) = map { $_ => 1 } qw( CustomerInfo LogEventInfo PrizmElement
                                        ClientDevice ConfigurationTemplate
                                        ElementLinkInfo Network 
                                        PerformanceData );

  foreach $class (grep { exists( $EXPORT_OK{$_} )
                         or die "$_ is not exported by module $me"
                       } @classes) {
    no strict 'refs';

    *{"$class\::NEW"} = sub {
                         my $proto = shift;
                         my $class = ref($proto) || $proto;
                         my $self = { @_ };
                         return bless($self, $class);
                       };
    *{"$class\::AUTOLOAD"} = sub {
                              my $field = $AUTOLOAD;
                              $field =~ s/.*://;
                              return if $field eq 'DESTROY';
                              if ( defined($_[1]) ) {
                                $_[0]->{$field} = $_[1];
                              } else {
                                $_[0]->{$field};
                              }
                            };
  }

  $me =~ s/::/\//g;
  $INC{"$me.pm"} =~ /^(.*)\.pm$/;
  $me = $1;
  for (@uris){
    $schemas{$_} = SOAP::Schema
      ->schema_url("file:$me/wsdls/$_.wsdl")
      ->parse->services->{$_};
  }

}

=head1 CONSTRUCTOR

=over 4

=item new HASHREF

Creates a new Prizm object.  HASHREF should contain the keys url, namespace,
username, and password for the URL of the Prizm SOAP proxy, the namespace
of the methods you would like to call, and the username and password for
basic authentication.

=cut 

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { @_ };
  return bless($self, $class);
}

=head1 METHODS

All Prizm methods may be invoked as methods of the Net::Prizm object.
The return value is either the fault string in the event of an error
or a SOAP::SOM object.

=cut 

sub AUTOLOAD {
  my $self = shift;   #hmmm... test this?

  my $method = $AUTOLOAD;
  $method =~ s/.*://;
  return if $method eq 'DESTROY';

  my $soap = SOAP::Lite
    -> autotype(0)
    -> readable(1)
    -> uri($self->{namespace})
    -> proxy($self->{url});
  
  local *SOAP::Transport::HTTP::Client::get_basic_credentials = sub {
    return $self->{user} => $self->{password};
  };

  local *SOAP::Serializer::as_ArrayOf_xsd_string = sub {
    my ($self, $value, $name, $type, $attr) = @_;

    $name ||= $self->gen_name;
    $self->encode_object(\SOAP::Data->value(
      SOAP::Data->name('string' => @{$value})->type('string')
      ), $name, $type);

  };

  local *SOAP::Serializer::as_ArrayOf_xsd_int = sub {
    my ($self, $value, $name, $type, $attr) = @_;

    $name ||= $self->gen_name;
    $self->encode_object(\SOAP::Data->value(
      SOAP::Data->name('int' => @{$value})->type('int')
    ), $name, $type);
  };

  local *SOAP::Serializer::as_CustomerInfo = sub {
    my ($self, $value, $name, $type, $attr) = @_;

    my $schema = {
           'importId'         => 'string',
           'customerId'       => 'int',
           'customerName'     => 'string',
           'customerType'     => 'string',
           'address1'         => 'string',
           'address2'         => 'string',
           'city'             => 'string',
           'state'            => 'string',
           'zipCode'          => 'string',
           'workPhone'        => 'string',
           'homePhone'        => 'string',
           'mobilePhone'      => 'string',
           'pager'            => 'string',
           'email'            => 'string',
           'extraFieldNames'  => 'impl:ArrayOf_xsd_string',
           'extraFieldValues' => 'impl:ArrayOf_xsd_string',
           'elementIds'       => 'impl:ArrayOf_xsd_int',
    };

    my (@result) = ();
    foreach my $key (keys %$value){
      my $to_encode = $value->{$key};
      push @result, SOAP::Data->name($key => $to_encode)->type($schema->{$key});
    }

    return $self->encode_object(\SOAP::Data->value(
      SOAP::Data->name($name => @result)), $name, 
                                 $type,
                                 {'xsi:type' => 'impl:CustomerInfo', %$attr});
  };

  my $param = 0;
  my $som =
    $soap->$method( map {
      my $paramdata =
        $schemas{$self->{namespace}}{$method}{'parameters'}[$param++];
      SOAP::Data->name($paramdata->name => $_ )
        ->type(${[SOAP::Utils::splitqname($paramdata->type)]}[1]) } @_
    );

  if ($som) {
    if ($som->fault){
      return $som->faultstring;
    }else{
      return $som;
    }
  }

  "Net::Prizm failed to $method for $self->{namespace} at " . $self->{url};
}


=back

=head1 SEE ALSO

  SOAP::Lite, SOAP::SOM

  http://motorola.canopywireless.com/ for information about Canopy and
Prizm.

  http://www.sisd.com/freeside/ for the ISP billing and provisioning system
  which provoked the need for this module.

=head1 BUGS

No explicit handling of types other than CustomerInfo.
Namespace promiscuous.
Lax handling of arguments and return values.

Quite probably others.  Use at your own risk.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2006 Jeff Finucane jeff-net-prizm@weasellips.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

WDSL files copyright Motorola Inc. which reserves all rights.  

This software is neither authorized, sponsored, endorsed, nor supported
by Motorola Inc.

=cut

1;
