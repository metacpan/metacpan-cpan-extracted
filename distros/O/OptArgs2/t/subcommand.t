#!perl
use strict;
use warnings;
use Test2::V0;
use OptArgs2;

@ARGV = ();    # just in case this script got called with some

my ( $e, $class, $opts );

cmd 'c1' => (
    comment => 'the base command',
    optargs => sub {
        arg command => (
            isa     => 'SubCmd',
            comment => 'command to run',
        );
    },
);

subcmd 'c1::s1' => (
    comment => 'sub command',
    optargs => sub { },
);

( $class, $opts ) = class_optargs('c1');
is $class, 'c1', 'correct Cmd';
is $opts, {}, 'no opts or args';

( $class, $opts ) = class_optargs( 'c1', 's1' );
is $class, 'c1::s1', 'correct SubCmd';
is $opts, {}, 'no opts or args';

$e = dies { ( $class, $opts ) = class_optargs( 'c1', 'junk' ) };
like ref $e, qr/UnknownSubCmd/, 'unknown SubCmd';

cmd 'c2' => (
    comment => 'the base command',
    optargs => sub {
        arg command => (
            isa      => 'SubCmd',
            required => 1,
            comment  => 'command to run',
        );
    },
);

subcmd 'c2::s1' => (
    comment => 'sub command',
    optargs => sub { },
);

$e = dies { ( $class, $opts ) = class_optargs('c2') };
like ref $e, qr/SubCmdRequired/, ref $e;

cmd 'c3' => (
    comment => 'the base command',
    optargs => sub {
        arg command => (
            isa      => 'SubCmd',
            required => 1,
            comment  => 'command to run',
            fallback => {
                name    => 'fb',
                isa     => 'Str',
                comment => 'a fallback argument',
            },
        );
    },
);

subcmd 'c3::s1' => (
    comment => 'sub command',
    optargs => sub { },
);

$e = dies { ( $class, $opts ) = class_optargs('c3') };
like ref $e, qr/ArgRequired/, ref $e;

( $class, $opts ) = class_optargs( 'c3', 's1' );
is $class, 'c3::s1', 'correct SubCmd';
is $opts, {}, 'no opts or args';

( $class, $opts ) = class_optargs( 'c3', 'junk' );
is $class, 'c3', 'fallback class';
is $opts, { fb => 'junk' }, 'fallback argument';

done_testing;
