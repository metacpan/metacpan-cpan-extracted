use Moose::Util::TypeConstraints;

subtype 'Swagger::Schema::V3::RefOrSchema', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::Schema';
subtype 'Swagger::Schema::V3::RefOrSchemaOrBool', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::Schema|Bool';
subtype 'Swagger::Schema::V3::RefOrResponse', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::Response';
subtype 'Swagger::Schema::V3::RefOrPath', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::Path';
subtype 'Swagger::Schema::V3::RefOrHeader', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::Header';
subtype 'Swagger::Schema::V3::RefOrLink', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::Link';
subtype 'Swagger::Schema::V3::RefOrRequestBody', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::RequestBody';
subtype 'Swagger::Schema::V3::RefOrParameter', as 'Swagger::Schema::V3::Ref|Swagger::Schema::V3::Parameter';



coerce 'Swagger::Schema::V3::RefOrSchema',
  from 'HashRef',
   via {
     if ($_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } else {
       return Swagger::Schema::V3::Schema->new($_);
     }
   };

coerce 'Swagger::Schema::V3::RefOrSchemaOrBool',
  from 'HashRef',
   via {
     if (ref($_) && $_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } elsif (ref($_)) {
       return Swagger::Schema::V3::Schema->new($_);
     } else {
         return $_;
     }
   };


coerce 'Swagger::Schema::V3::RefOrResponse',
  from 'HashRef',
   via {
     if ($_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } else {
       return Swagger::Schema::V3::Response->new($_);
     }
   };

coerce 'Swagger::Schema::V3::RefOrPath',
  from 'HashRef',
   via {
     if ($_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } else {
       return Swagger::Schema::V3::Path->new($_);
     }
   };

coerce 'Swagger::Schema::V3::RefOrHeader',
  from 'HashRef',
   via {
     if ($_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } else {
       return Swagger::Schema::V3::Header->new($_);
     }
   };

coerce 'Swagger::Schema::V3::RefOrLink',
  from 'HashRef',
   via {
     if ($_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } else {
       return Swagger::Schema::V3::Link->new($_);
     }
   };

coerce 'Swagger::Schema::V3::RefOrRequestBody',
  from 'HashRef',
   via {
     if ($_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } else {
       return Swagger::Schema::V3::RequestBody->new($_);
     }
   };

coerce 'Swagger::Schema::V3::RefOrParameter',
  from 'HashRef',
   via {
     if ($_->{ '$ref' }) {
       return Swagger::Schema::V3::Ref->new($_);
     } else {
       return Swagger::Schema::V3::Parameter->new($_);
     }
   };

package Swagger::Schema::V3 {
  use MooseX::DataModel;
  use Moose::Util::TypeConstraints;
  use namespace::autoclean;

  key openapi => (isa => 'Str', required => 1);
  key info => (isa => 'Swagger::Schema::V3::Info', required => 1);
  array servers => (isa => 'Swagger::Schema::V3::Server');
  object paths => (isa => 'Swagger::Schema::V3::Path', required => 1);
  key components => (isa => 'Swagger::Schema::V3::Components');
  array security => (isa => 'HashRef');
  array tags => (isa => 'Swagger::Schema::V3::Tag');
  key externalDocs => (isa => 'Swagger::Schema::V3::ExternalDocumentation');
}

package Swagger::Schema::V3::Tag {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str', required => 1);
  key description => (isa => 'Str');
  key externalDocs => (isa => 'Swagger::Schema::V3::ExternalDocumentation');
}

package Swagger::Schema::V3::Components {
  use MooseX::DataModel;
  use namespace::autoclean;

  object schemas => (isa => 'Swagger::Schema::V3::RefOrSchema');
  object responses => (isa => 'Swagger::Schema::V3::RefOrResponse');
  object parameters => (isa => 'Swagger::Schema::V3::RefOrParameter');
  #object examples => (isa => 'Swagger::Schema::V3::RefOr');
  object requestBodies => (isa => 'Swagger::Schema::V3::RefOrRequestBody');
  object headers => (isa => 'Swagger::Schema::V3::RefOrHeader');
  object securitySchemes => (isa => 'Swagger::Schema::V3::SecurityScheme');
  object links => (isa => 'Swagger::Schema::V3::RefOrLink');
  #object callbacks => (isa => 'Swagger::Schema::V3::RefOr');
}

package Swagger::Schema::V3::Server {
  use MooseX::DataModel;
  use namespace::autoclean;

  key url => (isa => 'Str', required => 1);
  key description => (isa => 'Str');
  object variables => (isa => 'Swagger::Schema::V3::ServerVariable');
}

