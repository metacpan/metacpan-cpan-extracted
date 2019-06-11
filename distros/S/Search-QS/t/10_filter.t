package main;

use Test::More;
use Data::Dumper;
use Search::QS::Filter;
use Search::QS::Filters;
use File::Basename;
use lib dirname (__FILE__);
use URLEncode;
use URI::Escape;
use feature "switch";


my $num = 0;

# SQL: (Name = Foo)
$qs = 'flt[Name]=Foo';
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;
print_all($qs);

# SQL :(age = 5 OR age = 9) AND (Name = Foo)
my $qs = 'flt[age]=5&flt[age]=9&flt[Name]=Foo';
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;
print_all($qs);

# SQL: ( (FirstName = Foo) OR (LastName = Bar) )
$qs = 'flt[FirstName]=Foo&flt[FirstName]=$or:1&flt[LastName]=Bar&flt[LastName]=$or:1';
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;
print_all($qs);

# SQL: (d = 10) AND  ( (c = 1) AND (d = 2) )  OR  ( (c = 2) AND (d > 3) )
$qs ='flt[c:one]=1&flt[c:one]=$and:1&flt[d:one]=2&flt[d:one]=$and:1&'.
    'flt[c:two]=2&flt[c:two]=$and:2&flt[d:two]=3&flt[d:two]=$op:>&'.
    'flt[d:two]=$and:2&flt[d:three]=10';
is(convert_url_params_to_filter_and_return($qs), $qs);
$num++;
print_all($qs);

# encoded query as_string
# SQL: ( Name = Foo )
$qs = 'flt%5BName%5D=Foo';
is(convert_url_params_to_filter_and_return($qs), uri_unescape($qs));
$num++;
print_all($qs);

done_testing($num);

sub convert_url_params_to_filter_and_return {
    my $qs = shift;
    my $struct = url_params_mixed($qs);
    return &to_qs($struct);
}

sub print_all {
    my $qs = shift;
    my $struct = url_params_mixed($qs);
    print Data::Dumper::Dumper($struct);
    print "QS orig:   " . $qs . "\n";
    print "QS parsed: " . &to_qs($struct) . "\n";
    print "SQL: " . &to_sql($struct) . "\n";
}

sub to_qs {
    my $struct = shift;
    my $ret = '';
    my @items;

    my $filters = new Search::QS::Filters;

    while (my ($k,$v) = each %$struct) {
        given($k) {
			when (/^flt\[(.*?)\]/)   { $filters->push(&to_sql_flt($1, $v)) }
		}
    }

    print Data::Dumper::Dumper(\@$filters);
    return $filters->to_qs;
}

sub to_sql {
    my $struct = shift;
    my $ret = '';
    my @items;

    my $filters = new Search::QS::Filters;

    while (my ($k,$v) = each %$struct) {
        given($k) {
			when (/^flt\[(.*?)\]/)   { $filters->push(&to_sql_flt($1, $v)) }
		}
    }

    return $filters->to_sql;

}

sub to_sql_flt {
    my $kt  = shift;
    my $val = shift;

    my ($key, $tag) = split(/:/,$kt);

    my $fltObj = new Search::QS::Filter(name => $key, tag => $tag);
    $fltObj->parse($val);
    return $fltObj;
}
