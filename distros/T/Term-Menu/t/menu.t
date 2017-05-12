#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

eval("use Test::Expect");
if($@) {
	plan skip_all => "Couldn't load Test::Expect";
	exit;
}

plan tests => 10;

## First we find the Expect.pl file.
my $expect_location;
for(qw( ./ ../ ../../ ./t/ ../t/ ../../t/ )) {
	if(-e $_."Expect.pl") {
		$expect_location = $_."Expect.pl";
		last;
	}
}

if(!defined($expect_location)) {
	plan skip_all => "Can't find the Expect file";
	exit;
}

require_ok("Term::Menu");

expect_run(
	command => "perl $expect_location",
	prompt	=> "test: ",
	quit	=> "q",
);

expect("a", "ok", "Giving a good answer");
expect("5", "error", "Giving a bad answer");
expect_send("abcdefg", "Asking a small question");
expect_like(qr/ok\n\na\)\nb\)/, "Giving a first");
expect("b", "ok", "Answering the order question");
