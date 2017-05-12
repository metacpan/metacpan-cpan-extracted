#!perl
use Test::More tests => 6;
use warnings;
use strict;

use Test::Exception;

BEGIN { use_ok('Net::Fritz::Error') };


### public tests

subtest 'check error getter' => sub {
    # given
    my $text = 'some_exception_text';
    my $error = new_ok( 'Net::Fritz::Error', [ $text ] );

    # when
    my $result = $error->error;

    # then
    is( $result, $text, 'Net::Fritz::Error->error' );
};

subtest 'check errorcheck()' => sub {
    # given
    my $text = 'some other exception';
    my $error = new_ok( 'Net::Fritz::Error', [ error => $text ] );

    # when/then
    throws_ok { $error->errorcheck() } qr/$text/, 'error text thrown on die()';
};

subtest 'check dump()' => sub {
    # given
    my $text = 'SOME_OTHER_ERROR';
    my $error = new_ok( 'Net::Fritz::Error', [ $text ] );

    # when
    my $dump = $error->dump();

    # then
    like( $dump, qr/Net::Fritz::Error/, 'class name is dumped' );
    like( $dump, qr/$text/, 'errortext is dumped' );
};


### internal tests

subtest 'check new() with named parameter' => sub {
    # given
    my $text = 'SOME_ERROR';

    # when
    my $error = new_ok( 'Net::Fritz::Error', [ error => $text ] );

    # then
    is( $error->error, $text, 'Net::Fritz::Error->error' );
};

subtest 'check new() with single parameter' => sub {
    # given
    my $text = 'ERROR! ERROR! ERROR!';

    # when
    my $error = new_ok( 'Net::Fritz::Error', [ $text ] );

    # then
    is( $error->error, $text, 'Net::Fritz::Error->error' );
};
