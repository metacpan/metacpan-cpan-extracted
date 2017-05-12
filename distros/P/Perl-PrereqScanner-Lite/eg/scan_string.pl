#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Perl::PrereqScanner::Lite;

my $scanner = Perl::PrereqScanner::Lite->new;
$scanner->add_extra_scanner('Moose');

open my $fh, '<', __FILE__;
my $string = do { local $/; <$fh> };
my $modules = $scanner->scan_string($string);
use Data::Dumper; warn Dumper($modules);
