#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('MouseX::Getopt');
}

{

    package App;
    use Mouse;

    with 'MouseX::Getopt::Strict';

    has 'data' => (
        metaclass => 'Getopt',
        is        => 'ro',
        isa       => 'Str',
        default   => 'file.dat',
        cmd_flag  => 'f',
    );

    has 'cow' => (
        metaclass   => 'Getopt',
        is          => 'ro',
        isa         => 'Str',
        default     => 'moo',
        cmd_aliases => [qw/ moocow m c /],
    );

    has 'horse' => (
        traits      => ['Getopt'],
        is          => 'ro',
        isa         => 'Str',
        default     => 'bray',
        cmd_flag    => 'horsey',
        cmd_aliases => 'x',
    );

    has 'length' => (
        is      => 'ro',
        isa     => 'Int',
        default => 24
    );

    has 'verbose' => (
        is  => 'ro',
        isa => 'Bool',
    );

    has 'libs' => (
        is      => 'ro',
        isa     => 'ArrayRef',
        default => sub { [] },
    );

    has 'details' => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { {} },
    );

    has 'private_stuff' => (
        is       => 'ro',
        isa      => 'Int',
        default  => 713
    );
}

{
    local @ARGV = ();

    my $app = App->new_with_options;
    isa_ok( $app, 'App' );

    ok( !$app->verbose, '... verbosity is off as expected' );
    is( $app->length, 24,         '... length is 24 as expected' );
    is( $app->data,   'file.dat', '... data is file.dat as expected' );
    is_deeply( $app->libs, [], '... libs is [] as expected' );
    is_deeply( $app->details, {}, '... details is {} as expected' );
    is($app->private_stuff, 713, '... private stuff is 713 as expected');
}

{
    local @ARGV = (qw/--private_stuff 317/);

    throws_ok { App->new_with_options } qr/Unknown option: private_stuff/;
}

{
    local @ARGV = (qw/--length 100/);

    throws_ok { App->new_with_options } qr/Unknown option: length/;
}

