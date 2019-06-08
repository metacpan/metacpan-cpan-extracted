use Test::More;
use Search::QS;
use File::Basename;
use lib dirname (__FILE__);
use URLEncode;
use URI::Escape;

my $num = 0;

my $qs = new Search::QS;

isa_ok($qs->filters, 'Search::QS::Filters');
$num++;

isa_ok($qs->options, 'Search::QS::Options');
$num++;

my $qs ='flt[c:one]=1&flt[c:one]=$and:1&flt[d:one]=2&flt[d:one]=$and:1&'.
    'flt[c:two]=2&flt[c:two]=$and:2&flt[d:two]=3&flt[d:two]=$op:>&'.
    'flt[d:two]=$and:2&flt[d:three]=10&start=5&limit=8&sort[name]=asc&sort[type]=desc';
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;

# encoded query as_string
# SQL: ( Name = Foo )
$qs = 'flt%5BName%5D=Foo';
is(convert_url_params_to_filter_and_return($qs), uri_unescape($qs));
$num++;

done_testing($num);

sub convert_url_params_to_filter_and_return {
    my $qs = shift;
    my $struct = url_params_mixed($qs);
    return &to_qs($struct);
}

sub to_qs {
    my $struct = shift;

    my $qs = new Search::QS;
    $qs->parse($struct);

    return $qs->to_qs;
}
