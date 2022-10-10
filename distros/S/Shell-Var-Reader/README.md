# Shell-Var-Reader

Lets say '/usr/local/etc/someconfig.conf' which is basically a shell
config and read via include in a sh or bash script, this can be used
for getting a hash ref conttaining them.

Similarly on systems like FreeBSD, this is also useful for reading
'/etc/rc.conf'.

As it currently stands, it does not understand bash arrays.

```
use Shell::Var::Reader;
use Data::Dumper;

my $found_vars=Shell::Var::Reader->read_in('/usr/local/etc/someconfig.conf');

print Dumper($found_vars);
```

## bin/shell_var_reader

This script allows for easy reading of a shells script/config and then
outputing it in a desired format.

```
-r <file>     File to read/run
-o <format>   Output formats
              Default: json
              Formats: json,yaml,toml,dumper(Data::Dumper)
-p            Pretty print
-s            Sort

-h/--help     Help
-v/--version  Version
```

## building

```
perl Makefile.PL
make
make test
make install
```
