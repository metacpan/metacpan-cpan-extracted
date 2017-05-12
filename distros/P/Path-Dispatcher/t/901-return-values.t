use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Path::Dispatcher;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::CodeRef->new(
            matcher => sub { [{ cant_handle_complex_list_of_results => 1 }] },
        ),
    ],
);

like(exception {
    $dispatcher->dispatch('foo');
}, qr/Results returned from _match must be a hashref/);

done_testing;

