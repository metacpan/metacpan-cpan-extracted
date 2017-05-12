#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More 0.88 tests => 3;
use PAUSE::Permissions;

#-----------------------------------------------------------------------
# construct PAUSE::Permissions
#-----------------------------------------------------------------------

my $pp;
my $cache_path = 'ppcache.txt';

SKIP: {
    skip("looks like you're offline", 3) if $@;

    eval { $pp = PAUSE::Permissions->new(cache_path => $cache_path); };

    ok(defined($pp), "instantiate PAUSE::Permissions");

    #-----------------------------------------------------------------------
    # construct the iterator
    #-----------------------------------------------------------------------
    my $iterator = $pp->module_iterator();

    ok(defined($iterator), 'create module iterator');

    #-----------------------------------------------------------------------
    #-----------------------------------------------------------------------
    my $string = '';

    while (my $entry = $iterator->next_module) {
        next unless $entry->name =~ /^enum/i;

        $string .= 'module='.($entry->name // 'undef')."\n"
                   ."----\n"
                   ;
    }

    my $expected = <<'END_EXPECTED';
module=enum
----
module=Enum
----
module=enum
----
module=enum::fields
----
module=enum::fields::extending
----
module=enum::hash
----
module=enum::prefix
----
module=EnumElement
----
module=Enumerable
----
module=Enumerate::PerlList
----
module=Enumeration
----
module=EnumType
----
END_EXPECTED

    is($string, $expected, "rendered permissions");

    unlink($cache_path) if -f $cache_path;
}
