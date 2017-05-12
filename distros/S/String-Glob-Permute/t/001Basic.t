# Copyright (c) 2008 Yahoo! Inc. All rights reserved. The copyrights to
# the contents of this file are licensed under the Perl Artistic License
# (ver. 15 Aug 1997).
######################################################################
# Test suite for String::Glob::Permute
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;

plan tests => 15;

use String::Glob::Permute qw(string_glob_permute);

my $pattern = "host{foo,bar}[2-4]";

my @hosts = string_glob_permute( $pattern );

is($hosts[0], "hostfoo2");
is($hosts[1], "hostbar2");
is($hosts[2], "hostfoo3");
is($hosts[3], "hostbar3");
is($hosts[4], "hostfoo4");
is($hosts[5], "hostbar4");
is(scalar @hosts, 6);

$pattern = "host[1-3,5,10]";
@hosts = string_glob_permute( $pattern );

is($hosts[0], "host1");
is($hosts[4], "host10");

@hosts = string_glob_permute( "host[08-09,10]" );
is($hosts[0], "host08");
is($hosts[1], "host09");
is($hosts[2], "host10");

@hosts = string_glob_permute( "host[8-9,10]" );
is($hosts[0], "host8");
is($hosts[1], "host9");
is($hosts[2], "host10");
