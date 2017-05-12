#!/usr/bin/env perl

use 5.008004;
use utf8;
use strict;
use warnings;


use autodie qw< :default >;
use Readonly;


use version; our $VERSION = qv('v0.999.3');


use TeamCity::BuildMessages qw< teamcity_escape >;


use Test::Exception;
use Test::More;


Readonly my @TEST_INPUT_AND_EXPECTED => (
    [ [ qw/ foo [bar] / ],                            q<foo '[bar|]'>                            ],
    [ [ qw/ progressMessage <message> / ],            q[progressMessage '<message>']             ],
    [ [ qw/ buildNumber 1.2.3_{build.number}-ent / ], q<buildNumber '1.2.3_{build.number}-ent'>, ],
    [ [ qw/ foo bar [baz] / ],                        q<foo bar='[baz|]'>                        ],
    [ [ qw/ testStdErr name testname out text / ],    q<testStdErr name='testname' out='text'>   ],
);

plan tests => 5 + scalar @TEST_INPUT_AND_EXPECTED;


foreach my $values (@TEST_INPUT_AND_EXPECTED) {
    my ($input, $expected) = @{$values};
    my @input = @{$input};
    $expected = qq/##teamcity[$expected]\n/;

    my $got = q<>;
    open my $string_handle, '>', \$got;
    TeamCity::BuildMessages::_emit_build_message_to_handle(
        $string_handle, @input,
    );
    close $string_handle;

    is( $got, $expected, qq<_emit_build_message_to_handle(@input)> );
} # end foreach


## no critic (RegularExpressions::RequireExtendedFormatting)
throws_ok
    { TeamCity::BuildMessages::_emit_build_message_to_handle() }
    qr<\ANo message specified[.]>ms,
    'Got exception for not giving a message.';


throws_ok
    { TeamCity::BuildMessages::_emit_build_message_to_handle( undef, 'foo' ) }
    qr<\ANo values specified[.]>ms,
    'Got exception for not giving any values.';


throws_ok
    {
        TeamCity::BuildMessages::_emit_build_message_to_handle(
            undef, 'bad name', 'foo',
        )
    }
    qr<\A"bad name" is not a valid message name[.]>ms,
    'Got exception for bad message name.';


{
    my $got = q<>;
    open my $string_handle, '>', \$got; ## no critic (InputOutput::RequireBriefOpen)
    throws_ok
        {
            TeamCity::BuildMessages::_emit_build_message_to_handle(
                $string_handle,
                'message',
                'property',
                'value',
                'name_missing_value',
            )
        }
        qr<\AMessage property given without a value[.]>ms,
        'Got exception for property missing a value.';
    close $string_handle;
}


{
    my $got = q<>;
    open my $string_handle, '>', \$got;
    throws_ok
        {
            TeamCity::BuildMessages::_emit_build_message_to_handle(
                $string_handle, 'message', 'bad name', 'value',
            )
        }
        qr<\A"bad name" is not a valid property name[.]>ms,
        'Got exception for property with a bad name.';
    close $string_handle;
}


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
