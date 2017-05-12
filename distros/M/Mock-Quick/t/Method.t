#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Lite;
use Test::Exception;

our $CLASS;

BEGIN {
    $CLASS = 'Mock::Quick::Method';
    use_ok($CLASS);
}

tests create => sub {
    my $code = sub { 1 };
    my $obj = $CLASS->new($code);
    isa_ok( $obj, $CLASS );
    is( $CLASS->new($code), $obj, "Building a method with the same sub twice succeeds" );
};

tests error => sub {
    throws_ok { $CLASS->new("foo") } qr/Constructor to $CLASS takes a single codeblock/, "Must be created with codeblock";
};

run_tests;
done_testing;
