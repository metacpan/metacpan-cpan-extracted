# Net-Connection-FreeBSD_sockstat

Creates Net::Connection objects using sockstat on FreeBSD.

```perl
    use Net::Connection::FreeBSD_sockstat;
    
    my @objects;
    eval{ @objects=&sockstat_to_nc_objects; };

    # this time don't resolve ports, ptrs, or usernames
    my $args={
         ports=>0,
         ptrs=>0,
    };
    eval{ @objects=&sockstat_to_nc_objects( $args )); };
```

# INSTALLATION

To install this module, run the following commands:

```shell
	perl Makefile.PL
	make
	make test
	make install
```
