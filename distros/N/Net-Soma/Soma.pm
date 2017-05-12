package Net::Soma;

use strict;
use vars qw($DEBUG $VERSION @uris $AUTOLOAD %schemas);
use SOAP::Lite 0.71 #+trace => debug, objects
;

$VERSION = '0.02';

$DEBUG = 0;

@uris = qw( CPECollection AppCatalog AdminService CPESearch Version Applications
            CPEAccess ApplicationsV2 
        );

=head1 NAME

Net::Soma - Perl client interface to SOMA iWireless platform

=head1 SYNOPSIS

use Net::Soma;
use Net::Soma qw( AttributeInstance FeatureInstance ApplicationInstance
                  ChoiceItem AttributeDef FeatureDef ApplicationDef
                  ApplicationDefV2 FeatureDefV2 AttributeDefV2 CPEInfoDefV2
                  CPESearchStruct CPESearchResult CPEInfo CPEInfoDef
                  HardwarePort
                  NoSuchCPEException DataAccessException InternalFault
                  BadAppParameterException BadAppParameterExceptionV2
                  NoSuchAppException NoSuchFeatureException
                  NoSuchAttributeException BadCPEParameterException
                  ActiveApplicationsException );

$soma = new Net::Soma { url => 'https://soma.example.net:8088/ossapi/services',
                        namespace => 'AppCatalog',
                      }
  
$err_or_som = $soma->getApplicationDefinitions();

if (ref($err_or_som)){
  my $result = $err_or_som->result;
  foreach my $definition (@$result) {
    print $definition->name, "\n";
  }
}else{
  print "$err_or_som\n";
}
 
=head1 DESCRIPTION

Net::Soma is a module implementing a Perl interface to SOMA's iWireless
SOAP interface (ossapi).  It is compatible with release 1.5 of that software
and requires the WSDLs from SOMA.

Net::Soma enables you to simply access the SOAP interface of your SOMA
networks softair platform server.  

=head1 BASIC USAGE

Import the Net::Soma module with

use Net::Soma (@list_of_classes);

Net::Soma will create any of the following classes for you

AttributeInstance FeatureInstance ApplicationInstance ChoiceItem
AttributeDef FeatureDef ApplicationDef ApplicationDefV2 FeatureDefV2
AttributeDefV2 CPEInfoDefV2 CPESearchStruct CPESearchResult CPEInfo
CPEInfoDef HardwarePort NoSuchCPEException DataAccessException InternalFault
BadAppParameterException BadAppParameterExceptionV2 NoSuchAppException
NoSuchFeatureException NoSuchAttributeException BadCPEParameterException
ActiveApplicationsException 
    
=cut

