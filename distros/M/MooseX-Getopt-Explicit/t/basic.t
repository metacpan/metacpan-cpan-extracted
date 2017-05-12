use strict;
use warnings;
use autodie;

{
    package Example;

    use Moose;
    with 'MooseX::Getopt::Explicit';

    has foo => (
        is  => 'rw',
        isa => 'Str',
    );

    has bar => (
        is     => 'rw',
        isa    => 'Str',
        traits => ['Getopt'],
    );
}

use Capture::Tiny qw(capture_merged);
use Test::More tests => 5;

my $app;

$app = Example->new_with_options(
    argv => ['--bar=test'],
);

is $app->foo, undef;
is $app->bar, 'test';

$app = eval {
    Example->new_with_options(
        argv => ['--foo=test2'],
    );
};

ok !$app;

my $output = capture_merged {
    my $pid = fork();

    if($pid) {
        waitpid $pid, 0;
    } else {
        Example->new_with_options(
            argv => ['--help'],
        );
        exit 0; # in case ↑ doesn't exit for some reason
    }
};

like $output, qr/--bar/;
unlike $output, qr/--foo/;
