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

    with 'MooseX::Getopt::Dashes';

    has 'some_thingy' => ( is => 'ro', isa => 'Str', default => 'foo' );
    has 'another_thingy'   => ( is => 'ro', isa => 'Str', default => 'foo', cmd_flag => 'another_thingy', traits => [ 'Getopt' ], );
}

{
    local @ARGV = (qw/--some-thingy bar/);
    ok ! exception { is( App->new_with_options->some_thingy, 'bar') }, 'Dash in option name';
}

{
    local @ARGV = (qw/--some_thingy bar/);
    like exception { App->new_with_options }, qr/Unknown option: some_thingy/;
}

{
    local @ARGV = (qw/--another_thingy bar/);
    ok ! exception { is( App->new_with_options->another_thingy, 'bar' ) }, 'Underscore in option name';
}

{
    local @ARGV = (qw/--another-thingy bar/);
    like exception { App->new_with_options }, qr/Unknown option: another-thingy/;
}

done_testing;
