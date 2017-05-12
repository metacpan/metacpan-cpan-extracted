requires 'perl', '5.010000';
requires 'Carp';
requires 'Redis::Script';
requires 'Redis::Transaction';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Redis';
    requires 'Test::RedisServer';
    requires 'Test::Warn';
};

on 'develop' => sub {
    requires 'Test::Kwalitee';
    requires 'Test::Kwalitee::Extra';
};
