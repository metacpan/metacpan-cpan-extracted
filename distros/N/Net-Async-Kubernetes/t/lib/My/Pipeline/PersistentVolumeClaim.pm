package My::Pipeline::PersistentVolumeClaim;
# A custom resource whose Kind is also called PersistentVolumeClaim, in its own
# API group - nothing to do with the core v1 PersistentVolumeClaim, and its
# spec is not immutable. Used by t/27-mock-ensure-group-kind.t (karr k45).

use IO::K8s::APIObject
    api_version     => 'pipeline.example.com/v1',
    resource_plural => 'persistentvolumeclaims';

with 'IO::K8s::Role::Namespaced';

k8s spec => { Str => 1 };

1;
