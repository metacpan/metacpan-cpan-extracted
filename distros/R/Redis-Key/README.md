# NAME

Redis::Key - wrapper class of Redis' key

# SYNOPSIS

    use Redis;
    use Redis::Key;
    my $redis = Redis->new;
    
    # basic usage
    my $key = Redis::Key->new(redis => $redis, key => 'hoge');
    $key->set('fuga');  # => $redis->set('hoge', 'fuga');
    print $key->get;    # => $redis->get('hoge');
    
    # bind
    my $key_unbound = Redis::Key->new(redis => $redis, key => 'hoge:{fugu}:piyo', need_bind => 1);
    my $key_fugu = $key_unbound->bind(fugu => 'FUGU');
    $key_fugu->set('foobar');      # => $redis->set('hoge:FUGU:piyo', 'foobar');
    my @keys = $key_unbound->keys; # => $redis->keys('hoge:*:piyo');

# DESCRIPTION

Redis::Key is a wrapper class of Redis' keys.

# AUTHOR

Ichinose Shogo <shogo82148@gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
