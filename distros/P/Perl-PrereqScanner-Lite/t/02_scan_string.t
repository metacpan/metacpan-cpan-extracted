#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/..";

use File::Spec::Functions qw/catfile/;
use Perl::PrereqScanner::Lite;

use t::Util;
use Test::More;

my $scanner = Perl::PrereqScanner::Lite->new({no_prereq => 1});

my $got = $scanner->scan_string(slurp(catfile($FindBin::Bin, 'resources', 'basic.pl')));
prereqs_ok($got);

done_testing;

