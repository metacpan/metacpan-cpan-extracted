use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use TeamCity::Message;

my @tests = (
    {
        name  => 'simple message',
        input => {
            type    => 'message',
            content => { text => 'foo' },
        },
        expect => {
            type    => 'message',
            content => q{text='foo'},
        },
    },
    {
        name  => 'arbtrary type',
        input => {
            type    => 'sometype',
            content => { text => 'foo' },
        },
        expect => {
            type    => 'sometype',
            content => q{text='foo'},
        },
    },
    {
        name  => 'multiple kv pairs',
        input => {
            type    => 'message',
            content => {
                text   => 'danger',
                status => 'ERROR',
            },
        },
        expect => {
            type    => 'message',
            content => q{status='ERROR' text='danger'},
        },
    },
    {
        name  => 'content is string',
        input => {
            type    => 'foo',
            content => 'a string',
        },
        expect => {
            type    => 'foo',
            content => 'a string',
        },
    },
    {
        name  => 'content is kv with escapes',
        input => {
            type    => 'foo',
            content => { text => qq{a string\r\n'quoted | ]'} },
        },
        expect => {
            type    => 'foo',
            content => q{text='a string|r|n|'quoted || |]|''},
        },
    },
    {
        name  => 'content is string with escapes',
        input => {
            type    => 'foo',
            content => qq{a string\r\n'quoted | ]'},
        },
        expect => {
            type    => 'foo',
            content => q{a string|r|n|'quoted || |]|'},
        },
    },
);

for my $test (@tests) {
    subtest(
        $test->{name},
        sub {
            my $output = tc_message( %{ $test->{input} } );
            my %parsed = _parse_and_test_message($output)
                or return;

            is(
                $parsed{type},
                $test->{expect}{type},
                "type is $test->{expect}{type}",
            );

            is(
                $parsed{content},
                $test->{expect}{content},
                'message contnt',
            );
        }
    );
}

done_testing();

sub _parse_and_test_message {
    my $msg = shift;

    like(
        $msg,
        qr/^\#\#teamcity\[/,
        q{message starts with '##teamcity['}
    ) or return;

    my ( $type, $content ) = $msg =~ /^\#\#teamcity\[(\S+)(?: (.+))?\]$/;
    ok(
        defined $type && length $type,
        'message has a type'
    ) or return;

    if ( $content =~ /^'/ ) {
        $content =~ s/^'|'$//g;
        return (
            type    => $type,
            content => $content,
        );
    }

    if ( $content =~ s/ timestamp='(.+?)'// ) {
        my $timestamp = $1;
        like(
            $timestamp,
            qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}/,
            'timestamp is formatted correctly'
        );
    }
    else {
        ok(
            0,
            'message has timestamp'
        );
    }

    return (
        type    => $type,
        content => $content,
    );
}
