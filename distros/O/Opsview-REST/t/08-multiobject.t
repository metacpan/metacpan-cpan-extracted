
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Opsview::REST::TestUtils;

use Try::Tiny;

use Test::More;
use Test::Exception;

use Data::Dumper;

BEGIN { use_ok 'Opsview::REST::Config'; };

my @tests = (
    {
        args => ['hostgroup'],
        url  => '/config/hostgroup',
    },
    {
        args => ['host'],
        url  => '/config/host',
    },
    {
        args => ['host', json_filter => '{"name":{"-like":"%opsview%"}}'],
        url  => '/config/host?json_filter=%7B%22name%22%3A%7B%22-like%22%3A%22%25opsview%25%22%7D%7D',
    },
);

test_urls('Opsview::REST::Config', @tests);

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 7
        if (not defined $ENV{OPSVIEW_REST_TEST});

    my $ops  = get_opsview();

    my $name = 'Application';
    my $res = $ops->get_hosttemplates(name => { '-like' => "$name%" });

    my $summ = $res->{summary};
    ok(defined $summ, "Got a summary back");
    cmp_ok($summ->{rows}, '==', 17, "There are 17 rows");
    my $matches = scalar grep { $_->{name} =~ /$name/ } @{ $res->{list} };
    cmp_ok($matches, '==', 17, 'All retrieved names match');

    my ($name1, $name2) = (get_random_name(), get_random_name());
    $res = $ops->create_contact([
        {
            name     => $name1,
            fullname => $name1,
        },
        {
            name     => $name2,
            fullname => $name2,
        },
    ]);
    ok($res->{objects_updated}, 'Create two contacts in one call');

    throws_ok {
        $ops->create_contacts([
            {
                name     => $name1,
                fullname => $name1,
            },
            {
                name     => $name2,
                fullname => $name2,
            },
        ]);
    } qr/Duplicate entry/, "Can't create them again";

    my $descr1 = get_random_name();
    my $cont = $ops->get_contacts(
        name => [ $name1, $name2 ],
    );
    map { $_->{description} = $descr1 } @{ $cont->{list} };

    lives_ok {
        $res = $ops->create_or_update_contacts($cont->{list});
    } "create_or_update didn't die";

    $res = $ops->get_contacts(name => [ $name1, $name2 ]);
    is($res->{summary}->{rows}, 2, 'Got back two contacts in search');

    for (@{ $res->{list} }) {
        is($_->{description}, $descr1, "Contact $_->{id} correctly updated");
        $res = $ops->delete_contact($_->{id});
        ok($res->{success}, "Contact $_->{id} deleted");
    }
}

done_testing;
