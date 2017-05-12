#!/usr/bin/env perl


use lib qw{ ./t/lib blib/lib };

$ENV{TEST_METHOD} = '.*split_ascii_domain_tld';

use ParseDomain;
ParseDomain->runtests();

