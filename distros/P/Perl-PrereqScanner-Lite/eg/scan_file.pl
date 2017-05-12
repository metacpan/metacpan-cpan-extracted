#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Perl::PrereqScanner::Lite;

my $scanner = Perl::PrereqScanner::Lite->new;
$scanner->add_extra_scanner('Moose');
my $modules = $scanner->scan_file(__FILE__);
use Data::Dumper; warn Dumper($modules);
