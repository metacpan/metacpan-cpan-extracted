
use Test::More tests => 5;
use Search::Odeum;
use File::Path qw(rmtree);

my $db = './t/04_query.db';
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
    {
        my $res = $odeum->query('orange & apple & strawberry');
        is($res->num, 1);
        my $doc = $res->next;
        if ($doc) {
            is($doc->uri, 'http://example.com/4');
        }
    }
    {
        my $res = $odeum->query('orange  ! apple');
        is($res->num, 1);
        my $doc = $res->next;
        is($doc->uri, 'http://example.com/3');
    }
    $odeum->close;
}

END {
    rmtree($db);
};

__END__

