package Redis::LeaderBoardMulti;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.02";

use Redis::LeaderBoardMulti::Member;
use Redis::Transaction qw/multi_exec watch_multi_exec/;
use Redis::Script;
use Carp;

our $SUPPORT_64BIT = eval { unpack('q>', "\x00\x00\x00\x00\x00\x00\x00\x01") };

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        use_hash    => 1,
        use_script  => 1,
        use_evalsha => 1,
        order       => ['desc'],
        %args,
    }, $class;

    $self->{hash_key} ||= $self->{key} . ":score";

    my $mask = "";
    unless (ref $self->{order}) {
        $self->{order} = [$self->{order}];
    }
    for my $order (@{$self->{order}}) {
        my $m = "\x80\x00\x00\x00\x00\x00\x00\x00";
        if ($order eq 'asc') {
            # do nothing
        } elsif ($order eq 'desc') {
            $m = ~$m;
        } else {
            die "invalid order: $order";
        }
        $mask .= $m;
    }
    $self->{_mask} = $mask;
    $self->{_pack_pattern} = ($SUPPORT_64BIT ? "q>" : "l>l>") x scalar @{$self->{order}};
    $self->{_unpack_pattern} = ($SUPPORT_64BIT ? "q>" : "l>l>") x scalar @{$self->{order}};

    return $self;
}

sub set_score {
    my $self = shift;
    for (my $i = 0; $i < @_; $i+=2) {
        $self->_set_score($_[$i], $_[$i+1]);
    }
}

sub _set_score {
    my ($self, $member, $scores) = @_;
    my $redis = $self->{redis};
    my $key = $self->{key};
    my $packed_score = $self->_pack_scores($scores);

    if ($self->{use_hash}) {
        my $hash_key = $self->{hash_key};
        if ($self->{use_script}) {
            my $script = $self->{_set_score_hash_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('HGET',KEYS[2],ARGV[1])
if s then
redis.call('ZREM',KEYS[1],s..ARGV[1])
end
redis.call('ZADD',KEYS[1],0,ARGV[2]..ARGV[1])
redis.call('HSET',KEYS[2],ARGV[1],ARGV[2])
EOS
            );
            $script->eval($redis, [$key, $hash_key], [$member, $packed_score]);
        } else {
            watch_multi_exec $redis, [$hash_key], 10, sub {
                return $redis->hget($hash_key, $member);
            }, sub {
                my (undef, $old_packed_score) = @_;
                $redis->zrem($key, "$old_packed_score$member", sub {}) if $old_packed_score;
                $redis->zadd($key, 0, "$packed_score$member", sub {});
                $redis->hset($hash_key, $member, $packed_score, sub {});
            };
        }
    } else {
        my $sub_sort_key = "$key:$member";
        if ($self->{use_script}) {
            my $script = $self->{_set_score_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('GET',KEYS[2])
if s then
redis.call('ZREM',KEYS[1],s..ARGV[1])
end
redis.call('ZADD',KEYS[1],0,ARGV[2]..ARGV[1])
redis.call('SET',KEYS[2],ARGV[2])
EOS
            );
            $script->eval($redis, [$key, $sub_sort_key], [$member, $packed_score]);
        } else {
            watch_multi_exec $redis, [$sub_sort_key], 10, sub {
                return $redis->get($sub_sort_key);
            }, sub {
                my (undef, $old_packed_score) = @_;
                $redis->zrem($key, "$old_packed_score$member", sub {}) if $old_packed_score;
                $redis->zadd($key, 0, "$packed_score$member", sub {});
                $redis->set($sub_sort_key, $packed_score, sub {});
            };
        }
    }
    $self->_set_expire_and_limit($member);
}

sub get_score {
    my ($self, $member) = @_;
    my $redis = $self->{redis};
    my $key = $self->{key};
    my $packed_score = $self->{use_hash}
        ? $redis->hget($self->{hash_key}, $member)
        : $redis->get("$key:$member");
    return unless $packed_score;
    return $self->_unpack_scores($packed_score);
}

