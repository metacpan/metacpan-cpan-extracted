# Rex-CMDB-YAMLwithRoles

YAML based CMDB provider for Rex with support for roles.

```perl
use Rex::CMDB;
 
set cmdb => {
    type           => 'YAMLwithRoles',
    merge_behavior => 'LEFT_PRECEDENT',
	path           => 'path/to/cmdb',
	use_roles      => 1,
};

task 'prepare', 'server1', sub {
    my $all_information          = get cmdb;
    my $specific_item            = get cmdb('item');
    my $specific_item_for_server = get cmdb( 'item', 'server' );
};
```

# ROLES

If use_roles has been set to true, when loading a config file, it will
check for value 'roles' and if that value is a array, it will then go
through and look foreach of those roles under the roles_path.

So lets say we have the config below.

```yaml
foo: "bar"
ping: "no"
roles:
  - 'test'
```

It will then load look under the roles_path for the file 'test.yaml', which with
the default settings would be 'cmdb/roles/test.yaml'.

Lets say we have the the role file set as below.

```yaml
ping: "yes"
ping_test:
    misses: 3
```

This means with the value for ping will be 'no' as the default of
'yes' is being overriden by the config value.

Somethings to keep in mind when using this.

- 1: Don't define a value you intend to use in a role in any of the
  config files that will me merged unless you want it to always
  override anything a role may import. So with like the example above,
  you would want to avoid putting ping='no' in the default yaml file
  and only set it if you want to override that role in like the yaml
  config for that host.

- 2: Roles may not include roles. While it won't error or the like,
  they also won't be reeled in.
