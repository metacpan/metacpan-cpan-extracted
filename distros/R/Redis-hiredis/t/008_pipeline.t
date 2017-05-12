use strict;
use warnings;
use Test::More;

plan skip_all => q/$ENV{'REDISHOST'} isn't set/
    if !defined $ENV{'REDISHOST'};

{
    use_ok 'Redis::hiredis';
    my $h = Redis::hiredis->new();
    isa_ok($h, 'Redis::hiredis');
    
    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;
    
    my $r;
    my $c = $h->connect($host, $port);
    is($c, undef, 'connect success');
    
    my $prefix = "Redis-hiredis-$$-";
    
    $h->command("set $prefix:foo0 bar0");
    $h->command("set $prefix:foo1 bar1");
    $h->command("set $prefix:foo2 bar2");
    
    $h->append_command("get $prefix:foo0");
    $h->append_command("get $prefix:foo1");
    $h->append_command("get $prefix:foo2");
    
    my $r0 = $h->get_reply();
    my $r1 = $h->get_reply();
    my $r2 = $h->get_reply();
    
    is $r0, 'bar0', 'pipeline reply 0';
    is $r1, 'bar1', 'pipeline reply 1';
    is $r2, 'bar2', 'pipeline reply 2';
    
    $h->append_command("rpush $prefix:list aaa");
    $h->append_command("rpush $prefix:list bbb");
    $h->append_command("rpush $prefix:list ccc");
    $h->append_command("lrange $prefix:list 0 3");
    
    is $h->get_reply(), 1, 'rpush reply0';
    is $h->get_reply(), 2, 'rpush reply1';
    is $h->get_reply(), 3, 'rpush reply2';
    
    is_deeply $h->get_reply(), [ qw(aaa bbb ccc) ], 'lrange reply';
}

done_testing();