sub incr_score {
    my ($self, $member, $scores) = @_;
    my $redis = $self->{redis};
    my $key = $self->{key};
    my $order = $self->{order};
    my @new_scores;

    $scores ||= [1];
    unless (ref $scores) {
        $scores = [$scores];
    }

    if ($self->{use_hash}) {
        my $hash_key = $self->{hash_key};
        if ($self->{use_script}) {
            my $script = $self->{_incr_score_hash_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('HGET',KEYS[2],ARGV[1]) or ''
if s~=ARGV[3] then
return 0
end
if s~='' then
redis.call('ZREM',KEYS[1],s..ARGV[1])
end
redis.call('ZADD',KEYS[1],0,ARGV[2]..ARGV[1])
redis.call('HSET',KEYS[2],ARGV[1],ARGV[2])
return 1
EOS
            );
            for (1..10) {
                my $old_packed_score = $redis->hget($hash_key, $member);
                my @old_scores;
                if ($old_packed_score) {
                    @old_scores = $self->_unpack_scores($old_packed_score);
                    $redis->zrem($key, "$old_packed_score$member", sub {});
                }

                for my $i (0..scalar(@$order)-1) {
                    push @new_scores, ($old_scores[$i] || 0) + ($scores->[$i] || 0);
                }
                my $packed_score = $self->_pack_scores(\@new_scores);
                if ($script->eval($redis, [$key, $hash_key], [$member, $packed_score, $old_packed_score || ''])) {
                    last;
                }
            }
        } else {
            watch_multi_exec $redis, [$hash_key], 10, sub {
                return $redis->hget($hash_key, $member);
            }, sub {
                my (undef, $old_packed_score) = @_;
                my @old_scores;
                if ($old_packed_score) {
                    @old_scores = $self->_unpack_scores($old_packed_score);
                    $redis->zrem($key, "$old_packed_score$member", sub {});
                }

                for my $i (0..scalar(@$order)-1) {
                    push @new_scores, ($old_scores[$i] || 0) + ($scores->[$i] || 0);
                }
                my $packed_score = $self->_pack_scores(\@new_scores);
                $redis->zadd($key, 0, "$packed_score$member", sub {});
                $redis->hset($hash_key, $member, $packed_score, sub {});
            };
        }
    } else {
        my $sub_sort_key = "$key:$member";
        watch_multi_exec $redis, [$sub_sort_key], 10, sub {
            return $redis->get($sub_sort_key);
        }, sub {
            my (undef, $old_packed_score) = @_;
            my @old_scores;
            if ($old_packed_score) {
                @old_scores = $self->_unpack_scores($old_packed_score);
                $redis->zrem($key, "$old_packed_score$member", sub {});
            }

            for my $i (0..scalar(@$order)-1) {
                push @new_scores, ($old_scores[$i] || 0) + ($scores->[$i] || 0);
            }
            my $packed_score = $self->_pack_scores(\@new_scores);
            $redis->zadd($key, 0, "$packed_score$member", sub {});
            $redis->set($sub_sort_key, $packed_score, sub {});
        };
    }
    $self->_set_expire_and_limit($member);

    return wantarray ? @new_scores : $new_scores[0];
}

sub decr_score {
    my ($self, $member, $scores) = @_;
    $scores ||= [1];
    unless (ref $scores) {
        $scores = [$scores];
    }
    for my $i (0..scalar(@$scores)-1) {
        $scores->[$i] *= -1;
    }
    return $self->incr_score($member, $scores);
}

sub _set_expire_and_limit {
    my ($self, $member) = @_;
    my $redis = $self->{redis};
    if (my $expire_at = $self->{expire_at}) {
        $redis->expireat($self->{key}, $expire_at);
        if ($self->{use_hash}) {
            $redis->expireat($self->{hash_key}, $expire_at);
        } else {
            $redis->expireat($self->{key}.":".$member, $expire_at);
        }
    }

    if ($self->{limit}) {
        $self->_set_limit;
    }
}

sub _set_limit {
    my $self = shift;
    my $redis = $self->{redis};

    my $limit = $self->{limit};
    my $key = $self->{key};
    my $scorelen = @{$self->{order}}*8;
    if ($self->{use_hash}) {
        my $hash_key = $self->{hash_key};
        if ($self->{use_script}) {
            my $script = $self->{_limit_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local k=KEYS[1]
local l=ARGV[1]
local s=redis.call('ZRANGE',k,l,-1)
if #s==0 then
return
end
for i=1,#s do
s[i]=string.sub(s[i],ARGV[2])
end
redis.call('HDEL',KEYS[2],unpack(s))
redis.call('ZREMRANGEBYRANK',k,l,-1)
EOS
            );
            $script->eval($redis, [$key, $hash_key], [$limit, $scorelen]);
        } else {
            watch_multi_exec $redis, [$key], 10, sub {
                return $redis->zrange($key, $limit, -1);
            }, sub {
                shift; #ignore $redis
                return unless @_;
                $redis->hdel($hash_key, (map { substr $_, $scorelen } @_), sub {});
                $redis->zremrangebyrank($key, $limit, -1, sub {});
            };
        }
    } else {
        if ($self->{use_script}) {
            my $script = $self->{_limit_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local k=KEYS[1]
local l=ARGV[1]
local s=redis.call('ZRANGE',k,l,-1)
if #s==0 then
return
end
for i=1,#s do
s[i]=k..":"..string.sub(s[i],ARGV[2])
end
redis.call('DEL',unpack(s))
redis.call('ZREMRANGEBYRANK',k,l,-1)
EOS
            );
            $script->eval($redis, [$key], [$limit, $scorelen]);
        } else {
            watch_multi_exec $redis, [$key], 10, sub {
                return $redis->zrange($key, $limit, -1);
            }, sub {
                shift; #ignore $redis
                return unless @_;
                $redis->del((map { $key.":".substr($_, $scorelen) } @_), sub {});
                $redis->zremrangebyrank($key, $limit, -1, sub {});
            };
        }
    }
}

