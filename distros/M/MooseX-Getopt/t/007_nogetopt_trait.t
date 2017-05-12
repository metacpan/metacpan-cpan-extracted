use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN {
    use_ok('MooseX::Getopt');
}

{
    package App;
    use Moose;

    with 'MooseX::Getopt';

    has 'data' => (
        traits    => ['Getopt'],
        is        => 'ro',
        isa       => 'Str',
        default   => 'file.dat',
        cmd_flag  => 'f',
    );

    has 'cow' => (
        traits      => ['Getopt'],
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
        traits   => ['NoGetopt'],
        is       => 'ro',
        isa      => 'Int',
        default  => 713
    );

    has '_private_stuff_cmdline' => (
        traits    => ['Getopt'],
        is        => 'ro',
        isa       => 'Int',
        default   => 832,
        cmd_flag  => 'p',
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

    like exception { App->new_with_options }, qr/Unknown option: private_stuff/;
}

done_testing;
