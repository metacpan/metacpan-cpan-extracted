#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MySQL::Workbench::Parser;
use MySQL::Workbench::Parser::Table;

my $parser = MySQL::Workbench::Parser->new(
    file => __FILE__,
);

my %tests = (
    _lint => [
        {
            input  => [],
            result => undef,
        },
        {
            input  => [{}],
            result => undef,
        },
    ],
);


for my $method ( sort keys %tests ) {
    my $sub = $parser->can( $method );

    my $cnt = 0;
    for my $method_test ( @{ $tests{$method} || [] } ) {
        my $check = $method_test->{result};
        my $input = $method_test->{input};

        my $result = $parser->$sub( @{$input} );
        is $result, $check, "$method - $cnt";

        $cnt++;
    }
}

done_testing();
