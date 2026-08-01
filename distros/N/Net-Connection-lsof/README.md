# Net-Connection-lsof

Uses lsof to generate a array of Net::Connection objects.

```perl
    use Net::Connection::lsof;

    my @objects;
    eval{ @objects = &lsof_to_nc_objects; };

    # this time don't resolve ports, ptrs, or usernames
    my $args={
             ports=>0,
             ptrs=>0,
             uid_resolve=>0,
             };
    eval{ @objects = &lsof_to_nc_objects($args); };
```

# INSTALLATION

To install this module, run the following commands:

```shell
	perl Makefile.PL
	make
	make test
	make install
```
