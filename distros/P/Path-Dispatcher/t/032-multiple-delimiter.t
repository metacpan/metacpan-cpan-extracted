use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Sequence->new(
        delimiter => ' ',
        rules => [
            Path::Dispatcher::Rule::Eq->new(
                string => 'foo',
            ),
            Path::Dispatcher::Rule::Eq->new(
                string => 'bar',
            ),
        ],
        block => sub { push @calls, shift->positional_captures },
    ),
);

$dispatcher->run('foo bar');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

$dispatcher->run('foo    bar');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

$dispatcher->run('   foo    bar    ');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");


$dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Sequence->new(
        delimiter => '/',
        rules => [
            Path::Dispatcher::Rule::Eq->new(
                string => 'foo',
            ),
            Path::Dispatcher::Rule::Eq->new(
                string => 'bar',
            ),
        ],
        block => sub { push @calls, shift->positional_captures },
    ),
);

$dispatcher->run('/foo/bar');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

$dispatcher->run('/foo/bar/');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

$dispatcher->run('/foo//bar/');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

$dispatcher->run('foo/bar');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

$dispatcher->run('///foo///bar///');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

done_testing;
