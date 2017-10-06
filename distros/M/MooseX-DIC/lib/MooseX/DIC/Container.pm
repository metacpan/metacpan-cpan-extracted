package MooseX::DIC::Container;

use Moose::Role;

# (package_name: Str) -> Any
requires 'build_class';

# (service_name: Str[,environment: Str]) -> Any
requires 'get_service';

# (service_name: Str) -> Bool
requires 'has_service';

# (service_name: Str[,environment: Str]) -> MooseX::DIC::Configuration::ServiceMetadata
requires 'get_service_metadata';

1;
