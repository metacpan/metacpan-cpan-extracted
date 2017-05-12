use strict;
use warnings;
use Test::More;

plan skip_all => q/$ENV{'REDISHOST'} isn't set/
    if !defined $ENV{'REDISHOST'};

{
    use_ok 'Redis::hiredis';
    my $h = Redis::hiredis->new();
    isa_ok $h, 'Redis::hiredis';

    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;

    # bad connect
    eval { $h->connect('fake_host', $port); };
    ok ( $@, 'connect failed correctly');

    eval { $h->connect($host, $port); };
    ok ( ! $@, 'connect worked' );

    # bad command
    eval { $h->command( 'NO_SUCH_CMD' ); };
    ok ( $@, 'command failed correctly' );

    # partially bad pipeline
    eval { $h->append_command('BAD_CMD0'); };
    ok ( ! $@, 'append_command 0 worked' );

    eval { $h->append_command('PING'); };
    ok ( ! $@, 'append_command 1 worked' );

    eval { $h->append_command('BAD_CMD2'); };
    ok ( ! $@, 'append_command 2 worked' );

    eval { $h->get_reply(); };
    ok ( $@, 'pipeline cmd 0 failed correctly' );

    eval { $h->get_reply(); };
    ok ( ! $@, 'pipeline cmd 1 worked' );

    eval { $h->get_reply(); };
    ok ( $@, 'pipeline cmd 2 failed correctly' );
};

done_testing();
