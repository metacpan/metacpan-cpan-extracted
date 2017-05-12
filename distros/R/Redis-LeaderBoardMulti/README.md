# NAME

Redis::LeaderBoardMulti - Redis leader board considering multiple scores

# SYNOPSIS

    use Redis;
    use Redis::LeaderBoard;
    my $redis = Redis->new;
    my $lb = Redis::LeaderBoardMulti->new(
        redis => $redis,
        key   => 'leader_board:1',
        order => ['asc', 'desc'], # asc/desc, desc as default
    );
    $lb->set_score('one' => 100, time);
    $lb->set_score('two' =>  50, time);
    my ($rank, $score) = $lb->get_rank_with_score('one');

# DESCRIPTION

Redis::LeaderBoardMulti is for providing leader board by using Redis's sorted set.
Redis::LeaderBoard considers only one score, while Redis::LeaderBoardMulti can consider secondary score.

# LICENSE

Copyright (C) Ichinose Shogo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ichinose Shogo <shogo82148@gmail.com>
