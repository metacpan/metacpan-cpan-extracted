use Test::More;
use Data::Dumper;
use Search::QS;
use File::Basename;
use lib dirname (__FILE__);
use URLEncode;
use URI::Escape;

my $num = 0;

$qs = 'flt[Name]=Foo'; # SQL: (Name = Foo)
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;

my $qs = 'flt[age]=5&flt[age]=9&flt[Name]=Foo';
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;

$qs = 'flt[FirstName]=Foo&flt[FirstName]=$or:1&flt[LastName]=Bar&flt[LastName]=$or:1';
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;

$qs ='flt[c:one]=1&flt[c:one]=$and:1&flt[d:one]=2&flt[d:one]=$and:1&'.
    'flt[c:two]=2&flt[c:two]=$and:2&flt[d:two]=3&flt[d:two]=$op:>&'.
    'flt[d:two]=$and:2&flt[d:three]=10';
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

    my $filters = new Search::QS->filters;
    $filters->parse($struct);

    return $filters->to_qs;
}
