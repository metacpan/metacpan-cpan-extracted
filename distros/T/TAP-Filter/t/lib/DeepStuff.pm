package DeepStuff;

use strict;
use warnings;
use Test::Deep;

use base qw(Exporter);

our @EXPORT = qw( is_result is_plan is_test );

sub is_result {
    return isa( 'TAP::Parser::Result' );
}

sub is_plan {
    my $n = shift;
    return all(
        is_result(),
        methods(
            is_plan       => bool( 1 ),
            tests_planned => $n,
        )
    );
}

sub is_test {
    my ( $n, $desc, $ok ) = @_;
    return all(
        is_result(),
        methods(
            is_test => bool( 1 ),
            number  => $n,
            description => $desc ? "- $desc" : '',
            ok => ( $ok ? 'ok' : 'not ok' ),
        )
    );
}

1;
