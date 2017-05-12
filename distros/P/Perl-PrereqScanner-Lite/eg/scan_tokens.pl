#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Compiler::Lexer;

use Perl::PrereqScanner::Lite;

my $scanner = Perl::PrereqScanner::Lite->new;
$scanner->add_extra_scanner('Moose');

open my $fh, '<', __FILE__;
my $string = do { local $/; <$fh> };
my $tokens = Compiler::Lexer->new->tokenize($string);

my $modules = $scanner->scan_tokens($tokens);
use Data::Dumper; warn Dumper($modules);