package Swagger::Schema::V3::ServerVariable {
  use MooseX::DataModel;
  use namespace::autoclean;

  array enum => (isa => 'Str');
  key default => (isa => 'Str', required => 1);
  key description => (isa => 'Str');
}

package Swagger::Schema::V3::Path {
  use MooseX::DataModel;
  use namespace::autoclean;

  key summary => (isa => 'Str');
  key description => (isa => 'Str');
  key get => (isa => 'Swagger::Schema::V3::Operation');
  key put => (isa => 'Swagger::Schema::V3::Operation');
  key post => (isa => 'Swagger::Schema::V3::Operation');
  key delete => (isa => 'Swagger::Schema::V3::Operation');
  key options => (isa => 'Swagger::Schema::V3::Operation');
  key head => (isa => 'Swagger::Schema::V3::Operation');
  key patch => (isa => 'Swagger::Schema::V3::Operation');
  key trace => (isa => 'Swagger::Schema::V3::Operation');

  array servers => (isa => 'Swagger::Schema::V3::Server');

  array parameters => (isa => 'Swagger::Schema::V3::Parameter');
}

enum 'Swagger::Schema::V3::ParameterTypes',
     [qw/string number integer boolean array file object/];

enum 'Swagger::Schema::V3::SecurityParameterTypes',
     [qw/http apiKey openIdConnect oauth2/];

package Swagger::Schema::V3::SecurityScheme {
  use MooseX::DataModel;
  use namespace::autoclean;

  key type => (isa => 'Swagger::Schema::V3::SecurityParameterTypes', required => 1);
  key scheme => (isa => 'Str');
}


package Swagger::Schema::V3::Schema {
  use MooseX::DataModel;
  use namespace::autoclean;

  key title => (isa => 'Str');
  key multipleOf => (isa => 'Num');
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
  array required => (isa => 'Str');
  array enum => (isa => 'Any');

  key type => (isa => 'Swagger::Schema::V3::ParameterTypes');
  array allOf => (isa => 'Swagger::Schema::V3::RefOrSchema');
  array oneOf => (isa => 'Swagger::Schema::V3::RefOrSchema');
  array anyOf => (isa => 'Swagger::Schema::V3::RefOrSchema');
  key not => (isa => 'Swagger::Schema::V3::RefOrSchema');
  key items => (isa => 'Swagger::Schema::V3::RefOrSchema');
  object properties => (isa => 'Swagger::Schema::V3::RefOrSchema');
  key additionalProperties => (isa => 'Swagger::Schema::V3::RefOrSchemaOrBool');
  key description => (isa => 'Str');
  key format => (isa => 'Str');

  key nullable => (isa => 'Bool');
  key discriminator => (isa => 'Swagger::Schema::V3::Discriminator');
  key readOnly => (isa => 'Bool');
  key writeOnly => (isa => 'Bool');
  #key xml => (isa => 'Swagger::Schema::V3::XML');
  key externalDocs => (isa => 'Swagger::Schema::V3::ExternalDocumentation');
  key example => (isa => 'Any');
  key deprecated => (isa => 'Bool');
  #x-^ patterned fields
}

package Swagger::Schema::V3::Discriminator {
  use MooseX::DataModel;
  use namespace::autoclean;

  key propertyName => (isa => 'Str', required => 1);
  object mapping => (isa => 'Str');
}

package Swagger::Schema::V3::ParameterBase {
  use MooseX::DataModel;
  use namespace::autoclean;

  key description => (isa => 'Str');
  key required => (isa => 'Bool');
  key deprecated => (isa => 'Bool');
  key allowEmptyValue => (isa => 'Bool');

  key style => (isa => 'Str');
  key explode => (isa => 'Bool');
  key allowReserved => (isa => 'Bool');

  key schema => (isa => 'Swagger::Schema::V3::RefOrSchema');

  key example => (isa => 'Any');
  # examples can be Example Object | Reference Object
  object examples => (isa => 'Any');

  object content => (isa => 'Swagger::Schema::V3::MediaType');
}

package Swagger::Schema::V3::Header {
  use MooseX::DataModel;
  use namespace::autoclean;
  extends 'Swagger::Schema::V3::ParameterBase';
}

package Swagger::Schema::V3::Parameter {
  use MooseX::DataModel;
  use namespace::autoclean;
  extends 'Swagger::Schema::V3::ParameterBase';

  key name => (isa => 'Str', required => 1);
  key in => (isa => 'Str', required => 1);
}

