use strict;
use warnings;

use Test::More;

use Routes::Tiny;

subtest 'not match when contstraint fails' => sub {
    my $r = Routes::Tiny->new;

    $r->add_route(
        '/articles/:id',
        name        => 'article',
        constraints => {id => qr/\d+/}
    );

    my $m = $r->match('articles/abc');
    ok(!$m);
};

subtest 'match when contstraint is ok' => sub {
    my $r = Routes::Tiny->new;

    $r->add_route(
        '/articles/:id',
        name        => 'article',
        constraints => {id => qr/\d+/}
    );

    my $m = $r->match('articles/123');
    is_deeply($m->params, {id => 123});
    is($r->build_path('article', id => 123), '/articles/123');
};

subtest 'throws when building path with not passing constraint' => sub {
    my $r = Routes::Tiny->new;

    $r->add_route(
        '/articles/:id',
        name        => 'article',
        constraints => {id => qr/\d+/}
    );

    eval { $r->build_path('article', id => 'abc'); };
    ok($@ =~ qr/Param 'id' fails a constraint/);
};

subtest 'contraint as array' => sub {
    my $r = Routes::Tiny->new;

    $r->add_route(
        '/articles/:id',
        name        => 'article',
        constraints => {id => [qw/1 2 3/]}
    );

    ok $r->match('/articles/2');
    is_deeply($r->match('/articles/2')->params, {id => 2});
    ok !$r->match('/articles/a');

    eval { $r->build_path('article', id => 'abc'); };
    ok($@ =~ qr/Param 'id' fails a constraint/);
};

done_testing;
