Net::DNS::Create
================

### Create DNS configurations from a nice Perl structure based DSL.

Net::DNS::Create lets you specify your DNS configuration in a Perl script so
that all the duplication that normally occurs in DNS config files can be
expressed with variables and functions. This ultimately results in a
(hopefully) DRY (Don't Repeat Yourself) representation of your DNS config
data, making it easier and less error prone to change.

Net::DNS::Create supports multiple backends which means you can change out
your DNS server software with minimal effort.

Backends are provided for:

  * [Bind](https://www.isc.org/downloads/bind/)
  * [TinyDNS](http://cr.yp.to/djbdns.html)
  * [Route53](https://aws.amazon.com/route53/)

Installation
------------

To install this module type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Documentation
-------------

Before installing:

    perldoc lib/Net/DNS/Create.pm

After installing:

    man Net::DNS::Create

Dependencies
------------

This module requires these other modules and libraries:

  * Module::Build
  * Test::More
  * Hash::Merge::Simple
  * Net::DNS
  * Net::Amazon::Route53
  * LWP::Protocol::https


Copyright And Licence
---------------------

Copyright © 2009-2014 by David Caldwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
