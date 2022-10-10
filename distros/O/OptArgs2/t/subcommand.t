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
            isa     => 'SubCmd',
            comment => 'command to run',
        },
    ],
);

subcmd 'c1::s1' => (
    comment => 'sub command',
    optargs => [],
);

( $class, $opts ) = class_optargs('c1');
is $class, 'c1', 'correct Cmd';
is $opts, {}, 'no opts or args';

( $class, $opts ) = class_optargs( 'c1', 's1' );
is $class, 'c1::s1', 'correct SubCmd';
is $opts, {}, 'no opts or args';

$e = dies { ( $class, $opts ) = class_optargs( 'c1', 'junk' ) };
like ref $e, qr/SubCmdUnknown/, 'unknown SubCmd';

cmd 'c2' => (
    comment => 'the base command',
    optargs => [
        command => {
            isa      => 'SubCmd',
            required => 1,
            comment  => 'command to run',
        },
    ],
);

subcmd 'c2::s1' => (
    comment => 'sub command',
    optargs => [],
);

$e = dies { ( $class, $opts ) = class_optargs('c2') };
like ref $e, qr/ArgRequired/, ref $e;

cmd 'c3' => (
    comment => 'the base command',
    optargs => [
        command => {
            isa      => 'SubCmd',
            required => 1,
            comment  => 'command to run',
            fallthru => 1,
        },
    ],
);

subcmd 'c3::s1' => (
    comment => 'sub command',
    optargs => [],
);

$e = dies { ( $class, $opts ) = class_optargs('c3') };
like ref $e, qr/ArgRequired/, ref $e;

( $class, $opts ) = class_optargs( 'c3', 's1' );
is $class, 'c3::s1', 'correct SubCmd';
is $opts, {}, 'no opts or args';

( $class, $opts ) = class_optargs( 'c3', 'junk' );
is $class, 'c3', 'fallback class';
is $opts, { command => 'junk' }, 'fallback argument';

done_testing;