sub import {
  my $class = shift;
  my @classes = @_;
  my $me = __PACKAGE__;
  my @classlist = qw( AttributeInstance FeatureInstance ApplicationInstance
                      ChoiceItem AttributeDef FeatureDef ApplicationDef
                      ApplicationDefV2 FeatureDefV2 AttributeDefV2 CPEInfoDefV2
                      CPESearchStruct CPESearchResult CPEInfo CPEInfoDef
                      HardwarePort
                      NoSuchCPEException DataAccessException InternalFault
                      BadAppParameterException BadAppParameterExceptionV2
                      NoSuchAppException NoSuchFeatureException
                      NoSuchAttributeException BadCPEParameterException
                      ActiveApplicationsException
                   );
  my (%EXPORT_OK) = map { $_ => 1 } @classlist;

  {
    no strict 'refs';         #hmmm force 'use' of all to be serialized?
    foreach my $class (@classlist) { 

      *{"SOAP::Serializer::as_$class"} = sub {
        my ($self, $value, $name, $type, $attr) = @_;

        $self->register_ns("urn:ossapi.services.core.soma.com", "netsoma");
        $self->encode_object( \SOAP::Data->value(
          SOAP::Data->name($name => map { SOAP::Data->name($_ => $value->{$_}) }
                                           keys %$value
                          )
        ), $name, $type, {'xsi:type' => "netsoma:$class", %$attr});
      };

      *{"SOAP::Serializer::as_ArrayOf$class"} = sub {
        my ($self, $value, $name, $type, $attr) = @_;

        $self->register_ns("urn:ossapi.services.core.soma.com", "netsoma");
        if (@$value) {
          $self->encode_object( \SOAP::Data->value(
            SOAP::Data->name($name => map { SOAP::Data->name(item => $_) }
                                             @$value
                            )
          ), $name, $type, {'xsi:type' => "netsoma:ArrayOf$class", %$attr});
        } else {
          $self->encode_object( [], $name, $type, {'xsi:type' => "netsoma:ArrayOf$class", %$attr});
        }

      };

    }

  }

  foreach $class ( map { $_, "ArrayOf$_" }
                   grep { exists( $EXPORT_OK{$_} )
                          or die "$_ is not exported by module $me"
                        }
                   @classes)
  {
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

  # $me =~ s/::/\//g;
  # $INC{"$me.pm"} =~ /^(.*)\.pm$/;
  # $me = $1;
  # for (@uris){
  #   $schemas{$_."Service"} = SOAP::Schema
  #     ->schema_url("file:$me/wsdls/$_.wsdl")
  #     ->parse->services->{$_."Service"};
  # }

}

=head1 CONSTRUCTOR

=over 4

=item new HASHREF

Creates a new Soma object.  HASHREF should contain the keys url and namespace
for the URL of the Soma SOAP proxy and the namespace of the methods you would
like to call.  You may optionally define the key die_on_fault to cause that
behavior for methods.

=cut 

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { @_ };

  for (@uris){
    $schemas{$_."Service"} = SOAP::Schema
      ->schema_url($self->{url}."$_?wsdl")
       ->parse->services->{$_."Service"};
  }

  return bless($self, $class);
}

=head1 METHODS

All Soma methods may be invoked as methods of the Net::Soma object.
The return value is either the fault string in the event of an error
or a SOAP::SOM object.

If the option die_on_fault was set for the Net::Soma object, then
instead the method dies on error and returns the result component
of the SOAP::SOM object on success.

=cut 

sub AUTOLOAD {
  my $self = shift;   #hmmm... test this?

  my $method = $AUTOLOAD;
  $method =~ s/.*://;
  return if $method eq 'DESTROY';

  my $nscount = 1;
  my $uri = $self->{namespace};
  $uri =~ s/Service$//;
  my $soap = SOAP::Lite
    -> autotype(1)
    -> readable(1)
    -> uri($uri)
    -> proxy($self->{url});

#  local *SOAP::Transport::HTTP::Client::get_basic_credentials = sub {
#    return $self->{user} => $self->{password};
#  };

  my $param = 0;
  my $som =
    $soap->$method( map {
      my $paramdata =
        $schemas{$self->{namespace}}{$method}{'parameters'}[$param++];
      my ($pre,$type) = SOAP::Utils::splitqname($paramdata->type);
      SOAP::Data->name($paramdata->name => $_ )
        ->type(${[SOAP::Utils::splitqname($paramdata->type)]}[1]) } @_
    );

  if ($som) {
    if ($som->fault){
      if ($self->{die_on_fault}){
        die $som->faultstring;
      } else {
        return $som->faultstring;
      }
    }else{
      if ($self->{die_on_fault}){
        return $som->result;
      } else {
        return $som;
      }
    }
  }

  die "Net::Soma failed to $method for $self->{namespace} at " . $self->{url};
}


=back

=head1 SEE ALSO

  SOAP::Lite, SOAP::SOM

  http://www.somanetworks.com/ for information about SOMA and iWireless.

  http://www.sisd.com/freeside/ for the ISP billing and provisioning system
  which provoked the need for this module.

=head1 BUGS

Namespace promiscuous.
Lax handling of arguments and return values.
In fact, calling a bogus method with arguments causes complaints about
accessing methods on undefined values (at line 233, paramdata->name)

Quite probably others.  Use at your own risk.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2008 Jeff Finucane jeff-net-soma@weasellips.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is neither authorized, sponsored, endorsed, nor supported
by Soma Networks.

=cut

1;
