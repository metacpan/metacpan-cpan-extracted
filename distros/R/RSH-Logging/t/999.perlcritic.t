#!perl

use Test::More;
eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;
plan skip_all => "Not worrying about perl critic right now.";

