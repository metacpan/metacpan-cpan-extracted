#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 3;
use PAUSE::Permissions;

#-----------------------------------------------------------------------
# construct PAUSE::Permissions
#-----------------------------------------------------------------------

my $pp = PAUSE::Permissions->new(path => 't/06perms-mini.txt');

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
    $string .= 'module='.($entry->name // 'undef')."\n"
               .'owner='.($entry->owner // 'undef')."\n"
               .'co-maints='.join(' ', $entry->co_maintainers)."\n"
               ."----\n"
               ;
}

my $expected = <<'END_EXPECTED';
module=constant
owner=SAPER
co-maints=P5P PERL
----
module=constant::Atom
owner=JOHNWRDN
co-maints=NEILB
----
module=Math::Complex
owner=RAM
co-maints=JHI PERL ZEFRAM
----
module=CPAN::Test::Reporter
owner=undef
co-maints=SKUD
----
module=Test::Cucumber
owner=SARGIE
co-maints=JOHND
----
END_EXPECTED

is($string, $expected, "rendered permissions");

