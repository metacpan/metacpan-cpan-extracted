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

## src_bin/shell_var_reader

This script allows for easy reading of a shells script/config and then
outputing it in a desired format.

```
-r <file>     File to read/run
-o <format>   Output formats
              Default: json
              Formats: json,yaml,toml,dumper(Data::Dumper),shell
-p            Pretty print
-s            Sort
-i <include>  Include file info. May be used multiple times.
-m <munger>   File containing code to use for munging data prior to output.

--tcmdb <dir>       Optionally include data from a Rex TOML CMDB.
--cmdb_host <host>  Hostname to use when querying the CMDB.
                    Default :: undef
--host_vars <vars>  If --cmdb_host is undef, check this comma seperated
                    list JSON Paths in the currently found/included vars
                    for the first possible hit.
                    Default :: HOSTNAME,REX_NAME,REX_HOSTNAME,ANSIBLE_HOSTNAME,ANSIBLE_NAME,NAME
--use_roles [01]    If roles should be used or not with the Rex TOML CMDB.
                    Default :: 1

-h/--help     Help
-v/--version  Version


Include Examples...
-i foo,bar.json       Read in bar.json and include it as the variable foo.
-i foo.toml           Read in foo.toml and merge it with what it is being merged into taking presidence.
-i a.jsom -i b.toml   Read in a.json and merge it, then read in in b.json and merge it.
```

## src_bin/cmdb_shell_var_reader

```
-a <action>       The action to perform.
                  Default :: undef

--verbose <0/1>   A boolean value for if it should be verbose or not.
                  Default :: 1

-d <dir>          The directory to operate on.
                  Default :: undef

--eo <0/1>        If it is okay if stuff already exists when doing the init
                  action. This just means it wont die if the directory
                  already exists. It wont overwrite anything.
                  Default :: 1

--group <group>   The name to use example system group to use for with the init action.
                  Default :: example

ACTIONS
init :: Creates the directory structure and files it with some example files.
update :: Looks for system group directories and processes each system config found under it.
```

### shell_var_reader CMDB layout

Specifically named files.

    - .shell_var_reader :: Marks the base directory as being for a shell_var_reader CMDB.

Specifically named directories.

    - cmdb :: The TOML CMDB directory.
    - json_confs :: Generated JSON confs.
    - shell_confs :: Generated shell confs.
    - toml_confs :: Generated TOML confs.
    - yaml_confs :: Generated YAML confs.

Other directories that that don't start with a '.' or contiain a file named '.not_a_system_group'
will be processed as system groups.

These directories will be searched for files directly below them for files ending in '.sh' and not
starting with either a '_' or a '.'. The name used for a system is the name of the file minus the ending
'.sh', so 'foo.bar.sh' would generate a config for a system named 'foo.bar'.

When it finds a file to use as a system config, it will point shell_var_reader at it with TOML CMDB enabled
and with the name of that system set the hostname to use with the TOML CMDB. That name will also be saved as
the variable 'SYSTEM_NAME', provided that variable is not defined already. If a 'munger.pl' exists, that file
is used as the munger file. shell_var_reader will be ran four times, once to generate each config type.

## Integration With Ansible

This may easily be integrated with ansible such as like below.

```yaml
- hosts: "{{ host }}"
  var_files:
    - ./json_confs/{{ inventory_hostname }}.json
```

And can easily be pushed out to servers like below, allowing scripts
etc to easily make use of the generated configs.

```
- hosts: "{{ host }}"
  order: sorted
  gather_facts: false
  ignore_errors: true
  ignore_unreachable: true
  become: true
  become_method: sudo
  serial: 1

  tasks:
  - name: Copy System JSON Conf Into Place
    ansible.builtin.copy:
      src: ./json_confs/{{ inventory_hostname }}.json
      dest: /usr/local/etc/system.json

  - name: Copy System Shell Conf Into Place
    ansible.builtin.copy:
      src: ./shell_confs/{{ inventory_hostname }}.conf
      dest: /usr/local/etc/system.conf

  - name: Copy System YAML Conf Into Place
    ansible.builtin.copy:
      src: ./yaml_confs/{{ inventory_hostname }}.yaml
      dest: /usr/local/etc/system.yaml

  - name: Copy System TOML Conf Into Place
    ansible.builtin.copy:
      src: ./toml_confs/{{ inventory_hostname }}.toml
      dest: /usr/local/etc/system.toml
```

## Integration With Rex

```perl
set cmdb => {
              type           => 'TOML',
              path           => ./cmdb/,
              merge_behavior => 'LEFT_PRECEDENT',
              use_roles      => 1,
            };

desc 'Upload Server Confs';
task 'upload_server_confs', group => 'all', sub {
    my $remote_hostname=connection->server;

    file '/usr/local/etc/system.toml',
        source => './toml_confs/'.$remote_hostname.'.toml';

    file '/usr/local/etc/system.yaml',
        source => './yaml_confs/'.$remote_hostname.'.yaml';

    file '/usr/local/etc/system.json',
        source => './json_confs/'.$remote_hostname.'.json';

    file '/usr/local/etc/system.sh',
        source => './shell_confs/'.$remote_hostname.'.sh';
};
```

## Install

Perl depends are as below.

- Data::Dumper
- File::Slurp
- Hash::Flatten
- JSON
- JSON::Path
- Rex
- Rex::CMDB::TOML
- String::ShellQuote
- TOML
- YAML::XS

None Perl depends are as below.

- libyaml

### FreeBSD

1. `pkg install p5-Data-Dumper p5-File-Slurp p5-Hash-Flatten p5-JSON
p5-JSON-Path p5-Rex p5-String-ShellQuote p5-TOML p5-YAML-LibYAML p5-App-cpanminus`
2. `cpanm Shell::Var::Reader`

### Debian

1. `apt-get install libfile-slurp-perl libhash-flatten-perl libjson-perl libjson-path-perl
libstring-shellquote-perl libtoml-perl libyaml-libyaml-perl cpanminus`
2. `cpanm Shell::Var::Reader`

### Source

```shell
perl Makefile.PL
make
make test
make install
```
