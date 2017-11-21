#!perl

use strict;
use warnings;
use utf8;
use FindBin;

use lib "$FindBin::Bin/..";

use lib "$FindBin::Bin/../lib";
use Perl::PrereqScanner::Lite;

use t::Util;
use Test::More;
use Test::Deep;

my $scanner = Perl::PrereqScanner::Lite->new({no_prereq => 1});

my $got = $scanner->scan_module('Perl::PrereqScanner::Lite');
cmp_deeply(get_reqs_hash($got), {
    "Compiler::Lexer"                      => 0,
    "Module::Path"                         => 0,
    "Perl::PrereqScanner::Lite::Constants" => 0,
    perl                                   => "5.008005",
    strict                                 => 0,
    warnings                               => 0,
    "CPAN::Meta::Requirements"             => 0,
    Carp                                   => 0,
});

done_testing;

