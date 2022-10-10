#!perl
use strict;
use warnings;
use Test2::V0;
use OptArgs2;

@ARGV = ();    # just in case this script got called with some

my ( $e, $class, $opts );

cmd 'c1' => (
    comment => 'the base command',
    optargs => [
        command => {
            isa      => 'SubCmd',
            comment  => 'command to run',
            required => 1,
        },
    ],
);

subcmd 'c1::s1' => (
    comment => 'sub command',
    optargs => [],
);

$e = dies { ( $class, $opts ) = class_optargs( 'c1', 's' ) };
isa_ok $e, 'OptArgs2::Usage::SubCmdUnknown';

cmd 'c2' => (
    comment => 'the base command',
    abbrev  => 1,
    optargs => [
        command => {
            isa     => 'SubCmd',
            comment => 'command to run',
        },
    ],
);

subcmd 'c2::s1' => (
    comment => 'sub command',
    optargs => [],
);

( $class, $opts ) = class_optargs( 'c2', 's' );
is $class, 'c2::s1', 'correct SubCmd abbrev';

( $class, $opts ) = class_optargs( 'c2', 's1' );
is $class, 'c2::s1', 'correct SubCmd full';

done_testing;
