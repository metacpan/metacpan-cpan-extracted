use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my (@matches, @calls);

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::CodeRef->new(
        matcher => sub { push @matches, $_; length > 5 ? {} : 0 },
        block   => sub { my $match = shift; push @calls, [@_] },
    ),
);

$dispatcher->run('foobar');

is_deeply([splice @matches], ['foobar']);
is_deeply([splice @calls], [ [] ]);

$dispatcher->run('other');
is($matches[0]->path, 'other');

done_testing;

