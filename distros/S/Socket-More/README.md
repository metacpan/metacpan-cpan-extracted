# NAME

Socket::More - Interface scoped passive/listener addressing

# SYNOPSIS

Bring into your namespace. This overrides `socket` also:

```perl
    use v5.36;
    use Socket::More ":all";
```

Or import any of the functions by name:

```perl
    use v5.36;
    use Socket::More qw<getifaddrs sockaddr_passive ...>;
```

Simple list of all network interfaces:

```perl
    #List basic interface information on all available interfaces
    my @ifs=getifaddrs;
    say $_->{name} for @ifs;
```

Flexible way to create interface scoped passive (listen) address across
families. Special 'unix' interface for ease of use. All invalid combinations of
family, port  and paths are discarded:

```perl
    #Create passive (listening) sockets for selected interfaces
    my @passive=sockaddr_passive {
            interface=>     ["eth0", "unix"],
            port=>          [5566, 7788],
            path=> "path_to_sock"
    };
            
    #All invalid family/interface/port/path  combinations are filtered out
    #leaving only valid info for socket creation and binding:
    for(@passive){
            say $_->{address};
            socket my $socket, $_->{family}, $_->{type}, 0;
            bind $socket $_->{addr};
    }
```

# DESCRIPTION

This module makes it easier to generate the data structures to bind multiple
sockets of multiple addresses, types, and families (including unix) on a
particular set of interfaces by name. 

It implements `sockaddr_passive`, which facilitates solutions to requirements
like these:

```
    'listen on interfaces eth0 and eth1, using IPv6 and port numbers 9090
    and 9091, but limit to link local addresses, and stream types'.

    'listen on eth0 and unix, port 1000 and path test.sock, using datagram
    type sockets,'.

    'listen on all interfaces on port 8080 and 8081, but only on link local
    ipv6 address'
```

In addition it also makes it easy to specify multiple listen/passive addresses
from the command line, using concise key/value notation and string to socket
family/type conversions.

It also makes it easy to generate 'random' ports to bind to, **before** your
program binds, to aid in testing scenarios.

Several 'inet.h' and similar routines are also implemented (eg `getifaddrs`,
`if_nametoindex`, `if_indextoname`, `if_nameindex`).

