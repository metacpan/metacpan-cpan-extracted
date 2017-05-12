# DESCRIPTION

Morpheus is a configuration engine that completely separates config consumers from config providers.

Consumers can obtain configuration values by using this module or *morph* script.
Configuration values are binded to various nodes in the global config tree, similar to virtual file system. Consumers can ask for any node or for any subtree.

Providers are plugins which can populate configuration tree from any sources: local configuration files, configuration database, environment, etc.
The overall program configuration is merged together from all data provided by plugins.

# CONFIGURATION TREE

Every config value is binded to a key inside the global configuration tree. Keys use */* as a separator of their parts, similar to usual filesystem conventions.

Any value which is a hashref will become the subtree in the configuration tree and will be merged with other values if possible. For example, if one plugin provides *{ foo => 5 }* for */blah* key, and another plugin provides *{ bar => 6 }* for */blah* key, then *morph("/blah")* will return *{ foo => 5, bar => 6 }*.
