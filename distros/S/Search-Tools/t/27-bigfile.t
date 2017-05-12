use strict;
use Test::More;
use lib 't';
plan skip_all => "set TEST_BIG_FILE to run $0"
    unless $ENV{TEST_BIG_FILE};

SKIP: {
    eval 'use IO::Uncompress::Gunzip ()';
    skip 'IO::Uncompress::Gunzip is required to test bigfile', 2
        if $@;

    use Data::Dump qw( dump );
    use Search::Tools::XML;
    use Search::Tools::Snipper;
    use Search::Tools::Tokenizer;

    my $file = 't/docs/bigfile.html.gz';
    my $q    = qq/child adoption/;
    my $fh   = IO::Uncompress::Gunzip->new($file);
    my $buf;
    {
        local $/;
        $buf = <$fh>;
        $buf = $buf x 20;    # 20x for big fun
    }
    diag( "working on " . length($buf) . " html bytes" );
    my $plain = Search::Tools::XML->strip_html($buf);
    diag( "working on " . length($plain) . " plain bytes" );
    my $snipper = Search::Tools::Snipper->new(
        query        => $q,
        occur        => 1,
        context      => 25,
        max_chars    => 190,
        as_sentences => 1,
        type         => 'offset',    # because we want to profile
    );

    #my $tokenizer = Search::Tools::Tokenizer->new();
    #diag("get_offsets");
    #my $offsets = $tokenizer->get_offsets($plain, qr/child/i);
    #diag("get_offsets done");
    #diag(dump $offsets);

    my $snip = $snipper->snip($plain);

    like( $snip, qr/child .+ child/, "match snip" );
    cmp_ok( length $snip, '<', 200, "length is sane" );
    
    done_testing(2);
    #sleep 5;   # just so we can measure mem use manually

}
