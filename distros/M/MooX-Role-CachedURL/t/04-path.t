#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 2;
use Test::File;
use MooX::Role::CachedURL;

use lib qw(t/lib);
use CPAN::Robots;

my $expected_content = "# Hello Robots!\n# Welcome to CPAN.\n";

my $robots;

eval { $robots = CPAN::Robots->new( path => 't/data/sample-robots.txt') };

ok(defined($robots), "Create instance of class using a local file");

is($robots->content, $expected_content,
   "Local file should match expected content");

