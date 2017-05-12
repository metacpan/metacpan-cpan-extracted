# NAME

Redis::LeaderBoard - leader board using Redis

# SYNOPSIS

    use Redis;
    use Redis::LeaderBoard;
    my $redis = Redis->new;
    my $lb = Redis::LeaderBoard->new(
        redis => $redis,
        key   => 'leader_board:1',
        order => 'asc', # asc/desc, desc as default
    );
    $lb->set_score('one' => 100');
    $lb->set_score('two' =>  50');
    my ($rank, $score) = $lb->get_rank_with_score('one');

    # memmber object
    my $member = $lb->find_member('two');
    $member->score(90);
    my $rank2 = $member->rank;

# DESCRIPTION

Redis::LeaderBoard is for providing leader board by using Redis's sorted set.

z(rev)?rank of Redis 2.8 or older doesn't consider same scores.
This module resolve it.

# INTERFACE

## Constructor

### `my $lb = Redis::LeaderBoard->new(%options)`

Create a new leader board object. Options should be set in `%options`.

- `redis: Redis`

    Redis object. Redis.pm or Redis::hiredis.

- `key: Str`

    Required.

- `order: Enum(asc/desc)`

    Optional. `desc` as default.

## Methods

### `$member_obj:Redis::LeaderBoard::Member = $lb->find_member($member:Str)`

Find member by member id. see [Redis::LeaderBoard::Member](https://metacpan.org/pod/Redis::LeaderBoard::Member) for more details.

### `$lb->set_score($member:Str, $score:Number, [$member2, $score2,...])`

Set scores of members. You can set multiple element if using Redis 2.4 or later.

### `$score:Number = $lb->get_score($member:Str)`

Get score of member.

### `$score:Number = $lb->incr_score($member:Str, [$increment_score:Number])`

increment score of member and returns reflected score. 1 is default `$increment_score`.

### `$score:Number = $lb->decr_score($member:Str, [$decrement_score:Number])`

decrement score of member and returns reflected score. 1 is default `$decrement_score`.

### `$lb->remove($member:Str, [$member2:Str,...])`

remove members from leader board. Multiple element can be accepted Redis 2.4 or later.

### `($rank:Int, $score:Number) = $lb->get_rank_with_score($member:Str)`

Returns rank and score. If you want to get rank and score at the same time,
you should not call `get_score` and `get_rank` separately, use this method instead for
performance.

### `$rank:Int = $lb->get_rank($member:Str)`

Get rank of member.

### `$order:Int = $lb->get_sorted_order($member:Str)`

Get sorted order in sorted set. (same as `$redis->zrank`)

### `$count = $lb->member_count([$from, $to])`

Get number of members. If score range (`$from` and `$to`) is specified, it returns a number
of members in range.

### `$rankings:ArrayRef<HashRef> = $lb->rankings(%opt)`

Return rankings by arrayref contains hashrefs.
keys of hashref is `member:Str`, `rank:Int` and `score:Number`.

Options can be set in `%options`. keys of options are as follows.

- `limit: Int`
- `offset: Int`

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>
