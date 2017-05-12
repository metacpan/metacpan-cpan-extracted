#!/usr/bin/perl 
use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::DataDirs;
use Test::More;
use File::Spec;

# The OO API

my $tdd = Test::DataDirs->new;

isa_ok $tdd, 'Test::DataDirs';

my %D = $tdd->hash;

sub path { [File::Spec->splitdir(shift),@_] } # Convenience function

is_deeply path($D{data_dir}), path($Bin, qw(data tdd-001)), 
    "\$D{data_dir} is set correctly";
ok -d $D{data_dir}, "$D{data_dir} exists and is a directory";

is_deeply path($D{temp_dir}), path($Bin, qw(temp tdd-001)), "\$D{temp_dir} is set correctly";
ok -d $D{temp_dir}, "$D{temp_dir} exists and is a directory";

done_testing;

# FIXME More testing required.
