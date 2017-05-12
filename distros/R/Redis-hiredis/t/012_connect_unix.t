use strict;
use warnings;
use Test::More;

plan skip_all => q/$ENV{'REDISPATH'} isn't set/ if !defined $ENV{REDISPATH};
{
    use_ok 'Redis::hiredis';
    my $h = Redis::hiredis->new();
    isa_ok($h, 'Redis::hiredis');

    my $path = $ENV{'REDISPATH'};

    my $c = $h->connect_unix($path);
    is($c, undef, 'connect success');

    my $r;
    $r = $h->command('ping');
    is $r, 'PONG', 'reply of ping command';
}

done_testing;
