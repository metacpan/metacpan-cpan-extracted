use Test::More tests => 20;

# Must test all examples in the documentation,
# so as to be sure we're not lying to the poor user.

sub begins_with
{
    my ($got, $exp) = @_;
    my $ok = substr($got,0,length $exp) eq $exp;
    if (!$ok)
    {
        diag "expected '$exp...'\n",
             "     got '$got'\n";
    }
    return $ok;
}

use_ok('Regexp::Common', 'time');

# Get day/month names in current locale
my ($November, $Thu);
eval
{
    require I18N::Langinfo;
    I18N::Langinfo->import(qw(langinfo MON_11 ABDAY_5));
    ($November, $Thu) = map langinfo($_), (MON_11(), ABDAY_5());
};
if ($@)
{
    ($November, $Thu) = qw(November Thu);
}



my ($record, $time);
my ($year, $month, $day, $h24, $h12, $min, $sec, $ampm);
my (@date_data, @time_data);
my $pass = 1;
my $str;
my $result;
my @result;

# Time::Format pattern example 1
$str = "$Thu $November 2, 2005";
eval {@result = $str =~ $RE{time}{tf}{-pat => 'Day Month d, yyyy'}{-keep}};
is ($@, q{}, 'Time::Format example 1, no error');
is_deeply (\@result, [$str, $Thu, $November, 2, 2005],
           'Time::Format example 1, expected values');

# Time::Format pattern example 2
eval {@result = $str =~ $RE{time}{tf}{-pat => '(Weekday|Day) (Month|Mon) d, yyyy'}{-keep}};
is ($@, q{}, 'Time::Format example 2, no error');
is_deeply (\@result, [$Thu, $November],
           'Time::Format example 2, expected values');


# strftime pattern example 1
$str = "$Thu $November 2, 2005";
@result = eval {$str =~ $RE{time}{strftime}{-pat => '%a %B %_d, %Y'}{-keep}};
is ($@, q{}, 'strftime example 1, no error');
is_deeply (\@result, [$str, $Thu, $November, 2, 2005],
           'strftime example 1, expected values');

# strftime pattern example 2
$str = "$Thu $November 2, 2005";
eval {@result = $str =~ $RE{time}{strftime}{-pat => '(%A|%a)? (%B|%b) ?%_d, %Y'}{-keep}};
is ($@, q{}, 'strftime example 2, no error');
is_deeply (\@result, [$Thu, $November],
           'strftime example 2, expected values');



# Typical usage: parsing a data record.
#
$rec = "blah blah 2005/10/21 blah blarrrrrgh";
@date = $rec =~ m{^blah blah $RE{time}{YMD}{-keep}};
ok (scalar @date, 'Fuzzy record parsing matched');
is_deeply (\@date, ['2005/10/21', 2005, 10, 21],
           'Fuzzy record parsing, expected results');

@date = $rec =~ m{^blah blah $RE{time}{tf}{-pat=>'yyyy/mm/dd'}{-keep}};
ok (scalar @date, 'TF record parsing matched');
is_deeply (\@date, ['2005/10/21', 2005, 10, 21],
           'TF record parsing, expected results');

@date = $rec =~ m{^blah blah $RE{time}{strftime}{-pat=>'%Y/%m/%d'}{-keep}};
ok (scalar @date, 'strftime record parsing matched');
is_deeply (\@date, ['2005/10/21', 2005, 10, 21],
           'strftime record parsing, expected results');


# Typical usage: parsing variable-format data.
#
eval
{
    require Time::Normalize;
    Time::Normalize->import();
};
my $dont_have_normalize = $@? 1 : 0;

SKIP:
{
    skip "Test relies on Time::Normalize, which you don't have", 3 if $dont_have_normalize;
    my $pass = 1;
    $record = "10-SEP-2005";

    if ( ((undef,$m,$d,$y) = $record =~ /^$RE{time}{mdy}{-keep}/)
     ||  ((undef,$d,$m,$y) = $record =~ /^$RE{time}{dmy}{-keep}/)
     ||  ((undef,$y,$m,$d) = $record =~ /^$RE{time}{ymd}{-keep}/) )
    {
        eval {($year, $month, $day) = normalize_ymd($y, $m, $d)};
    }
    else      # give up
    {
        $pass = undef;
    }
    is ($@, q{}, 'variable parse: no error');
    ok($pass, 'variable parse: matched');

    # $day is now 10; $month is now 09; $year is now 2005.
    is_deeply ([$day, $month, $year], [10, '09', 2005], 'variable parse: worked');
}

# Time examples
#
$time = '9:10pm';
@time_data = $time =~ /$RE{time}{hms}{-keep}/;
 # captures '9:10pm', '9', ':', '10', undef, 'pm'
is_deeply (\@time_data, ['9:10pm', '9', '10', undef, 'pm'], 'Time example 1');

@time_data = $time =~ /$RE{time}{tf}{-pat => '(h):(mm)(:ss)?(am)?'}{-keep}/;
 # captures '9', '10', undef, 'pm'
is_deeply (\@time_data, ['9', '10', undef, 'pm'], 'Time example 2');

