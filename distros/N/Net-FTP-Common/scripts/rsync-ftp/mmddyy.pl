#!/Users/metaperl/install/bin/perl

use Date::Business;

my $d = Date::Business->new;

my ($yyyy,$mm,$dd) = $d->image =~ /(\d{4})(\d{2})(\d{2})/ ;

print "$mm-$dd-$yyyy";
