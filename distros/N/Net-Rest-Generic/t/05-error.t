#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 10;

use_ok( 'Net::Rest::Generic::Error' ) || print "Bail out!\n";

my $default = Net::Rest::Generic::Error->throw();
isa_ok($default, 'Net::Rest::Generic::Error', 'able to throw an error with no arguments');
is($default->message, 'unknown', 'error object returned expected message');
is($default->category, 'object', 'error object returned expected category');
is($default->type, 'fail', 'error object returned expected type');

my $error = Net::Rest::Generic::Error->throw(
	category => 'http',
	message  => 'dang it',
	type     => '501',
);

isa_ok($error, 'Net::Rest::Generic::Error');

my $category = $error->category;
is($category, 'http', 'error object returned expected category');

my $message  = $error->message;
is($message, 'dang it', 'error object returned expected message');

my $type     = $error->type;
is($type, '501', 'error object returned expected type');

my $error_hash = Net::Rest::Generic::Error->throw({
	category => 'http',
	message  => 'dang it',
	type     => '501',
});

is($error_hash->category, 'http', 'creating object with arguments as hashref succeeds');

1;
