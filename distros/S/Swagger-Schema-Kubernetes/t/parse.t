#!/usr/bin/env perl

use Test::More;
use Swagger::Schema::Kubernetes;

my $test_swagger = <<EOF;
{
  "swagger": "2.0",
  "info": {
   "title": "Kubernetes",
   "version": "v1.13.0"
  },
  "paths": {
   "/api/v1/componentstatuses": {
    "parameters": [],
    "get": {
     "description": "list objects of kind ComponentStatus",
     "consumes": [
      "*/*"
     ],
     "produces": [
      "application/json",
      "application/yaml"
     ],
     "schemes": [
      "https"
     ],
     "tags": [
      "core_v1"
     ],
     "operationId": "listCoreV1ComponentStatus",
     "responses": {
      "200": {
       "description": "OK",
       "schema": {
        "\$ref": "#/definitions/io.k8s.api.core.v1.ComponentStatusList"
       }
      },
      "401": {
       "description": "Unauthorized"
      }
     },
     "x-kubernetes-action": "list",
     "x-kubernetes-group-version-kind": {
       "group": "",
       "kind": "ComponentStatus",
       "version": "v1"
     }
    }
   }
  },
  "definitions": {
   "io.k8s.api.core.v1.Container": {
    "description": "A single application container that you want to run within a pod.",
    "required": [
     "name"
    ],
    "properties": {
     "ports": {
      "description": "",
      "type": "array",
      "items": {
       "\$ref": "#/definitions/io.k8s.api.core.v1.ContainerPort"
      },
      "x-kubernetes-list-map-keys": [
       "containerPort",
       "protocol"
      ],
      "x-kubernetes-list-type": "map",
      "x-kubernetes-patch-merge-key": "containerPort",
      "x-kubernetes-patch-strategy": "merge"
     }
    }
   }
  }
}
EOF

{
  my $schema = Swagger::Schema::Kubernetes->MooseX::DataModel::new_from_json($test_swagger);
  isa_ok($schema, 'Swagger::Schema::Kubernetes');

  cmp_ok($schema->paths->{ "/api/v1/componentstatuses" }->get->x_kubernetes_action, 'eq', 'list');
  cmp_ok($schema->paths->{ "/api/v1/componentstatuses" }->get->x_kubernetes_group_version_kind->group, 'eq', '');
  cmp_ok($schema->paths->{ "/api/v1/componentstatuses" }->get->x_kubernetes_group_version_kind->kind, 'eq', 'ComponentStatus');
  cmp_ok($schema->paths->{ "/api/v1/componentstatuses" }->get->x_kubernetes_group_version_kind->version, 'eq', 'v1');

  cmp_ok($schema->definitions->{ "io.k8s.api.core.v1.Container" }->properties->{ ports }->x_kubernetes_list_type, 'eq', 'map');
  cmp_ok($schema->definitions->{ "io.k8s.api.core.v1.Container" }->properties->{ ports }->x_kubernetes_list_map_keys->[0], 'eq', 'containerPort');
  cmp_ok($schema->definitions->{ "io.k8s.api.core.v1.Container" }->properties->{ ports }->x_kubernetes_list_map_keys->[1], 'eq', 'protocol');
  cmp_ok($schema->definitions->{ "io.k8s.api.core.v1.Container" }->properties->{ ports }->x_kubernetes_patch_strategy, 'eq', 'merge');
  cmp_ok($schema->definitions->{ "io.k8s.api.core.v1.Container" }->properties->{ ports }->x_kubernetes_patch_merge_key, 'eq', 'containerPort');
}

done_testing;
