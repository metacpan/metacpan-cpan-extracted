use Swagger::Schema;

package Swagger::Schema::KubernetesGroupVersionKind;
  use MooseX::DataModel;

  key group => (isa => 'Str', required => 1);
  key kind => (isa => 'Str', required => 1);
  key version => (isa => 'Str', required => 1);

package Swagger::Schema::KubernetesOperation;
  use MooseX::DataModel;
  extends 'Swagger::Schema::Operation';

  key x_kubernetes_action => (isa => 'Str', location => 'x-kubernetes-action');
  key x_kubernetes_group_version_kind => (isa => 'Swagger::Schema::KubernetesGroupVersionKind', location => 'x-kubernetes-group-version-kind');

package Swagger::Schema::KubernetesPath;
  use MooseX::DataModel;
  extends 'Swagger::Schema::Path';
  use namespace::autoclean;

  key get => (isa => 'Swagger::Schema::KubernetesOperation');
  key put => (isa => 'Swagger::Schema::KubernetesOperation');
  key post => (isa => 'Swagger::Schema::KubernetesOperation');
  key delete => (isa => 'Swagger::Schema::KubernetesOperation');
  key options => (isa => 'Swagger::Schema::KubernetesOperation');
  key head => (isa => 'Swagger::Schema::KubernetesOperation');
  key patch => (isa => 'Swagger::Schema::KubernetesOperation');

package Swagger::Schema::KubernetesSchema;
  use MooseX::DataModel;
  extends 'Swagger::Schema::Schema';

  object properties => (isa => 'Swagger::Schema::KubernetesSchema');

  array x_kubernetes_list_map_keys => (isa => 'Str', location => 'x-kubernetes-list-map-keys');
  key x_kubernetes_list_type => (isa => 'Str', location => 'x-kubernetes-list-type');
  key x_kubernetes_patch_merge_key => (isa => 'Str', location => 'x-kubernetes-patch-merge-key');
  key x_kubernetes_patch_strategy => (isa => 'Str', location => 'x-kubernetes-patch-strategy');

package Swagger::Schema::Kubernetes;
  use MooseX::DataModel;
  our $VERSION = '0.01';
  extends 'Swagger::Schema';
  object paths => (isa => 'Swagger::Schema::KubernetesPath', required => 1);
  object definitions => (isa => 'Swagger::Schema::KubernetesSchema');

1;
### main pod documentation begin ###
 
=encoding UTF-8
 
=head1 NAME
 
Swagger::Schema::Kubernetes - Object model to Kubernetes Swagger / OpenAPI schema files
 
=head1 SYNOPSIS
 
  use File::Slurp;
  my $data = read_file($swagger_file);
  my $schema = Swagger::Schema::Kubernetes->MooseX::DataModel::new_from_json($data);
  # use the object model
  say "This API consists of:";
  foreach my $path (sort keys %{ $schema->paths }){
    foreach my $http_verb (sort keys %{ $schema->paths->{ $path } }) {
      say "$http_verb on $path";
    }
  }
 
=head1 DESCRIPTION
 
Get programmatic access to Kubenertes Swagger / OpenAPI files.

This module builds upon L<Swagger::Schema> to produce the same object model, enabling
access to the extra properties that the Kubernetes swagger definitions adds.
 
=head1 OBJECT MODEL
 
The object model is defined with L<MooseX::DataModel>. Take a look at the
C<lib/Swagger/Schema/Kubernetes.pm> and C<lib/Swagger/Schema.pm> files or the swagger spec 
to know what you can find inside the objects
 
=head1 SEE ALSO

L<https://github.com/kubernetes/kubernetes/tree/master/api/openapi-spec>
 
L<https://github.com/OAI/OpenAPI-Specification>
 
L<http://swagger.io>
 
=head1 AUTHOR
 
    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com
 
=head1 BUGS and SOURCE
 
The source code is located here: https://github.com/pplu/swagger-schema-kubernetes
 
Please report bugs to: https://github.com/pplu/swagger-schema-kubernetes/issues
 
=head1 COPYRIGHT and LICENSE
 
Copyright (c) 2018 by CAPSiDE
 
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.
