use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package App;
    use Moose;
    with qw(MooseX::Getopt);

    has 'TrackingNumber' => (
        is  => 'rw',
        isa => 'Str',
    );

    has 'otherparam' => (
        is  => 'rw',
        isa => 'Str',
    );
}

{
    local @ARGV = ('--TrackingNumber','1Z1234567812345670','--otherparam','foo');

    my $app = App->new_with_options;
    isa_ok($app, 'App');
    is($app->TrackingNumber, '1Z1234567812345670', '... TrackingNumber is as expected');
    is($app->otherparam, 'foo', '... otherparam is as expected');
}

done_testing;
