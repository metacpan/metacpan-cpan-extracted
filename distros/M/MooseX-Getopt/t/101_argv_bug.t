use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Getopt;

{
    package App;
    use Moose;

    with 'MooseX::Getopt';

    has 'length' => (
        is      => 'ro',
        isa     => 'Int',
        default => 24,
    );

    has 'verbose' => (
        is     => 'ro',
        isa    => 'Bool',
        default => 0,
    );
    no Moose;
}

{
    my $app = App->new_with_options(argv => [ '--verbose', '--length', 50 ]);
    isa_ok($app, 'App');

    ok($app->verbose, '... verbosity is turned on as expected');
    is($app->length, 50, '... length is 50 as expected');
}

done_testing;
