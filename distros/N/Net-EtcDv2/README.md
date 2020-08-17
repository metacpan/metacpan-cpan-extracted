# Net::EtcDv2

A Perl module to use the EtcD version 2 API

## SUMMARY

This module is an OO interface to the EtcD key/value system using the v2 API.

The Net::EtcDv2 module allows code to create, read, update, and delete
key/value data in an etcd cluster. Additionally, using the v2 API, this module
can create, list, and delete directories in the key store to organize the data.

Additionally, this module can manage users and roles, which govern the access
rights to the key/value heirarchy.

** NOTE **: This module is undef heavy development! Right now it can do the
the following:

- Create and Destroy directories
- Stat items and list their ACLs
- List items and children

** TODO **:
- Better test tree recursion
- Create, read, delete, and modify keys
- Create, list, delete, and modify users
- Create, list, modify, and delete roles

## INSTALLATION

To install this module, run the following commands:

```sh
perl Makefile.PL
make
make test
make install
```

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

```sh
perldoc Net::EtcDv2
```

You can also look for information at:

- AnnoCPAN, Annotated CPAN documentation
  - http://annocpan.org/dist/Net-EtcDv2

- CPAN Ratings
  - https://cpanratings.perl.org/d/Net-EtcDv2

- Search CPAN
  - https://metacpan.org/release/Net-EtcDv2

## LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Gary L. Greene, Jr.

This is free software, licensed under the Apache License, Version 2.0.
