use lib (-e 't' ? 't' : 'test'), 'inc';
use TestModuleCompile tests => 1;

SKIP: {
    eval "require YAML";
    if ($@ or $YAML::VERSION < 0.58) {
        skip "Test requires YAML-0.58 or higher", 1;
    }

    filters {
        pm => ['parse_pm', 'yaml_dump']
    };

    no_diff;

    run_is pm => 'parsed';
}

__DATA__

=== Parse compiler in block scope
--- pm
package Foo;
use strict;
{
    use Module::Compile xxx => 'yyy';

    a = b;
}

c = d;

--- parsed
---
- "package Foo;\nuse strict;\n{\n"
- {}
- []
---
- "\n    a = b;\n}\n\nc = d;\n"
- Module::Compile:
    use: "    use Module::Compile xxx => 'yyy';\n"
-
  - Module::Compile

