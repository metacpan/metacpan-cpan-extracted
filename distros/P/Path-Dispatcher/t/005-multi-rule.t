use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new;
for my $number (qw/first second/) {
    $dispatcher->add_rule(
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/foo/,
            block => sub { push @calls, $number },
        ),
    );
}

$dispatcher->run('foo');
is_deeply(\@calls, ['first']);

done_testing;

