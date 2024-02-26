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

### Gneral Flags

```
   -r <file>
       The file to read/run.

   -o <format>
       The output format.

       Default: json

       Formats: json,yaml,toml,dumper(Data::Dumper),shell,multi

       'multi' will write out JSON, YAML, TOML, to respectively named dirs.
       The -d can be used to specify the base dir, otherwise './' is used like
       below.

           ./json_confs
           ./shell_confs
           ./toml_confs
           ./yaml_confs

       Multi also requires --cmdb_host to be defined or to be findable via
       --tcmdb.

   -d <multi output base dir>
       When using multi, this is the base directory used.

       Default: .

   -p
       Pretty print. Not relevant to all outputs.

   -s
       Sort. Not relevant to all outputs.

   -i <include>
       Files to parse and include in the produced JSON, TOML, or YAML.

       The included file may be either JSON, TOML, or YAML.

       If a comma is included, everything before the comma is used as the key
       name to include the parsed data as. Otherwise it will me merged.

       Include Examples...

           Read in bar.json and include it as the variable foo.
           -i foo,bar.json

           Read in foo.toml and merge it with what it is being merged into taking presidence.
           -i foo.toml

           Read in a.json and merge it, then read in in b.json and merge it.
           -i a.jsom -i b.toml
```

### Munging Flags

```
   -m <munger>
       File containing code to use for munging data prior to output. The file
       will be read in and ran via eval.

       The following are accessible and usable from with in it.

           $found_Vars :: Hash reference containing the found variables with everything merged into it.
           $format :: The output format to use.
           $host_Vars :: The value of --host_vars .
           @includes :: A array of containing the various values for -i .
           $merger :: A Hash::Merge->new('RIGHT_PRECEDENT') object.
           $munger_file :: The value of -m if specified.
           $pretty :: If -p was specified or not.
           $sort :: If -s was specified or not.
           $tcmdb :: Path to the Rex TOML CMDB if specified.
           $to_read :: The value of -r .
           $use_roles :: The value of --use_rules .

       To lets say you wanted to delete the variable 'foo', you could do it
       like below.

           delete($found_vars->{foo});

       Or if wanted to set .suricata.enable and a few others based on
       .SURICATA_INSTANCE_COUNT you could do it like below.

           if ($found_vars->{SURICATA_INSTANCE_COUNT}) {
               $found_vars->{suricata}{enable}=1;
               $found_vars->{suricata_extract}{enable}=1;
               $found_vars->{snmpd}{extends}{suricata}{enable}=1;
               $found_vars->{snmpd}{extends}{suricata_extract}{enable}=1;
           }
```

### CMDB Flags

```
   --tcmdb <dir>
       Optionally include data from a Rex CMDB.

       $tcmdb.'/.cmdb_type' contians the CMDB type to use. Lines matching /^#/
       or /^[\ \t]$/ are ignored. The first line not matching those is used as
       the value to use for Rex CMDB.

       If that file does not exist, TOML, is used. For more info see
       Rex::CMDB::TOML.

   --cmdb_env <env>
       Environment name to use with the CMDB.

       Default :: undef

   --env_var <vars>
       If --cmdb_env is undef, check this comma seperated list JSON Paths in
       the currently found/included vars for the first possible hit.

       Default :: SYSTEM_ENV

   --cmdb_host <host>
       Hostname to use when querying the CMDB.

       Default :: undef

   --host_vars <vars>
       If --cmdb_host is undef, check this comma seperated list JSON Paths in
       the currently found/included vars for the first possible hit. For more
       info the path stuff, see JSON::Path.

       Default ::
       HOSTNAME,REX_NAME,REX_HOSTNAME,ANSIBLE_HOSTNAME,ANSIBLE_NAME,NAME

   --use_roles [01]
       If roles should be used or not with the Rex TOML CMDB.

       Default :: 1
```

## src_bin/cmdb_shell_var_reader

```
   --verbose <0/1>
       A boolean value for if it should be verbose or not.

       Default :: 1

   -d <dir>
       The directory to operate on. If undef, it will check the following
       directories for the file '.shell_var_reader'.

         ./
         ../
         ../../
         ../../../
         ../../../../
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

Other directories that that don't start with a '.' or contiain a file
named '.not_a_system_group' will be processed as system groups.

These directories will be searched for files directly below them for
files ending in '.sh' and not starting with either a '_' or a '.'. The
name used for a system is the name of the file minus the ending '.sh',
so 'foo.bar.sh' would generate a config for a system named 'foo.bar'.

When it finds a file to use as a system config, it will point
shell_var_reader at it with CMDB enabled and with the name of that
system set the hostname to use with the CMDB. That name will also be
saved as the variable 'SYSTEM_NAME', provided that variable is not
defined already. If a 'munger.pl' exists, that file is used as the
munger file. shell_var_reader will be ran four times, once to generate
each config type.

The CMDB type is control by `cmdb/.cmdb_type`. Setting the contents to
for example `YAMLwithRoles` will cause `YAMLwithRoles` to be used as
the CMDB.

```
   ,-----------------------------------------------------.                                                                    
   |shell_conf                                           |                                                                    
   |-----------------------------------------------------|                                                                    
   |./$group/$system.sh                                  |                                                                    
   |ran under ./$group/                                  |                                                                    
   |                                                     |                                                                    
   |Dirs matching ./$dir/.not_a_system_group are ignored.|                                                                    
   `-----------------------------------------------------'                                                                    
                               |                                                                                              
                               |                                                                                              
               ,------------------------------.  ,-------------------.   ,---------------------------------------------------.
               |CMDB                          |  |CMDB_YAMLwithRoles |   |CMDB_YAMLwithRoles_Roles                           |
               |------------------------------|  |-------------------|   |---------------------------------------------------|
               |Rex CMDB under ./cmdb         |--|cmdb/{$system}.yaml|---|.roles variable read and roles/$role.yaml merged in|
               |Settable via ./cmdb/.cmdb_type|  |cmdb/default.yaml  |   `---------------------------------------------------'
               `------------------------------'  `-------------------'                                                        
                               |                                                                                              
,------------------------------------------------------------.                                                                
|munger                                                      |                                                                
|------------------------------------------------------------|                                                                
|$found_vars hash ref                                        |                                                                
|Any changes to it will be reflected in the generated output.|                                                                
`------------------------------------------------------------'                                                                
                               |                                                                                              
                                                                                                                              
                       ,-------------.                                                                                        
                       |end          |                                                                                        
                       |-------------|                                                                                        
                       |write file(s)|                                                                                        
                       `-------------'                                                                                        

```

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
- Rex::CMDB::YAMLwithRoles
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
