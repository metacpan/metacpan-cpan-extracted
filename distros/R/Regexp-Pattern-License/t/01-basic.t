#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Regexp::Pattern;

dies_ok { re("License::foo") } "get unknown -> dies";

subtest "get" => sub {
	my $re1 = re("License::fsful");
	ok $re1;
	ok( 'This configure script is free software; the Free Software Foundation gives unlimited permission to copy, distribute and modify it.'
			=~ $re1 );
	ok( !( 'foo' =~ $re1 ) );
};

# TODO
#subtest "get dynamic" => sub {
#	my $re3a = re( "License::re3", variant => 'A' );
#	ok $re3a;
#	ok( '123-456' =~ $re3a );
#	ok( !( 'foo' =~ $re3a ) );
#	my $re3b = re( "License::re3", variant => 'B' );
#	ok $re3b;
#	ok( '123-45-67890' =~ $re3b );
#	ok( !( '123-456' =~ $re3b ) );
#};

done_testing;
