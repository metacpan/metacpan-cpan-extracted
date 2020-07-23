#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
 
BEGIN { plan skip_all => 'TEST_AUTHOR not enabled' if not $ENV{TEST_AUTHOR}; }
use Test::CPAN::Changes;
use Role::Declare;

changes_file_ok('CHANGES', { version => Role::Declare->VERSION });
done_testing();
