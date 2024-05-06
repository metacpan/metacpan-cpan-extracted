#!/usr/bin/perl
use Test::More;
use ExtUtils::Manifest qw(filecheck manicheck);
BEGIN {
	plan skip_all => "set RELEASE_TESTING to test"
		unless $ENV{RELEASE_TESTING};
}

is_deeply([filecheck()], [], "all files in tree listed in manifest");
is_deeply([manicheck()], [], "all files in manifest exists in tree");

done_testing();
