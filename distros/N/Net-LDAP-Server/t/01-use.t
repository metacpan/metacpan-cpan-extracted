#!/usr/bin/perl

use strict;
use warnings;

use Test;
BEGIN { plan tests => 1 }

use ExtUtils::testlib;
use Net::LDAP::Server;
ok eval "require Net::LDAP::Server";

1;
