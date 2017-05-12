#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 3;
use PAUSE::Permissions;
use Path::Tiny;

#-----------------------------------------------------------------------
# construct PAUSE::Permissions
#-----------------------------------------------------------------------

my $pp = PAUSE::Permissions->new(path => 't/06perms-mini.txt');

ok(defined($pp), "instantiate PAUSE::Permissions");

#-----------------------------------------------------------------------
# construct the iterator
#-----------------------------------------------------------------------
my $iterator = $pp->entry_iterator();

ok(defined($iterator), 'create entry iterator');

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
my $string = '';

while (my $entry = $iterator->next) {
    $string .= $entry->module()
               .','
               .$entry->user()
               .','
               .$entry->permission()
               ."\n";
}

my $expected = path('t/06perms-mini.txt')->slurp;
$expected =~ s/\A.*\n\n//s;
is($string, $expected, "rendered permissions");