sub remove {
    my ($self, $member) = @_;
    my $redis = $self->{redis};
    my $key = $self->{key};

    if ($self->{use_hash}) {
        my $hash_key = $self->{hash_key};
        if ($self->{use_script}) {
            my $script = $self->{_remove_hash_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('HGET',KEYS[2],ARGV[1])
if s then
redis.call('ZREM',KEYS[1],s..ARGV[1])
redis.call('HDEL',KEYS[2],ARGV[1])
end
EOS
            );
            $script->eval($redis, [$key, $hash_key], [$member]);
        } else {
            watch_multi_exec $redis, [$hash_key], 10, sub {
                return $redis->hget($hash_key, $member);
            }, sub {
                my (undef, $packed_score) = @_;
                if ($packed_score) {
                    $redis->zrem($key, "$packed_score$member");
                    $redis->hdel($hash_key, $member);
                }
            };
        }
    } else {
        my $sub_sort_key = "$key:$member";
        if ($self->{use_script}) {
            my $script = $self->{_remove_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('GET',KEYS[2])
if s then
redis.call('ZREM',KEYS[1],s..ARGV[1])
redis.call('DEL',KEYS[2])
end
EOS
            );
            $script->eval($redis, [$key, $sub_sort_key], [$member]);
        } else {
            watch_multi_exec $redis, [$sub_sort_key], 10, sub {
                return $redis->get($sub_sort_key);
            }, sub {
                my (undef, $packed_score) = @_;
                if ($packed_score) {
                    $redis->zrem($key, "$packed_score$member");
                    $redis->del($sub_sort_key);
                }
            };
        }
    }
}

sub get_sorted_order {
    my ($self, $member) = @_;
    my $redis = $self->{redis};
    my $key = $self->{key};
    my $order;

    if ($self->{use_hash}) {
        my $hash_key = $self->{hash_key};
        if ($self->{use_script}) {
            my $script = $self->{_get_sort_order_hash_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('HGET',KEYS[2],ARGV[1])
return redis.call('ZRANK',KEYS[1],s..ARGV[1])
EOS
            );
            $order = $script->eval($redis, [$key, $hash_key], [$member]);
        } else {
            my $packed_score = $redis->hget($hash_key, $member);
            $order = $redis->zrank($key, "$packed_score$member");
        }
    } else {
        my $sub_sort_key = "$key:$member";
        if ($self->{use_script}) {
            my $script = $self->{_get_sort_order_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('GET',KEYS[2])
return redis.call('ZRANK',KEYS[1],s..ARGV[1])
EOS
            );
            $order = $script->eval($redis, [$key, $sub_sort_key], [$member]);
        } else {
            ($order) = watch_multi_exec $redis, [$sub_sort_key], 10, sub {
                return $redis->get($sub_sort_key);
            }, sub {
                my (undef, $packed_score) = @_;
                $redis->zrank($key, "$packed_score$member", sub {});
            };
        }
    }
    return $order;
}

sub get_rank {
    my ($self, $member) = @_;
    my ($rank) = $self->get_rank_with_score($member);
    return $rank;
}

