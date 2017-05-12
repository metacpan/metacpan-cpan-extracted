#!perl
use Test::More tests => 7;
use warnings;
use strict;

BEGIN { use_ok('Net::Fritz::Data') };


### public tests

subtest 'check data getter' => sub {
    # given
    my $value = 'barf00';
    my $data = new_ok( 'Net::Fritz::Data', [ data => $value ] );

    # when
    my $result = $data->data();

    # then
    is( $result, $value, 'Net::Fritz::Data->data');
};

subtest 'check get()' => sub {
    # given
    my $value = 'FOObar';
    my $data = new_ok( 'Net::Fritz::Data', [ $value ] );

    # when
    my $result = $data->get();

    # then
    is( $result, $value, 'Net::Fritz::Data->get');
};

subtest 'check dump_without_indent()' => sub {
    # given
    my $data = new_ok( 'Net::Fritz::Data', [ 'TEST VALUE' ] );

    # when
    my $dump = $data->dump();

    # then
    foreach my $line ((split /\n/, $dump, 2)) {
	like( $line, qr/^(Net::Fritz|----)/, 'line starts as expected' );
    }

    like( $dump, qr/Net::Fritz::Data/, 'class name is dumped' );
    like( $dump, qr/TEST VALUE/, 'data is dumped' );
};

subtest 'check dump_with_indent()' => sub {
    # given
    my $data = new_ok( 'Net::Fritz::Data', [ 'TEST VALUE' ] );

    # when
    my $dump = $data->dump('xxx');

    # then
    foreach my $line ((split /\n/, $dump, 2)) { # only check first two lines!
	like( $line, qr/^xxx/, 'line starts with given indent' );
    }
};


### internal tests

subtest 'check new() with named parameters' => sub {
    # given
    my $value = 'foo';

    # when
    my $data = new_ok( 'Net::Fritz::Data', [ data => $value ] );

    # then
    is( $data->data, $value, 'Net::Fritz::Data->data');
};

subtest 'check new() with single parameter' => sub {
    # given
    my $value = 'bar';

    # when
    my $data = new_ok( 'Net::Fritz::Data', [ $value ] );

    # then
    is( $data->data, $value, 'Net::Fritz::Data->data');
};

