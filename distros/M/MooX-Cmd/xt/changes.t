#!perl

use strict;
use warnings;

use Test::More;
use Test::CPAN::Changes;

# Skip when running from source tree ({{$NEXT}} placeholder present)
my $changes = do { local $/; open my $fh, '<', 'Changes' or die $!; <$fh> };
plan skip_all => 'Changes contains dzil placeholder' if $changes =~ /\{\{\$NEXT\}\}/;

changes_ok();
