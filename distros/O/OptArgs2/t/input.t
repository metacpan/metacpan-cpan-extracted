#!perl
use strict;
use warnings;
use OptArgs2;
use Test2::V0;

my $o;

@ARGV = ('cpanfile');
$o    = optargs(
    comment => 'type Input',
    optargs => [
        input => {
            isa      => 'Input',
            comment  => 'input argument',
            required => 1,
        },
    ],
);

like $o->{input}, qr/CPANfile/, 'type Input from argument';

@ARGV = ( '--input' => 'cpanfile' );
$o    = optargs(
    comment => 'type Input',
    optargs => [
        input => {
            isa     => '--Input',
            comment => 'input option',
        },
    ],
);

like $o->{input}, qr/CPANfile/, 'type Input from option';

done_testing();
