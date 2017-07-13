use strict;
use warnings;

use Test::More;

use Routes::Tiny;

subtest 'matches simple route case sensitive (default)' => sub {
    my $r = Routes::Tiny->new(strict_case => 1);

    $r->add_route('/admin/', name => 'route');

    ok $r->match('/admin/');
    ok !$r->match('/ADMIN/');
    ok !$r->match('/AdMiN/');
};

subtest 'matches simple route case insensitive' => sub {
    my $r = Routes::Tiny->new(strict_case => 0);

    $r->add_route('/ADMIN/', name => 'route');

    ok $r->match('/admin/');
    ok $r->match('/ADMIN/');
    ok $r->match('/AdMiN/');
};

subtest 'matches subroutes case sensitive' => sub {
    my $r  = Routes::Tiny->new(strict_case => 1);
    my $r2 = Routes::Tiny->new(strict_case => 0);

    $r2->add_route('/info/', name => 'info');
    $r->mount('/admin/', $r2);

    ok $r->match('/admin/info/');
    ok $r->match('/admin/INFO/');
    ok !$r->match('/ADMIN/info/');
    ok !$r->match('/AdMiN/info/');
};

done_testing;