package Swagger::Schema::V3::MediaType {
  use MooseX::DataModel;
  use namespace::autoclean;

  key schema => (isa => 'Swagger::Schema::V3::RefOrSchema');
  key example => (isa => 'Any');
  # examples can be Example Object | Reference Object
  object examples => (isa => 'Any');
  object encoding => (isa => 'Swagger::Schema::V3::Encoding');
}

package Swagger::Schema::V3::Encoding {
  use MooseX::DataModel;
  use namespace::autoclean;

  key contentType => (isa => 'Str');
  object headers => (isa => 'Swagger::Schema::V3::Header');
  key style => (isa => 'Str');
  key explode => (isa => 'Bool');
  key allowReserved => (isa => 'Bool');
}

package Swagger::Schema::V3::Ref {
  use MooseX::DataModel;
  use namespace::autoclean;

  key ref => (isa => 'Str', location => '$ref');
}

package Swagger::Schema::V3::RequestBody {
  use MooseX::DataModel;
  use namespace::autoclean;

  key description => (isa => 'Str');
  object content => (isa => 'Swagger::Schema::V3::MediaType', required => 1);
  key required => (isa => 'Bool', default => 0);
}

package Swagger::Schema::V3::Operation {
  use MooseX::DataModel;
  use namespace::autoclean;

  array tags => (isa => 'Str');
  key summary => (isa => 'Str');
  key description => (isa => 'Str');
  key externalDocs => (isa => 'Swagger::Schema::V3::ExternalDocumentation');
  key operationId => (isa => 'Str');
  array parameters => (isa => 'Swagger::Schema::V3::RefOrParameter');

  key requestBody => (isa => 'Swagger::Schema::V3::RefOrRequestBody');
  # TODO: keys for responses can be default or http codes
  object responses => (isa => 'Swagger::Schema::V3::RefOrResponse', required => 1);
  object callbacks => (isa => 'Swagger::Schema::V3::RefOrPath');
  key deprecated => (isa => 'Bool');

  array security => (isa => 'HashRef');
  array servers => (isa => 'Swagger::Schema::V3::Server');
}

package Swagger::Schema::V3::Link {
  use MooseX::DataModel;
  use namespace::autoclean;

  key operationRef => (isa => 'Str');
  key operationId => (isa => 'Str');
  object parameters => (isa => 'Any');
  object requestBody => (isa => 'Any');
  key description => (isa => 'Str');
  key server => (isa => 'Swagger::Schema::V3::Server');
}

package Swagger::Schema::V3::Response {
  use MooseX::DataModel;
  use namespace::autoclean;

  key description => (isa => 'Str', required => 1);
  object headers => (isa => 'Swagger::Schema::V3::RefOrHeader');
  object content => (isa => 'Swagger::Schema::V3::MediaType');
  object links => (isa => 'Swagger::Schema::V3::RefOrLink');
}

package Swagger::Schema::V3::ExternalDocumentation {
  use MooseX::DataModel;
  use namespace::autoclean;

  key description => (isa => 'Str');
  key url => (isa => 'Str', required => 1); #Must be in the format of a URL
}

package Swagger::Schema::V3::Info {
  use MooseX::DataModel;
  use namespace::autoclean;

  key title => (isa => 'Str', required => 1);
  key description => (isa => 'Str'); #Can contain GFM
  key termsOfService => (isa => 'Str');
  key contact => (isa => 'Swagger::Schema::V3::Contact');
  key license => (isa => 'Swagger::Schema::V3::License');
  key version => (isa => 'Str', required => 1);
  #TODO: x-^ extensions
}

package Swagger::Schema::V3::License {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str', required => 1);
  key url => (isa => 'Str'); #Must be in the format of a URL
}

package Swagger::Schema::V3::Contact {
  use MooseX::DataModel;
  use namespace::autoclean;

  key name => (isa => 'Str');
  key url => (isa => 'Str');
  key email => (isa => 'Str');
}

### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Swagger::Schema::V3 - Object access to OpenAPI V3 schema files

=head1 SYNOPSIS

  use File::Slurp;
  my $data = read_file($swagger_file);
  my $schema = Swagger::Schema::V3->MooseX::DataModel::new_from_json($data);
  # use the object model
  say "This API consists of:";
  foreach my $path (sort keys %{ $schema->paths }){
    foreach my $http_verb (sort keys %{ $schema->paths->{ $path } }) {
      say "$http_verb on $path";
    }
  }

=head1 DESCRIPTION

Get programmatic access to an OpenAPI V3 file.

If you're trying to parse a V2 file, take a look at L<Swagger::Schema>

=head1 OBJECT MODEL

The object model is defined with L<MooseX::DataModel>. Take a look at the
C<lib/Swagger/Schema/V3.pm> file or the swagger spec
L<https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md>
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
