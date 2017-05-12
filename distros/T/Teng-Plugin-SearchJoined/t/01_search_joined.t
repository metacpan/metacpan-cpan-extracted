use strict;
use warnings;
use utf8;
use Test::More;
use t::Utils;
use Mock::BasicJoin;

Mock::BasicJoin->load_plugin('SearchJoined');

my $dbh = t::Utils->setup_dbh;
my $db = Mock::BasicJoin->new({dbh => $dbh});
$db->prepare_db($dbh);

isa_ok $db, 'Teng';
isa_ok $db, 'Mock::BasicJoin';

$db->bulk_insert(user => [{
    id   => 1,
    name => 'aaa',
}, {
    id   => 2,
    name => 'bbb',
}]);

$db->bulk_insert(item => [{
    id   => 1,
    name => 'aaa_item',
}, {
    id   => 2,
    name => 'bbb_item',
}]);

$db->bulk_insert(user_item => [{
    user_id => 1,
    item_id => 1,
}, {
    user_id => 1,
    item_id => 2,
}, {
    user_id => 2,
    item_id => 2,
}]);

subtest 'double' => sub {
    my $itr = $db->search_joined(user_item => [
        user => {'user_item.user_id' => 'user.id'},
    ], {
        'user.id' => 1,
    }, {
        order_by => 'user_item.item_id',
    });

    isa_ok $itr, 'Teng::Plugin::SearchJoined::Iterator';

    my $count = 0;
    while (my ($user_item, $user) = $itr->next) {
        isa_ok $user_item, 'Mock::BasicJoin::Row::UserItem';
        isa_ok $user,      'Mock::BasicJoin::Row::User';
        ok $user->name, 'aaa';
        $count++;
    }
    is $count, 2;
};

subtest 'triple' => sub {
    my $itr = $db->search_joined(user_item => [
        user => {'user_item.user_id' => 'user.id'},
        item => {'user_item.item_id' => 'item.id'},
    ], {
        'user.id' => 2,
    }, {
        order_by => 'user_item.item_id',
    });
    isa_ok $itr, 'Teng::Plugin::SearchJoined::Iterator';

    my $count = 0;
    while (my ($user_item, $user, $item) = $itr->next) {
        isa_ok $user_item, 'Mock::BasicJoin::Row::UserItem';
        isa_ok $user,      'Mock::BasicJoin::Row::User';
        isa_ok $item,      'Mock::BasicJoin::Row::Item';
        ok $user->name, 'bbb';
        ok $item->name, 'bbb_item';
        $count++;
    }
    is $count, 1;
};

subtest 'suppress_object_creation' => sub {
    my $itr = $db->search_joined(user_item => [
        user => {'user_item.user_id' => 'user.id'},
        item => {'user_item.item_id' => 'item.id'},
    ], {
        'user.id' => 2,
    }, {
        order_by => 'user_item.item_id',
    });
    isa_ok $itr, 'Teng::Plugin::SearchJoined::Iterator';

    $itr->suppress_object_creation(1);
    my $count = 0;
    while (my ($user_item, $user, $item) = $itr->next) {
        isa_ok $user_item, 'HASH';
        isa_ok $user,      'HASH';
        isa_ok $item,      'HASH';
        ok $user->{name}, 'bbb';
        ok $item->{name}, 'bbb_item';
        $count++;
    }
    is $count, 1;
};

done_testing;
