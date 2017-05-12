#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 40;
use Path::Dispatcher;

my $predicate = Path::Dispatcher::Rule::Tokens->new(
    tokens => ['ticket'],
    prefix => 1,
);

my $chain = Path::Dispatcher::Rule::Chain->new;

my $create = Path::Dispatcher::Rule::Tokens->new(
    tokens => ['create'],
);

my $update = Path::Dispatcher::Rule::Tokens->new(
    tokens => ['update'],
    prefix => 1,
);

my $under_always = Path::Dispatcher::Rule::Under->new(
    predicate => $predicate,
    rules     => [Path::Dispatcher::Rule::Always->new, $create, $update],
);

my $under_chain = Path::Dispatcher::Rule::Under->new(
    predicate => $predicate,
    rules     => [$chain, $create, $update],
);

my %tests = (
    "ticket" => {
        fail => 1,
        catchall => 1,
        always => 1,
    },
    "ticket create" => {},
    "ticket update" => {},
    "  ticket   update  " => {
        name => "whitespace doesn't matter for token-based rules",
    },
    "ticket update foo" => {
        name => "'ticket update' rule is prefix",
    },

    "ticket create foo" => {
        fail => 1,
        catchall => 1,
        always => 1,
        name => "did not match 'ticket create foo' because it's not a suffix",
    },
    "comment create" => {
        fail => 1,
        name => "did not match 'comment create' because the prefix is ticket",
    },
    "ticket delete" => {
        fail => 1,
        catchall => 1,
        always => 1,
        name => "did not match 'ticket delete' because delete is not a suffix",
    },
);

sub run_tests {
    my $under = shift;
    my $is_always = shift;

    for my $path (keys %tests) {
        my $data = $tests{$path};
        my $name = $data->{name} || $path;

        my $match = $under->match(Path::Dispatcher::Path->new($path));
        $match = !$match if $data->{fail} && !($is_always && $data->{always}); # Always always matches
        ok($match, $name);
    }

    my $catchall = Path::Dispatcher::Rule::Regex->new(
        regex => qr/()/,
    );

    $under->add_rule($catchall);

    for my $path (keys %tests) {
        my $data = $tests{$path};
        my $name = $data->{name} || $path;

        my $match = $under->match(Path::Dispatcher::Path->new($path));
        $match = !$match if $data->{fail} && !$data->{catchall};
        ok($match, $name);
    }
}

run_tests $under_chain, 0;
run_tests $under_always, 1;

my @result;

do {
    package ChainDispatch;
    use Path::Dispatcher::Declarative -base;

    under 'ticket' => sub {
        chain {
            push @result, "(ticket chain)";
        };
        on 'create' => sub { push @result, "ticket create" };
        chain {
            push @result, "(ticket chain just for update)";
        };
        on 'update' => sub { push @result, "ticket update" };
    };

    under 'blog' => sub {
        chain {
            push @result, "(blog chain)";
        };
        under 'post' => sub {
            chain {
                push @result, "(after post)";
            };
            on 'create' => sub { push @result, "create blog post" };
            on 'delete' => sub { push @result, "delete blog post" };
        };
        chain {
            push @result, "(before comment)";
        };
        under 'comment' => sub {
            on 'create' => sub { push @result, "create blog comment" };
            on 'delete' => sub { push @result, "delete blog comment" };
            chain {
                push @result, "(never included)";
            };
        };
    };
};

ChainDispatch->run('ticket create');
is_deeply([splice @result], ['(ticket chain)', 'ticket create']);

ChainDispatch->run('ticket update');
is_deeply([splice @result], ['(ticket chain)', '(ticket chain just for update)', 'ticket update']);

ChainDispatch->run('ticket foo');
is_deeply([splice @result], []);

ChainDispatch->run('blog');
is_deeply([splice @result], []);

ChainDispatch->run('blog post');
is_deeply([splice @result], []);

ChainDispatch->run('blog post create');
is_deeply([splice @result], ['(blog chain)', '(after post)', 'create blog post']);

ChainDispatch->run('blog comment');
is_deeply([splice @result], []);

ChainDispatch->run('blog comment create');
is_deeply([splice @result], ['(blog chain)', '(before comment)', 'create blog comment']);

