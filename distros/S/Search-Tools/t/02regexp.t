use Test::More tests => 68;

BEGIN {
    use POSIX qw(locale_h);
    use locale;

    # treat the 8bit chars below as latin1, otherwise Perl converts to utf8
    setlocale( LC_ALL, 'C' );

    #use encoding 'iso-8859-1';  # this does NOT work as expected.
}

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

use Carp;

use_ok('Search::Tools::QueryParser');

my @q = (
    'the quick'                         => 'quick',         # stopwords
    'color:brown       fox'             => 'brown fox',     # fields
    '+jumped and +ran         -quickly' => 'jumped ran',    # booleans
    '"over the or lazy        and dog"' =>
        'over the or lazy and dog',                         # phrase
    'foo* food bar' => 'foo* food bar',                     # wildcard
    'foo foo*'      => 'foo*',                              # unique wildcard
    'ªµº ÀÁÂÃÄÅÆ Ç ÈÉÊË ÌÍÎÏ ÐÑ ÒÓÔÕÖØ ÙÚÛÜ ÝÞ ß àáâãäåæ ç èéêë ìíîï ð ñ òóôõöø ùúûü ýþÿ'
        => 'ªµº ÀÁÂÃÄÅÆ Ç ÈÉÊË ÌÍÎÏ ÐÑ ÒÓÔÕÖØ ÙÚÛÜ ÝÞ ß àáâãäåæ ç èéêë ìíîï ð ñ òóôõöø ùúûü ýþÿ' # 8bit chars
);

ok( my $parser = Search::Tools::QueryParser->new(
        locale    => 'en_US.iso-8859-1',
        stopwords => 'the'
    ),

    "qparser object"
);

my $total_terms = 0;
while ( my $str = shift(@q) ) {
    ok( my $query = $parser->parse($str), "parse query >>$str<<" );  # 7 tests
    my $expected = shift(@q);

    #diag( "expected = " . $query->num_terms );
    $total_terms += $query->num_terms;

    for my $term ( @{ $query->terms } ) {
        my $r = $query->regex_for($term);

        #diag($term);
        like( $term, $r->plain, $term );
        like( $term, $r->html,  $term );

        #diag($r->plain);

    }
}
is( $total_terms, 29, "29 total terms" );

#diag("total terms = $total_terms");
