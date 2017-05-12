use strict;
use Test::More;

use Furl;
use JSON;
use Redis::Namespace;

our %custom_test = (
    OBJECT => sub {
        my ($key, $info) = @_;
        my $args = $info->{arguments};
        is $args->[0]{type}, 'string';
    },
    PSUBSCRIBE => sub { pass },
    PUBLISH => sub { pass },
    PUBSUB => sub { pass },
    SUBSCRIBE => sub { pass },
    UNSUBSCRIBE => sub { pass },
    'SCRIPT EXISTS' => sub { pass },
    'SCRIPT FLUSH' => sub { pass },
    'SCRIPT KILL' => sub { pass },
    'SCRIPT LOAD' => sub { pass },
);

sub test {
    my $url = 'https://raw.githubusercontent.com/antirez/redis-doc/master/commands.json';
    my $furl = Furl->new;
    my $res = $furl->get($url);
    my $json = decode_json $res->content;

    for my $key (sort keys %$json) {
        subtest $key => sub {
            my $test = $custom_test{$key} // \&test_command;
            $test->($key, $json->{$key});
        };
    }
}

our %before_tests = (
    none => sub {
        for my $arg (@_) {
            ok !($arg->{type} eq 'key' || $arg->{type} eq 'pattern'), $arg->{name};
        }
    },
    first => sub {
        my ($first, @extra) = @_;
        ok $first->{type} eq 'key' || $first->{type} eq 'pattern', $first->{name};
        for my $arg (@extra) {
            isnt $arg->{type}, 'key', $arg->{name};
        }
    },
    all => sub {
        for my $arg (@_) {
            ok $arg->{type} eq 'key' || $arg->{type} eq 'pattern', $arg->{name};
        }
    },
    exclude_first => sub {
        my ($first, @extra) = @_;
        isnt $first->{type}, 'key', $first->{name};
        for my $arg (@extra) {
            is $arg->{type}, 'key', $arg->{name};
        }
    },
    exclude_last => sub {
        my $last = pop @_;
        isnt $last->{type}, 'key', $last->{name};
        for my $arg (@_) {
            is $arg->{type}, 'key', $arg->{name};
        }
    },
    alternate => sub {
        for my $arg (@_) {
            is $arg->{type}[0], 'key', $arg->{name}[0];
            isnt $arg->{type}[1], 'key', $arg->{name}[1];
            is scalar @{$arg->{name}}, 2;
        }
    },
    sort => sub {
        my ($first, @extra) = @_;
        is $first->{type}, 'key', $first->{name};
    },
    eval_style => sub {
        my ($script, $num, $keys, $values, @extra) = @_;
        is $script->{type}, 'string', $script->{name};
        is $num->{type}, 'integer', $num->{name};
        is $keys->{type}, 'key', $keys->{name};
        ok $keys->{multiple};
        isnt $values->{type}, 'key', $values->{name};
        ok $values->{multiple};
        is scalar @extra, 0;
    },
    exclude_options => sub {
        my ($key, $num, $keys, @extra) = @_;
        is $key->{type}, 'key', $key->{name};
        is $num->{type}, 'integer', $num->{name};
        is $keys->{type}, 'key', $keys->{name};
        ok $keys->{multiple};
        for my $arg (@extra) {
            isnt $arg->{type}, 'key', $arg->{name};
        }
    },
    scan => sub {
        my ($cursor, @extra) = @_;
        is $cursor->{type}, 'integer', $cursor->{name};
        for my $arg (@extra) {
            if ($arg->{command} eq 'MATCH') {
                is $arg->{type}, "pattern", $arg->{name};
            } else {
                isnt $arg->{type}, "pattern", $arg->{name};
            }
        }
    },
    migrate => sub {
        my ($host, $port, $key, $db, $timeout, @extra) = @_;
        is $host->{type}, 'string', $host->{name};
        is $port->{type}, 'string', $port->{name};
        is $key->{type}, 'enum', $key->{name};
        is_deeply $key->{enum}, ['key', '""'], $key->{name};
        is $db->{type}, 'integer', $db->{name};
        is $timeout->{type}, 'integer', $timeout->{name};
        for my $arg (@extra) {
            if ($arg->{command} eq 'KEYS') {
                is $arg->{type}, 'key';
            } else {
                isnt $arg->{type}, 'key';
            }
        }
    }
);

sub test_command {
    my ($key, $info) = @_;
    my ($command, @subcommand) = split / /, lc $key;
    ok my $option = $Redis::Namespace::COMMANDS{$command}, 'exists args tranfer definition' or return;
    my ($before, $after) = @$option;
    $before //= 'none';
    ok $Redis::Namespace::BEFORE_FILTERS{$before}, "exists before filter: $before";
    if (ok my $test = $before_tests{$before}, "exists test for before fileter: $before") {
        $test->(
            (map { +{ name => $_, type => 'subcommand'} } @subcommand),
            @{$info->{arguments}},
        );
    }
    if ($after) {
        ok $Redis::Namespace::BEFORE_FILTERS{$after}, "exists after filter $after";
    }
}

test();

done_testing;
