# Copyright (c) 2017-2019 Martin Becker.  All rights reserved.
# This script is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/80_documentation.t'

use strict;
use warnings;
use Test::More 0.82;

my $MAKEFILE_PL = 'Makefile.PL';
my $MODULE_PM   = 'lib/Task/Devel/Essentials.pm';

my @installed  = ();
my %documented = ();
my @duplicates = ();

if (!open MF, '<', $MAKEFILE_PL) {
    plan skip_all => "cannot open $MAKEFILE_PL";
}
while (<MF>) {
    if (/^\s*(requires|recommends)\s*'([\w:]+)'\s*=>\s*'?[\d.]+'?\s*;\s*\z/) {
        push @installed, [$2, $1 ne 'requires'];
    }
}
close MF;
if (!@installed) {
    plan skip_all => "could not parse requirements in $MAKEFILE_PL";
}

if (!open PM, '<', $MODULE_PM) {
    plan skip_all => "cannot open $MODULE_PM";
}
while (<PM>) {
    if (/^=item\s+(L<)?(\S+)(?(1)>)(\s*\(optional\))?\s*\z/) {
        if (exists $documented{$2}) {
            push @duplicates, $2;
        }
        else {
            $documented{$2} = defined $3;
        }
    }
}
close PM;
if (!keys %documented) {
    plan skip_all => "could not parse documentation in $MODULE_PM";
}

plan tests => 4;

my (@opt_missing, @opt_wrong) = ();
my (@mod_missing, @mod_wrong) = ();
foreach my $mr (@installed) {
    my ($mod, $opt) = @{$mr};
    if (!exists $documented{$mod}) {
        push @mod_missing, $mod;
        next;
    }
    my $d_opt = $documented{$mod};
    if ($d_opt xor $opt) {
        if ($opt) {
            push @opt_missing, $mod;
        }
        else {
            push @opt_wrong, $mod;
        }
    }
    delete $documented{$mod};
}
@mod_wrong = sort keys %documented;

foreach my $mod (@mod_missing) {
    diag("not documented: $mod");
}
ok(0 == @mod_missing, 'all modules documented');

foreach my $mod (@mod_wrong) {
    diag("not listed: $mod");
}
ok(0 == @mod_wrong, 'all documented modules listed as prerequisites');

foreach my $mod (@duplicates) {
    diag("documented more than once: $mod");
}
ok(0 == @duplicates, 'all modules documented just once');

foreach my $mod (@opt_missing) {
    diag("should be marked optional: $mod");
}
foreach my $mod (@opt_wrong) {
    diag("should not be marked optional: $mod");
}
ok(0 == @opt_missing + @opt_wrong, 'all optional modules correctly flagged');

__END__