No symbols are exported by default. All symbols can be exported with the ":all"
tag or individually by name.  Please see the [API](https://metacpan.org/pod/API) section for a complete
listing.

# MOTIVATION

I wanted an easy way to listen on a particular interface ONLY.  The normal way
of wild card addresses "0.0.0.0" or "::", will listen on all interfaces. Any
restrictions on connecting sockets will either need to be implemented in the
firewall or in application code accepting and then closing the connection. This
is a waste of resources and a potential security problem.

Manually creating the multitude of potential addresses on the same interface
(especially for IPv6) is a pain to maintain. This module reduces the effort by
generating all combinations of parameters and then filters out what doesn't
make sense and what you don't want

# API

## getifaddrs

```perl
    my @interfaces=getifaddrs;
```

Queries the OS via  `getifaddr` for the list of interfaces currently active.
Returns a list of hash references representing the network interfaces. The keys
of these hashes include:

- name

    The text name of the interface

- flags

    Flags set on the interface

- addr

    Packed sockaddr structure suitable for use with `bind`

- netmask

    Packed sockaddr structure of the netmask

- dstmask

    Packed sockaddr structure of the dstmask

## if\_nametoindex

```perl
    my $index=if_nametoindex($name);
```

Returns the index of an interface by name. If the interface is not found,
returns 0 and sets `$!` with error code.

## if\_indextoname

```perl
    my $name=if_indextoname($index);
```

Returns the name of an interface by index. If the index does not represent an
interface, `undef` is returned and sets `$!` with error code

## if\_nameindex

```perl
    my @pairs=if_nameindex;
```

Returns a list of key value pairs. The key is the interface index, and the
value is the name of the interface.

Return `undef` on error and sets `$!` with error code.

## family\_to\_string

```perl
    my $string=family_to_string($family);
```

Returns a string label representing an address family `$family`. For example,
calling with constant `AF_INET`, will return a string `"AF_INET"`

## string\_to\_family

```perl
    my @family=string_to_family($pattern);
```

Performs a match of all AF\_.\* names against `$pattern`. Returns a list of
integer constants for the corresponding address family that matched. Returns an
empty list if the patten/string does not match.  The match is performed
insensitive to case

For example calling with `"INET"` will return a list of two elements,
`AF_INET` and `AF_INET6`.

This is useful for handling address families supplied from the command line, as
abbreviated names can be matched.

## sock\_to\_string

```perl
    my $string=sock_to_string($type);
```

Returns a string label representing a socket type `$type`. For example,
calling with the integer constant `SOCK_STREAM`, will return a string
`"SOCK_STREAM"`

## string\_to\_sock

```perl
    my @type=string_to_family($string);
```

Performs a match of all SOCK\_.\* names against `$pattern`. Returns a list of
integers for the corresponding socket types that matched. Returns an empty list
if the patten/string does not match. The match is performed insensitive to case.

For example calling with `"STREAM"` will return a list of one element, `SOCK_STREAM`.

This is useful for handling address families supplied from the command line, as
abbreviated names can be matched.

## sockaddr\_passive

```perl
    my @interfaces=sockadd_passive $specification;
```

Returns a list of 'interface' structures (similar to getifaddr above) which
provide meta data and packed address structures suitable for passive use (i.e
bind) and matching the `$specification`. The resulting data is sorted by
interface name, then but family and finally by type.

It has some overlapping function of `getaddrinfo`, however it is specifically
for creating addresses for binding, allows the use of interface names and
operates with UNIX domain configurations through a synthetic  'unix' interface.

A specification hash has optional keys which dictate what addresses are
generated and filtered:

```perl
    {
            interface=>"en",
            family=>"INET",
            port=>[1234]
            ...
    }
```

The only required keys are `port` and/or `path`. These are used in the
address generation and not as a filter. Without at least one of these keys, no
results will be generated. 

Other keys like `interface`, `family`  and `type` for example are used to
restrict addresses created to the match 

Keys like `address` and `group` are a filter which are directly matched
against the address and group.

Keys themselves can be shortened all the way down to the shortest unique
substring. So instead of 'interface', it could be 'inter', 'int' or just 'i'
for example. This aids in usage from the command line. The shortest unique keys
are:

```perl
    {
            i=>...          #interface
            f=>...          #family
            po=>...         #port
            pa=>...         #path
            a=>...          #address
            t=>...          #type
            g=>...          #group
    }
```

It can include the following keys:

- interface

    ```perl
        examples: 
        interface=>"eth0"
        interface=>"eth\d*";
        interface=>["eth0", "lo"];
        interface=>"unix";
        interface=>["unix", "lo"];
    ```

    A string or array ref of strings which are used as regex to match interface
    names currently available.

- familiy

    ```perl
        examples: family=>AF_INET family=>[AF_INET, AF_INET6, AF_UNIX]
    ```

    A integer or array ref of integers representing the family type an interface
    supports.

    **From v0.4.0:** Also can be a string or array ref of strings, which are matched
    against supported families. See `parse_passive_spec` for matching details

- type

    ```perl
        examples: type=>SOCK_STREAM type=>[SOCK_STREAM, SOCK_DGRAM]
    ```

    A integer or array ref of integers representing the socket type an interface
    supports.

    **From v0.4.0:** Also can be a string or array ref of strings, which are matched
    against supported socket types. See `parse_passive_spec` for matching details

- port

    ```perl
        examples: port=>55554 port=>[12345,12346]
    ```

    The ports used in generating a passive address. Only applied to AF\_INET\*
    families. Ignored for others.

    Either `port` or `path` are required, otherwise no addresses will be
    generated.

- path

    ```perl
        examples: path=>"path_to_socket.sock" path=>["path_to_socket1.sock",
        "path_to_socket2.sock"]
    ```

    The path used in generating a passive address. Only applied to AF\_UNIX
    families. Ignored for others.

    Either `port` or `path` are required, otherwise no addresses will be
    generated.

    **NOTE** The actual path resulting from the specification will have a '\_D' or
    '\_S' appended to the path. This is done to ensure sockets of different type
    don't attempt to use the same path.

- address

    ```perl
        exmples: 
                address=>"192\.168\.1\.1" 
                address=>"169\.254\."
    ```

    As string used to match the textual representation of an address. In the
    special case of '0.0.0.0" or "::", any interface specification is ignored.

- group

    ```perl
        examples:
                group=>"PRIVATE'
    ```

    The group the address belongs to as per [Net::IP](https://metacpan.org/pod/Net%3A%3AIP)

- data

    ```perl
        examples: 
        data=>[$scalar]
        data=>[{ ca=>$ca_path, pkey=>$p_path}]
    ```

    A user field which will be included in each item in the output list. 

    **NOTE** It is recommended this value is an array ref, wrapping actual data. This
    makes it more consistent when the data key is parsed from the command line

## parse\_passive\_spec

```perl
    my @spec=parse_passive_spec($string);
```

Parses a concise string intended to be supplied as a command line argument. The
string consists of one or more fields separated by commas.

The fields are in key value pairs in the form

```
    key=value
```

`key` can be any key used in a specification for `sockaddr_passive`, and
`value` is interpreted as a path, number or a string (regex), depending on the
key.

`port` and `path` keys take literal values.

`family` and `type` keys take regex values, which match against the
family/type names (using `string_to_sock` and `string_to_family`) and are
replaced with the integer values internally.

Other keys treat the value as a string/regex to match against.

The keys can be used repeatedly within multiple fields. For example that means
the following  will match interfaces eth0, eth1 and lo.

```perl
    in=>eth0,port=1000,in='lo|eth1'
```

Only the first "=" within a field is split. this allows the data field itself
to take more key value pairs:

```
    eg:
    data=key1=value,data=key2=another
    data=ca=ca_path.pem,data=key=private.pem
```

**NOTE** Because repeat `data` keys can be used, the specification generated from
`parse_passive_spec` will contain a `data` key with an array as its value.

For example, the following parse a `sockaddr_passive` specification which would
match SOCK\_STREAM sockets, for both AF\_INET and AF\_INET6 families, on all
available interfaces.

```
    family=INET,type=STREAM #Full key name
    f=INET,t=STREAM         #Shortest unique string for keys
```

The special case of a field not in key value format (i.e. with out a '='), is
interpreted as the plack compatible listen switch argument.

```
    HOST:PORT               #INET/INET6 address and port
    :PORT                   #wildcard address and port
    PATH                    #UNIX socket path
    
```

The `HOST` portion is assinged to the `address` field. The `PORT` portion is
assigned to the `port` field. If a `PORT` is specified without a `HOST`,
then the `address` field is set to `["0.0.0.0", "::"]` which disables
interface matching, but will listen on all INET addresses.

**NOTE** This behaviour may change in later versions, as  "::" supports both INET
and INET6.

**NOTE** to specify an IPv6 literal on the command line, it is contained in a pair
of \[\] and will need to be escaped or quoted in the shell

## socket

```perl
    socket $socket, $domain_or_addr, $type, $proto


    example:
            die "$!" unless socket my $socket, AF_INET, SOCK_STREAM,0;

            
            die "$!" unless socket my $socket, $sockaddr, SOCK_STREAM,0;
```

A wrapper around `CORE::socket`.  It checks if the `DOMAIN` is a number.  If
so, it simply calls `CORE::socket` with the supplied arguments.

Otherwise it assumes `DOMAIN` is a packed sockaddr structure and extracts the
domain/family field using `sockaddr_family`. This value is then used as the
`DOMAIN` value in a call to `CORE::socket`.

Return values are as per `CORE::socket`. Please refer to ["perldoc -f socket"](#perldoc-f-socket)
for more.

## has\_IPv4\_interface

```
    has_IPv4_interface;
```

Returns true if at least one IPv4 interface was found. False otherwise.

## has\_IPv6\_interface

```
    has_IPv6_interface;
```

Returns true if at least one IPv6 interface was found. False otherwise.

## reify\_ports

```perl
reify_ports $specs, ...

example:
  reify_ports {address=>"127.0.0.1", port=>0}
```

Iterates through list of specifications and replacing `port` fields equal to 0
(any port), with a 'random' one supplied by the operating system. This performs
a `sockaddr_passive` call to to 'flatten' any internal structures in the
specifications provided. 

This works by taking the first entry which results in a 0 port number, creating a
socket and binding it. The 0 port will result in the OS choosing a port for
use.  The resulting port is extracted from the socket (getsocketname) and
replaces the 0 port value in **all** the specification entries. The socket has
`SO_REUSEADDR` applied to ensure it can be bound again immediately.

If the specifications request two or more  0 ports in otherwise identical
specifications, it is up the user to choose how to handle any duplicate bind
complications (i.e `SO_REUSEPORT`)

**NOTE:** There is a chance that another program can use the port number
returned after a call to `reify_ports`.

**NOTE:** The interface/address tested to generate the random port might return
a port which is already in use on other interfaces.

## reify\_ports\_unshared

```perl
  reify_ports_chaos $specs, ...

example:
  reify_ports {address=>"127.0.0.1", port=>[0,0]};
  reify_ports {address=>"127.0.0.1", port=>0}, {port=>0};
```

Operates like `reify_ports` with the exception that all 0 port entries in the
specifications cause a query to the OS. The port numbers are not explicitly
'shared' between specifications, thus returning potentially (most likely)
different port numbers for each entry.

# EXAMPLES

Please checkout 'cli.pl' in the examples directory of this distribution. It
demonstrates many of the features of this module by using the
`sockaddr_passive`, `parse_passive_spec`, `family_to_string` and
`sock_to_string` functions. It requires `Text::Table` in addition to this
module.

It takes user input from the command line using one or more `-l` parameters
via [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong). These are parsed into passive specifications, which are
then executed to generate list of passive structures matching the
specification. The results are converted into nice text table output.

The following shows the example outputs running this program with different
inputs.

## Run1

Any interface, AF\_INET6 only, stream or datagram on port 1000:

```
    perl examples/cli.pl -l '[::]':1000

    Interface Address Family   Group       Port Path Type        Data
    ::        ::      AF_INET6 UNSPECIFIED 1000      SOCK_STREAM
    ::        ::      AF_INET6 UNSPECIFIED 1000      SOCK_DGRAM
```

## Run2

Any interface, AF\_INET only, stream or datagram on port 1000:

```
    ->perl examples/cli.pl -l 0.0.0.0:1000
    Interface Address Family  Group   Port Path Type        Data
    0.0.0.0   0.0.0.0 AF_INET PRIVATE 1000      SOCK_STREAM
    0.0.0.0   0.0.0.0 AF_INET PRIVATE 1000      SOCK_DGRAM
```

## Run3

Any interface, AF\_INET only, stream or datagram on port 1000, with data:

```
    perl examples/cli.pl -l 0.0.0.0:1000,data='ca_path=ca_path.pem;key=key_path'
    Interface Address Family  Group   Port Path Type        Data
    0.0.0.0   0.0.0.0 AF_INET PRIVATE 1000      SOCK_STREAM ca_path=ca_path.pem;key=key_path
    0.0.0.0   0.0.0.0 AF_INET PRIVATE 1000      SOCK_DGRAM  ca_path=ca_path.pem;key=key_path
```

## Run4

On interface en0, port 1000, stream or datagram types and only private or link
local addresses:

```
    perl examples/cli.pl -l interface=en0,port=1000,group='pri|link'

    Interface Address                   Family   Group              Port Path Type        Data
    en0       192.168.1.103             AF_INET  PRIVATE            1000      SOCK_STREAM
    en0       192.168.1.103             AF_INET  PRIVATE            1000      SOCK_DGRAM 
    en0       fe80::1086:a38e:8f5d:38e2 AF_INET6 LINK-LOCAL-UNICAST 1000      SOCK_STREAM
    en0       fe80::1086:a38e:8f5d:38e2 AF_INET6 LINK-LOCAL-UNICAST 1000      SOCK_DGRAM 
```

## Run5

On interface en0,lo and unix, port 1000, path mypath.sock, and stream type only

```perl
    perl examples/cli.pl -l interface='en0|lo|unix',port=1000,path=mypath.sock,type=stream

    Interface Address                   Family   Group              Port Path          Type        Data
    en0       192.168.1.103             AF_INET  PRIVATE            1000               SOCK_STREAM
    en0       fe80::1086:a38e:8f5d:38e2 AF_INET6 LINK-LOCAL-UNICAST 1000               SOCK_STREAM
    lo0       fe80::1                   AF_INET6 LINK-LOCAL-UNICAST 1000               SOCK_STREAM
    unix      mypath.sock_S             AF_UNIX  UNIX                    mypath.sock_S SOCK_STREAM
```

## Run6

Shortened keys. Multiple listeners on command line:

First specification:	Interface en0, port 1000, only AF\_INET and stream 

Second specification:	Interface lo or unix, AF\_INET or UNIX types, po 2000
for inet and path test.sock for unix, datagram type only

```
    perl examples/cli.pl -l i='en0',po=1000,f='inet$',t=stream -l i='lo|unix',f='inet$|unix',po=2000,pa="test.sock",t=dgram

    Interface Address       Family  Group    Port Path        Type        Data
    en0       192.168.1.103 AF_INET PRIVATE  1000             SOCK_STREAM
    lo0       127.0.0.1     AF_INET LOOPBACK 2000             SOCK_DGRAM
    unix      test.sock_D   AF_UNIX UNIX          test.sock_D SOCK_DGRAM
```

## RUN7

Interface en0 and lo, port 1010, private or link local group, multiple data keys

```
    examples/cli.pl -l in=en0,in=lo,po=1010,gr='PRI|link',data=ca=test,data=key=path

    Interface Address                   Family   Group              Port Path Type        Data            
    en0       192.168.1.103             AF_INET  PRIVATE            1010      SOCK_STREAM ca=test,key=path
    en0       192.168.1.103             AF_INET  PRIVATE            1010      SOCK_DGRAM  ca=test,key=path
    en0       fe80::1086:a38e:8f5d:38e2 AF_INET6 LINK-LOCAL-UNICAST 1010      SOCK_STREAM ca=test,key=path
    en0       fe80::1086:a38e:8f5d:38e2 AF_INET6 LINK-LOCAL-UNICAST 1010      SOCK_DGRAM  ca=test,key=path
    lo0       fe80::1                   AF_INET6 LINK-LOCAL-UNICAST 1010      SOCK_STREAM ca=test,key=path
    lo0       fe80::1                   AF_INET6 LINK-LOCAL-UNICAST 1010      SOCK_DGRAM  ca=test,key=path
```

# TODO

- Network interface queries for byte counts, rates.. etc
- Expand address family types support(i.e link)
- Network change events/notifications

# SEE ALSO

Other modules provide network interface queries:
[Net::Interface](https://metacpan.org/pod/Net%3A%3AInterface) seems broken at the time of writing
[IO::Interface](https://metacpan.org/pod/IO%3A%3AInterface) works with IPv4 addressing only?

# AUTHOR

Ruben Westerberg, &lt;drclaw@mac.com&lt;gt>

# REPOSITORTY and BUGS

Please report any bugs via git hub: [http://github.com/drclaw1394/perl-socket-more](http://github.com/drclaw1394/perl-socket-more)

# COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl or the MIT license.

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