sub get_rank_with_score {
    my ($self, $member) = @_;
    my $redis = $self->{redis};
    my $key = $self->{key};
    my $sub_sort_key = "$key:$member";

    my $rank;
    my $packed_score;
    if ($self->{use_hash}) {
        my $hash_key = $self->{hash_key};
        if ($self->{use_script}) {
            my $script = $self->{_get_rank_with_score_hash_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('HGET',KEYS[2],ARGV[1])
if not s then
return {nil, nil}
end
return {s,redis.call('ZLEXCOUNT',KEYS[1],'-','('..s)}
EOS
            );
            ($packed_score, $rank) = $script->eval($redis, [$key, $hash_key], [$member]);
        } else {
            $packed_score = $redis->hget($hash_key, $member);
            $rank = $redis->zlexcount($key, '-', "($packed_score") if $packed_score;
        }
    } else {
        my $sub_sort_key = "$key:$member";
        if ($self->{use_script}) {
            my $script = $self->{_get_rank_with_score_script} ||= Redis::Script->new(
                use_evalsha => $self->{use_evalsha},
                script      => <<EOS,
local s=redis.call('GET',KEYS[2])
if not s then
return {nil, nil}
end
return {s,redis.call('ZLEXCOUNT',KEYS[1],'-','('..s)}
EOS
            );
            ($packed_score, $rank) = $script->eval($redis, [$key, $sub_sort_key], []);
        } else {
            ($rank) = watch_multi_exec $redis, [$sub_sort_key], 10, sub {
                $packed_score = $redis->get($sub_sort_key);
            }, sub {
                $redis->zlexcount($key, '-', "($packed_score") if $packed_score;
            };
        }
    }

    return if !defined $rank or !defined $packed_score;
    return $rank + 1, $self->_unpack_scores($packed_score);
}

sub get_rank_by_score {
    my ($self, $scores) = @_;
    my $redis = $self->{redis};
    my $key = $self->{key};

    my $packed_score = $self->_pack_scores($scores);
    my $rank = $redis->zlexcount($key, '-', "[$packed_score");

    return $rank + 1;
}

sub member_count {
    my ($self, $from, $to) = @_;

    if (!$from && !$to) {
        $self->{redis}->zcard($self->{key});
    }
    else {
        $from = defined $from ? $from : '-inf';
        $to   = defined $to   ? $to   : 'inf';
        $self->{redis}->zcount($self->{key}, $from, $to);
    }
}

sub rankings {
    my ($self, %args) = @_;
    my $limit  = exists $args{limit}  ? $args{limit}  : $self->member_count;
    my $offset = exists $args{offset} ? $args{offset} : 0;

    my $members_with_scores = $self->{redis}->zrange($self->{key}, $offset, $offset + $limit - 1);
    return [] unless @$members_with_scores;

    my @rankings;
    my ($current_rank, $current_target_scores, $same_score_members);
    for my $member_with_score (@$members_with_scores) {
        my $scores = [$self->_unpack_scores($member_with_score)];
        my $member = substr $member_with_score, 8*@$scores;

        if (!$current_rank) {
            $current_rank          = $self->get_rank_by_score($scores);
            $same_score_members    = $offset - $current_rank + 2;
            $current_target_scores = $scores;
        }
        elsif (!grep { $scores->[$_] != $current_target_scores->[$_] } 0..@$scores-1) {
            $same_score_members++;
        }
        else {
            $current_target_scores = $scores;
            $current_rank = $current_rank + $same_score_members;
            $same_score_members = 1;
        }
        push @rankings, +{
            member => $member,
            score  => $scores->[0],
            rank   => $current_rank,
            scores => $scores,
        };
    }

    \@rankings;
}

sub find_member {
    my ($self, $member) = @_;

    Redis::LeaderBoardMulti::Member->new(
        member       => $member,
        leader_board => $self,
    );
}

sub _pack_scores {
    my ($self, $scores) = @_;
    unless(ref $scores) {
        $scores = [$scores];
    }
    my $num = scalar @$scores;
    my $order = $self->{order};
    die "the number of scores is illegal" if $num != scalar @$order;
    if ($SUPPORT_64BIT) {
        return pack($self->{_pack_pattern}, @$scores) ^ $self->{_mask};
    } else {
        return pack(
            $self->{_pack_pattern},
            # sign extension
            map { ($_<0?-1:0), $_ } @$scores
        ) ^ $self->{_mask};
    }
}

sub _unpack_scores {
    my ($self, $packed_score) = @_;
    my @scores = unpack($self->{_unpack_pattern}, $packed_score ^ $self->{_mask});
    if ($SUPPORT_64BIT) {
        return wantarray ? @scores : $scores[0];
    } else {
        my @s;
        for (my $i = 0; $i < @scores; $i += 2) {
            # check overflow
            if (($scores[$i+1]>=0&&$scores[$i]!=0) || ($scores[$i+1]<0&&$scores[$i]!=-1)) {
                carp "[Redis::LeaderBoardMulti] score overflow";
            }
            push @s, $scores[$i+1];
        }
        return wantarray ? @s : $s[0];
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Redis::LeaderBoardMulti - Redis leader board considering multiple scores

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Redis::LeaderBoardMulti is for providing leader board by using Redis's sorted set.
Redis::LeaderBoard considers only one score, while Redis::LeaderBoardMulti can consider secondary score.

=head1 LICENSE

Copyright (C) Ichinose Shogo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ichinose Shogo E<lt>shogo82148@gmail.comE<gt>

=cut

