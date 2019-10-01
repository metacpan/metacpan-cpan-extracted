#!perl
package My::TestScript;

use 5.006;

use strict;
use warnings;

use Test::More;
plan tests => 25;

#plan tests => 1;

use Test::Exception;
use Test::Deep;

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
    methods( debug => 1, verbose => 1, argv => [], opt_foo => undef ),
    'correct defaults were set'
);

debug_verbose_interactions: {
    my @cases = (
        {
            name   => 'debug and verbose default ON',
            params => {
                argv => [],
            },
            results => {
                debug   => 1,
                verbose => 1,
            },
        },
        {
            name   => '--debug implies verbose',
            params => {
                argv => ['--debug'],
            },
            results => {
                debug   => 1,
                verbose => 1,
            },
        },
        {
            name   => '--nodebug implies no verbose',
            params => {
                argv => ['--nodebug'],
            },
            results => {
                debug   => 0,
                verbose => 0,
            },
        },
        {
            name   => '--noverbose overrides default setting',
            params => {
                argv => ['--noverbose'],
            },
            results => {
                verbose => 0,
            },
        },
        {
            name   => '--verbose sets verbose ON with --nodebug',
            params => {
                argv => [ '--verbose', '--nodebug' ],
            },
            results => {
                debug   => 0,
                verbose => 1,
            },
        },
        {
            name   => '--noverbose overrides implication by --debug',
            params => {
                argv => [ '--noverbose', '--debug' ],
            },
            results => {
                debug   => 1,
                verbose => 0,
            },
        },
    );

    for (@cases) {
        $app = __PACKAGE__->init( %{ $_->{params} } );
        cmp_deeply( $app, methods( %{ $_->{results} } ), $_->{name} );
    }
}

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
                debug   => 1,
                verbose => 1,
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
                debug   => 1,
                verbose => 1,
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
                debug   => 1,
                verbose => 1,
                opt_foo => undef,
            },
        },
        {
            name   => '--debug is accepted',
            name2  => 'and turns on debug',
            params => {
                argv     => ['--debug'],
                add_opts => [],
            },
            results => {
                argv    => [],
                debug   => 1,
                verbose => 1,
                opt_foo => undef,
            },
        },
        {
            name   => '--nodebug is accepted',
            name2  => 'and turns off debug',
            params => {
                argv     => ['--nodebug'],
                add_opts => [],
            },
            results => {
                argv    => [],
                debug   => 0,
                verbose => 0,
                opt_foo => undef,
            },
        },
        {
            name   => '--verbose is accepted',
            name2  => 'and turns on verbose',
            params => {
                argv     => ['--verbose'],
                add_opts => [],
            },
            results => {
                argv    => [],
                debug   => 1,
                verbose => 1,
                opt_foo => undef,
            },
        },
        {
            name   => '--noverbose is accepted',
            name2  => 'and turns off verbose',
            params => {
                argv     => ['--noverbose'],
                add_opts => [],
            },
            results => {
                argv    => [],
                debug   => 1,
                verbose => 0,
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
                debug   => 1,
                verbose => 1,
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

exit;

__END__

# bless( {
#   'argv' => [],
#   'debug' => 1,
#   'verbose' => 0
# }, 'main' )
#
