use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Intersection->new(
            block => sub { "creating a ticket" },
            rules => [
                Path::Dispatcher::Rule::Tokens->new(
                    delimiter => '/',
                    tokens    => ['=', 'model', 'Ticket'],
                ),
                Path::Dispatcher::Rule::Metadata->new(
                    field   => 'http_method',
                    matcher => Path::Dispatcher::Rule::Eq->new(string => 'POST'),
                ),
            ],
        ),
    ],
);

my @results = $dispatcher->run(Path::Dispatcher::Path->new(
    path     => "/=/model/Ticket",
    metadata => {
        http_method => "POST",
    },
));

is_deeply(\@results, ["creating a ticket"], "matched path and metadata");

@results = $dispatcher->run(Path::Dispatcher::Path->new(
    path => "/=/model/Ticket.yml",
    metadata => {
        http_method => "GET",
    },
));

is_deeply(\@results, [], "didn't match metadata");

done_testing;

