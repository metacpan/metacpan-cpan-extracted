use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::Identity;
use lib "t";
use testlib::Util ":all";
use Net::Twitter::Loader;

sub test_mock {
    my ($param, $exp_ids, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply(main->mock_timeline($param), [statuses(@$exp_ids)], $msg);
}

note('--- test the mock itself');

test_mock {}, [100,99,98,97,96,95,94,93,92,91], "mock no param";
test_mock {count => 4}, [100,99,98,97], "mock count";
test_mock {per_page => 13}, [100,99,98,97,96,95,94,93,92,91,90,89,88], "mock per_page";
test_mock {rpp => 150}, [reverse(1..100)], "mock rpp";
test_mock {max_id => 50}, [reverse(41..50)], "mock max_id";
test_mock {max_id => 120}, [reverse(91..100)], "mock max_id too large";
test_mock {max_id => -40}, [1], "mock max_id negative";
test_mock {since_id => 95}, [reverse(96 .. 100)], "mock since_id";
test_mock {since_id => 120}, [], "mock since_id too large";
test_mock {since_id => -100}, [reverse(91..100)], "mock since_id negative";
test_mock {max_id => 40, since_id => 35}, [reverse(36..40)], "mock max_id and since_id";
test_mock {max_id => 20, since_id => 20}, [], "mock max_id == since_id";


my $mocknt = mock_twitter();

note('--- iteration by user_timeline');
my $loader = Net::Twitter::Loader->new(
    backend => $mocknt, page_next_delay => 0, page_max => 500,
);
identical $loader->backend, $mocknt, "backend() OK";
is_deeply(
    $loader->user_timeline({since_id => 10, screen_name => "someone"}),
    [statuses reverse(11 .. 100)],
    "user_timeline since_id"
);
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 91};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 82};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 73};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 64};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 55};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 46};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 37};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 28};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 19};
test_call $mocknt, 'user_timeline', {screen_name => "someone", since_id => 10, max_id => 11};
end_call $mocknt;

$mocknt->clear;
is_deeply(
    $loader->user_timeline({user_id => 1919, count => 30}),
    [statuses reverse(71 .. 100)],
    "user_timeline no since_id"
);
test_call $mocknt, 'user_timeline', {user_id => 1919, count => 30};
end_call $mocknt;

$mocknt->clear;
is_deeply(
    $loader->user_timeline({max_id => 50, count => 25}),
    [statuses reverse(26 .. 50)],
    "user_timeline max_id"
);
test_call $mocknt, 'user_timeline', {count => 25, max_id => 50};
end_call $mocknt;

$mocknt->clear;
is_deeply(
    $loader->user_timeline({max_id => 20, since_id => 5, count => 5}),
    [statuses reverse(6 .. 20)],
    "user_timeline max_id and since_id"
);
test_call $mocknt, 'user_timeline', {count => 5, max_id => 20, since_id => 5};
test_call $mocknt, 'user_timeline', {count => 5, max_id => 16, since_id => 5};
test_call $mocknt, 'user_timeline', {count => 5, max_id => 12, since_id => 5};
test_call $mocknt, 'user_timeline', {count => 5, max_id => 8, since_id => 5};
test_call $mocknt, 'user_timeline', {count => 5, max_id => 6, since_id => 5};
end_call $mocknt;

$loader = Net::Twitter::Loader->new(
    backend => $mocknt, page_next_delay => 0, page_max => 2,
);
identical $loader->backend, $mocknt, "backend() OK";
$mocknt->clear;
is_deeply(
    $loader->user_timeline({since_id => 5, screen_name => "foo"}),
    [statuses reverse(82 .. 100)],
    "page_max option"
);
test_call $mocknt, 'user_timeline', {screen_name => "foo", since_id => 5};
test_call $mocknt, 'user_timeline', {screen_name => "foo", since_id => 5, max_id => 91};
end_call $mocknt;

$loader = Net::Twitter::Loader->new(
    backend => $mocknt, page_next_delay => 0, page_max_no_since_id => 3,
);
$mocknt->clear;
is_deeply(
    $loader->user_timeline({max_id => 80, count => 11}),
    [statuses reverse(50 .. 80)],
    "page_max_no_since_id option"
);
test_call $mocknt, 'user_timeline', {count => 11, max_id => 80};
test_call $mocknt, 'user_timeline', {count => 11, max_id => 70};
test_call $mocknt, 'user_timeline', {count => 11, max_id => 60};
end_call $mocknt;

$loader = Net::Twitter::Loader->new(
    backend => $mocknt, page_next_delay => 0,
);
foreach my $method_name (qw(home_timeline list_statuses search favorites mentions retweets_of_me)) {
    note("--- iteration by $method_name");
    $mocknt->clear;
    is_deeply(
        $loader->$method_name({max_id => 40, since_id => 5, count => 20}),
        [statuses reverse(6 .. 40)],
        "$method_name iterates"
    );
    test_call $mocknt, $method_name, {count => 20, since_id => 5, max_id => 40};
    test_call $mocknt, $method_name, {count => 20, since_id => 5, max_id => 21};
    test_call $mocknt, $method_name, {count => 20, since_id => 5, max_id => 6};
    end_call $mocknt;
}

note('--- public_statuses should never iterate');
$loader = Net::Twitter::Loader->new(
    backend => $mocknt, page_next_delay => 0, page_max_no_since_id => 10,
);
$mocknt->clear;
is_deeply(
    $loader->public_timeline(),
    [statuses reverse(91 .. 100)],
    "public_timeline does not iterate even if page_max_no_since_id > 1"
);
test_call $mocknt, 'public_timeline', {};
end_call $mocknt;

done_testing;
