# Net-Connection-Linux_ss

Build Net::Connection objects on Linux using the output from ss.

```perl
use Net::Connection::Linux_ss;

my @objects;
eval{ @objects=&ss_to_nc_objects; };

# this time don't resolve ports or ptrs
my $args={
     ports=>0,
     ptrs=>0,
};
eval{ @objects=&ss_to_nc_objects( $args ); };
```

This parses the output of `ss -p4an` and `ss -p6an`, the ss from iproute2.
Process information beyond what ss itself reports comes from
Proc::ProcessTable and /proc.

## Install

```
perl Makefile.PL
make
make test
make install
```
