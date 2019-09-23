#!perl -T
package My::TestScript;

use 5.006;

use strict;
use warnings;

BEGIN {
    $ENV{MRC_NO_STDOPTS} = 1;
}

use Test::More;
plan tests => 27;

#plan tests => 1;

use Test::Exception;
use Test::Deep;
use Test::MockModule;
use Capture::Tiny qw( capture_merged );

use Moo;
with 'MooX::Role::CliOptions';

use MooX::StrictConstructor;

has opt_foo => ( is => 'ro', );

my $app;
lives_ok { $app = __PACKAGE__->init( argv => [] ) }
'empty command line accepted';
isa_ok( $app, __PACKAGE__, '$app' );
cmp_deeply(
    $app,
    methods( argv => [], opt_foo => undef ),
    'correct defaults were set'
);

{
    my @cases = (
        {
            name   => 'undef add_opts accepted',
            name2  => 'and opt_foo is left alone',
            params => {
                argv     => [],
                add_opts => undef,
            },
            results => {
                argv    => [],
                opt_foo => undef,
            },
        },
        {
            name   => 'empty add_opts accepted',
            name2  => 'and opt_foo is left alone',
            params => {
                argv     => [],
                add_opts => [],
            },
            results => {
                argv    => [],
                opt_foo => undef,
            },
        },
        {
            name   => 'non-options appear in argv',
            name2  => 'and are left intact',
            params => {
                argv     => [qw(not options)],
                add_opts => [],
            },
            results => {
                argv    => [qw(not options)],
                opt_foo => undef,
            },
        },
        {
            name   => '--opt_foo accepted when in add_opts',
            name2  => 'and sets opt_foo',
            params => {
                argv     => ['--opt_foo=bar'],
                add_opts => ['opt_foo=s'],
            },
            results => {
                argv    => [],
                opt_foo => 'bar',
            },
        },
    );

    for (@cases) {
        lives_ok { $app = __PACKAGE__->init( %{ $_->{params} } ); }
        $_->{name};
        cmp_deeply( $app, methods( %{ $_->{results} } ), $_->{name2} );
    }
}

{
    my $p2u_called;
    my $mock_MRM = Test::MockModule->new('MooX::Role::CliOptions');
    $mock_MRM->mock(
        _pod2usage => sub {
            $p2u_called = 1;
        },
    );

    my @cases = (
        {
            name   => '--debug is not accepted',
            name2  => 'and $app->debug does not exist',
            params => {
                argv     => ['--debug'],
                add_opts => [],
            },
            method   => 'debug',
            opt_name => 'debug',
        },
        {
            name   => '--nodebug is not accepted',
            name2  => 'and $app->debug does not exist',
            params => {
                argv     => ['--nodebug'],
                add_opts => [],
            },
            method   => 'debug',
            opt_name => 'nodebug',
        },
        {
            name   => '--verbose is not accepted',
            name2  => 'and $app->verbose does not exist',
            params => {
                argv     => ['--verbose'],
                add_opts => [],
            },
            method   => 'verbose',
            opt_name => 'verbose',
        },
        {
            name   => '--noverbose is not accepted',
            name2  => 'and $app->verbose does not exist',
            params => {
                argv     => ['--noverbose'],
                add_opts => [],
            },
            method   => 'verbose',
            opt_name => 'noverbose',
        },
    );

    for (@cases) {
        $p2u_called = 0;
        my $merged;
        lives_ok {
            $merged = capture_merged {
                $app = __PACKAGE__->init( %{ $_->{params} } );
            }
        }
        $_->{name};
        like(
            $merged,
            qr/Unknown option: $_->{opt_name}/,
            'unkdown option message displayed'
        );
        ok( $p2u_called,                       'usage message was displayed' );
        ok( !__PACKAGE__->can( $_->{method} ), $_->{name2} );
    }
}

exit;

__END__
