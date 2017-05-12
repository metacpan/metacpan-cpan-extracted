
#use Test::More tests => 8;
use Test::More 'no_plan';
use Search::Odeum;
use File::Path qw(rmtree);

my $db = './t/05_op.db';
my @data = (
    {
        uri => 'http://example.com/1',
        document => 'apple',
    },
    {
        uri => 'http://example.com/2',
        document => 'orange apple',
    },
    {
        uri => 'http://example.com/3',
        document => 'strawberry orange',
    },
    {
        uri => 'http://example.com/4',
        document => 'strawberry orange apple',
    },
    {
        uri => 'http://example.com/5',
        document => 'grape',
    },
);

{
    my $odeum = Search::Odeum->new($db, OD_OCREAT|OD_OWRITER);
    ok($odeum->writable);
    for my $d(@data) {
        my $doc = Search::Odeum::Document->new($d->{uri});
        for my $word(split /\s+/, $d->{document}) {
            $doc->addword($word, $word);
        }
        $odeum->put($doc);
    }
    $odeum->close;
}

{
    my $odeum = Search::Odeum->new($db, OD_OREADER);
    my $res1 = $odeum->search('apple');
    my $res2 = $odeum->search('orange');
    my $res3 = $odeum->search('strawberry');
    my $res4 = $odeum->search('grape');

    {
        my $res = $res1->and_op($res2);
        is($res->num, 2);
        my %docs;
        while (my $doc = $res->next) {
            $docs{$doc->uri} = 1;
        }
        is_deeply({
            'http://example.com/2' => 1,
            'http://example.com/4' => 1,
        }, \%docs);
    }

    {
        my $res = $res1->or_op($res4);
        is($res->num, 4);
        my %docs;
        while (my $doc = $res->next) {
            $docs{$doc->uri} = 1;
        }
        is_deeply({
            'http://example.com/1' => 1,
            'http://example.com/2' => 1,
            'http://example.com/4' => 1,
            'http://example.com/5' => 1,
        }, \%docs);
    }

    {
        my $res = $res2->notand_op($res3);
        is($res->num, 1);
        my %docs;
        while (my $doc = $res->next) {
            $docs{$doc->uri} = 1;
        }
        is_deeply({
            'http://example.com/2' => 1,
        }, \%docs);
    }

    $odeum->close;
}

END {
    rmtree($db);
};

__END__

