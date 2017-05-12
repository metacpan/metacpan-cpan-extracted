use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Parse::Crontab::Schedule::Entity';
}

my $entity = new_ok 'Parse::Crontab::Schedule::Entity', [entity => '*', range => [0,7], field => 'day_of_week'];
is $entity->range_min, 0;
is $entity->range_max, 7;
is_deeply $entity->expanded, [0..7];

$entity = new_ok 'Parse::Crontab::Schedule::Entity', [entity => '*/2', range => [0,7], field => 'day_of_week'];
is_deeply $entity->expanded, [0,2,4,6];

$entity = new_ok 'Parse::Crontab::Schedule::Entity', [entity => '3,*/2', range => [0,7], field => 'day_of_week'];
is_deeply $entity->expanded, [0,2,3,4,6];

$entity = new_ok 'Parse::Crontab::Schedule::Entity', [entity => '2,3-5/2,2', range => [0,7], field => 'day_of_week'];
is_deeply $entity->expanded, [2,3,5];

$entity = new_ok 'Parse::Crontab::Schedule::Entity', [
    entity  => 'mon-Tue',
    aliases => [qw/sun mon tue wed thu fri sat/],
    range   => [0,7],
    field   => 'day_of_week',
];
is_deeply $entity->expanded, [1,2];

throws_ok {
    Parse::Crontab::Schedule::Entity->new(
        entity  => 'mon-Tuo',
        aliases => [qw/sun mon tue wed thu fri sat/],
        range   => [0,7],
        field   => 'day_of_week',
    );
} qr/entity not valid/;

done_testing;
