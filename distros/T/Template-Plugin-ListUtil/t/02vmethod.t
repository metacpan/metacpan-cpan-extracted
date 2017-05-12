#!/usr/bin/perl

# this is so cheeky I can't belive it.

use strict;
use warnings;

use IO::File;
use FindBin;
use File::Spec::Functions;

use Template::Plugin::ListUtilVMethods 'install';

# read in the other test file
my $fh = IO::File->new(catfile($FindBin::Bin,"01basic.t"))
  or die "Can't open other test file";
local $/ = undef;
my $string = <$fh>;

# make them all vmethods
$string =~ s/ListUtil\.(.*?)\((.*?)\)/$2.$1/g;

# and run the tests
eval $string;
