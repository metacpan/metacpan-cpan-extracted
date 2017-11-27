use Moose::Util::TypeConstraints;

coerce 'Swagger::Schema::Parameter',
  from 'HashRef',
   via {
     if      (exists $_->{ in } and $_->{ in } eq 'body') {
       return Swagger::Schema::BodyParameter->new($_);
     } elsif ($_->{ '$ref' }) {
       return Swagger::Schema::RefParameter->new($_);
     } else {
       return Swagger::Schema::OtherParameter->new($_);
     }
   };

package Swagger::Schema {
  our $VERSION = '1.02';
  #ABSTRACT: Object model for Swagger schema files
  use MooseX::DataModel;
  use Moose::Util::TypeConstraints;
  use namespace::autoclean;

  key swagger => (isa => enum([ '2.0' ]), required => 1);
  key info => (isa => 'Swagger::Schema::Info', required => 1);
  key host => (isa => 'Str'); #MAY contain a port
  key basePath => (isa => subtype(as 'Str', where { $_ =~ /^\// }));
  array schemes => (isa => enum([ 'http', 'https', 'ws', 'wss']));
  array consumes => (isa => 'Str'); #Str must be mime type: https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md#mimeTypes
  array produces => (isa => 'Str');
  object paths => (isa => 'Swagger::Schema::Path', required => 1);
  object definitions => (isa => 'Swagger::Schema::Schema');
  object parameters => (isa => 'Swagger::Schema::Parameter');
  object responses => (isa => 'Swagger::Schema::Response');
  object securityDefinitions => (isa => 'Swagger::Schema::SecurityScheme');
  # The below declaration is declared as Any, because there is no way to represent
  # any array of hashrefs of strings
  #array security => (isa => 'Swagger::Schema::SecurityRequirement');
  array security => (isa => 'Any');
  array tags => (isa => 'Swagger::Schema::Tag');
  key externalDocs => (isa => 'Swagger::Schema::ExternalDocumentation');    
}

package Swagger::Schema::SecurityScheme {
  use MooseX::DataModel;
  use namespace::autoclean;
  
}

#package Swagger::Schema::SecurityRequirement {
#  use MooseX::DataModel;
#
#  # See the security attribute in Swagger::Schema
#  # this object is more like a plain hashref
#  # it only has a patterned field {name}, which holds an array of strings
#
#  no MooseX::DataModel;
#}

package Swagger::Schema::Path {
  use MooseX::DataModel;
  use namespace::autoclean;

  key get => (isa => 'Swagger::Schema::Operation');
  key put => (isa => 'Swagger::Schema::Operation');
  key post => (isa => 'Swagger::Schema::Operation');
  key delete => (isa => 'Swagger::Schema::Operation');
  key options => (isa => 'Swagger::Schema::Operation');
  key head => (isa => 'Swagger::Schema::Operation');
  key patch => (isa => 'Swagger::Schema::Operation');
  array parameters => (isa => 'Swagger::Schema::Parameter');
}

package Swagger::Schema::Tag {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str');
  key description => (isa => 'Str');
  key externalDocs => (isa => 'Swagger::Schema::ExternalDocumentation');
}

enum 'Swagger::Schema::ParameterTypes',
     [qw/string number integer boolean array file object/];

package Swagger::Schema::Schema {
  use MooseX::DataModel;
  use namespace::autoclean;

  key ref => (isa => 'Str', location => '$ref');
  key x_ms_client_flatten => (isa => 'Bool', location => 'x-ms-client-flatten');

  key type => (isa => 'Swagger::Schema::ParameterTypes');
  key format => (isa => 'Str');
  key allowEmptyValue => (isa => 'Bool');
  key collectionFormat => (isa => 'Str');
  key default => (isa => 'Any');
  key maximum => (isa => 'Int');
  key exclusiveMaximum => (isa => 'Bool');
  key minimum => (isa => 'Int');
  key exclusiveMinumum => (isa => 'Bool');
  key maxLength => (isa => 'Int');
  key minLength => (isa => 'Int');
  key pattern => (isa => 'Str');
  key maxItems => (isa => 'Int');
  key minItems => (isa => 'Int');
  key uniqueItems => (isa => 'Bool');
  array enum => (isa => 'Any');
  key multipleOf => (isa => 'Num');
  #x-^ patterned fields

  key items => (isa => 'Swagger::Schema::Schema');
  array allOf => (isa => 'Swagger::Schema::Schema');
  object properties => (isa => 'Swagger::Schema::Schema');
  key additionalProperties => (isa => 'Swagger::Schema::Schema');
  key readOnly => (isa => 'Bool');
  #key xml => (isa => 'Swagger::Schema::XML');
  key externalDocs => (isa => 'Swagger::Schema::ExternalDocumentation');
  key example => (isa => 'Any');
}

package Swagger::Schema::Parameter {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str');
  key in => (isa => 'Str');
  key description => (isa => 'Str');
  key required => (isa => 'Bool');
  key x_ms_client_flatten => (isa => 'Bool', location => 'x-ms-client-flatten');
  key x_ms_skip_url_encoding => (isa => 'Bool', location => 'x-ms-skip-url-encoding');
  key x_ms_enum => (isa => 'Swagger::Schema::MSX::Enum', location => 'x-ms-enum');
  key x_ms_parameter_grouping => (isa => 'Swagger::Schema::MSX::ParameterGrouping', location => 'x-ms-parameter-grouping');
  key x_ms_client_request_id  => (isa => 'Bool', location => 'x-ms-client-request-id');
  key x_ms_client_name => (isa => 'Str', location => 'x-ms-client-name');
  key x_ms_parameter_location => (isa => 'Str', location => 'x-ms-parameter-location');
}

package Swagger::Schema::MSX::ParameterGrouping {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str');
  key postfix => (isa => 'Str');
}

package Swagger::Schema::MSX::Enum {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str');
  key modelAsString => (isa => 'Bool');
}

package Swagger::Schema::RefParameter {
  use MooseX::DataModel;
  use namespace::autoclean;

  extends 'Swagger::Schema::Parameter';
  key ref => (isa => 'Str', location => '$ref');
}

package Swagger::Schema::BodyParameter {
  use MooseX::DataModel;
  use namespace::autoclean;

  extends 'Swagger::Schema::Parameter';
  key schema => (isa => 'Swagger::Schema::Schema', required => 1);
}

package Swagger::Schema::OtherParameter {
  use MooseX::DataModel;
  use namespace::autoclean;

  extends 'Swagger::Schema::Parameter';

  key type => (isa => 'Swagger::Schema::ParameterTypes', required => 1);
  key format => (isa => 'Str');
  key allowEmptyValue => (isa => 'Bool');
  object items => (isa => 'Any');
  key collectionFormat => (isa => 'Str');
  key default => (isa => 'Any');
  key maximum => (isa => 'Int');
  key exclusiveMaximum => (isa => 'Bool');
  key minimum => (isa => 'Int');
  key exclusiveMinumum => (isa => 'Bool');
  key maxLength => (isa => 'Int');
  key minLength => (isa => 'Int');
  key pattern => (isa => 'Str');
  key maxItems => (isa => 'Int');
  key minItems => (isa => 'Int');
  key uniqueItems => (isa => 'Bool');
  array enum => (isa => 'Any');
  key multipleOf => (isa => 'Num');
  #x-^ patterned fields
}

enum 'Swagger::Schema::CollectionFormat',
     [qw/csv ssv tsv pipes/];

package Swagger::Schema::Item {
  use MooseX::DataModel;
  use namespace::autoclean;

  key type => (isa => 'Swagger::Schema::ParameterTypes', required => 1);
  key format => (isa => 'Str');
  
  array items => (isa => 'Swagger::Schema::Item');

  key collectionFormat => (isa => 'Swagger::Schema::CollectionFormat');
  key default => (isa => 'Any');
  key maximum => (isa => 'Num');
  key exclusiveMaximum => (isa => 'Bool');
  key minimum => (isa => 'Num');
  key exclusiveMinimum => (isa => 'Bool');
  key maxLength => (isa => 'Int');
  key minLength => (isa => 'Int');
  key pattern => (isa => 'Str');
  key maxItems => (isa => 'Int');
  key minItems => (isa => 'Int');
  key uniqueItems => (isa => 'Bool');
  array enum => (isa => 'Any');
  key multipleOf => (isa => 'Num');
  #x-^ patterned fields
}

package Swagger::Schema::Operation {
  use MooseX::DataModel;
  use namespace::autoclean;

  array tags => (isa => 'Str');
  key summary => (isa => 'Str');
  key description => (isa => 'Str');
  key externalDocs => (isa => 'Swagger::Schema::ExternalDocumentation');
  key operationId => (isa => 'Str');
  array consumes => (isa => 'Str'); #Must be a Mime Type
  array produces => (isa => 'Str'); #Must be a Mime Type
  array parameters => (isa => 'Swagger::Schema::Parameter');
  object responses => (isa => 'Swagger::Schema::Response');
  array schemes => (isa => 'Str');
  key deprecated => (isa => 'Bool');
  #key security => (isa =>
  #TODO: x-^ fields  
}

package Swagger::Schema::Response {
  use MooseX::DataModel;
  use namespace::autoclean;

  key description => (isa => 'Str');
  key schema => (isa => 'Swagger::Schema::Parameter');
  object headers => (isa => 'Swagger::Schema::Header');
  #key examples => (isa => '');
  #TODO: patterned fields  
}

package Swagger::Schema::Header {
  use MooseX::DataModel;
  use namespace::autoclean;

  key description => (isa => 'Str');
  key type => (isa => 'Str', required => 1);
  key format => (isa => 'Str');
  object items => (isa => 'HashRef');
  key collectionFormat => (isa => 'Str');
  key default => (isa => 'Any');
  key maximum => (isa => 'Int');
  key exclusiveMaximum => (isa => 'Bool');
  key minimum => (isa => 'Int');
  key exclusiveMinumum => (isa => 'Bool');
  key maxLength => (isa => 'Int');
  key minLength => (isa => 'Int');
  key pattern => (isa => 'Str');
  key maxItems => (isa => 'Int');
  key minItems => (isa => 'Int');
  key uniqueItems => (isa => 'Bool');
  array enum => (isa => 'Any');
  key multipleOf => (isa => 'Num');
}

package Swagger::Schema::ExternalDocumentation {
  use MooseX::DataModel;
  use namespace::autoclean;

  key description => (isa => 'Str');
  key url => (isa => 'Str', required => 1); #Must be in the format of a URL
}

package Swagger::Schema::Info {
  use MooseX::DataModel;
  use namespace::autoclean;

  key title => (isa => 'Str', required => 1);
  key description => (isa => 'Str'); #Can contain GFM
  key termsOfService => (isa => 'Str');
  key contact => (isa => 'Swagger::Schema::Contact');
  key license => (isa => 'Swagger::Schema::License');
  key version => (isa => 'Str', required => 1);
  #TODO: x-^ extensions
}

package Swagger::Schema::License {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str', required => 1);
  key url => (isa => 'Str'); #Must be in the format of a URL
}

package Swagger::Schema::Contact {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str');
  key url => (isa => 'Str');
  key email => (isa => 'Str');
}
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Swagger::Schema - Object access to Swagger / OpenAPI schema files

=head1 SYNOPSIS

  use File::Slurp;
  my $data = read_file($swagger_file);
  my $schema = Swagger::Schema->MooseX::DataModel::new_from_json($data);
  # use the object model
  say "This API consists of:";
  foreach my $path (sort keys %{ $schema->paths }){
    foreach my $http_verb (sort keys %{ $schema->paths->{ $path } }) {
      say "$http_verb on $path";
    }
  }

=head1 DESCRIPTION

Get programmatic access to a Swagger / OpenAPI file.

=head1 OBJECT MODEL

The object model is defined with L<MooseX::DataModel>. Take a look at the
C<lib/Swagger/Schema.pm> file or the swagger spec 
L<https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md> 
to know what you can find inside the objects

=head1 SEE ALSO

L<https://github.com/OAI/OpenAPI-Specification>

L<http://swagger.io>

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 BUGS and SOURCE

The source code is located here: https://github.com/pplu/swagger-schema-perl

Please report bugs to: https://github.com/pplu/swagger-schema-perl/issues

=head1 COPYRIGHT and LICENSE

Copyright (c) 2015 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.
