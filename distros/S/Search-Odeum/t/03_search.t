
use Test::More tests => 8;
use Search::Odeum;
use File::Path qw(rmtree);

my $db = './t/03_search.db';
my @data = (
    {
        uri => 'http://perl.org/',
        document => 'This is Perl',
    },
    {
        uri => 'http://www.ruby-lang.org/',
        document => 'This is Ruby',
    },
    {
        uri => 'http://www.example.com/',
        document => 'This is example',
    }
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
    ok(!$odeum->writable);
    ok($odeum->fsiz > 0);
    is($odeum->dnum, 3);
    is($odeum->wnum, 5);

    {
        my $res = $odeum->search('Perl', 10);
        is($res->num, 1);
        my $doc = $res->next;
        is($doc->uri, 'http://perl.org/');
    }

    {
        my $res = $odeum->search('This', 10);
        is($res->num, 3);
    }

    $odeum->close;
}

END {
    rmtree($db);
};

__END__

