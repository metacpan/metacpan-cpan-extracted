#!perl -w
use strict;
use DB_File;

my $db = shift;
my %db;
tie( %db, 'DB_File', $db, O_RDONLY)
  or die "couldn't tie '$db': $!'";

print map { "'$_' => '$db{$_}'" } keys %db;
print "\n";
