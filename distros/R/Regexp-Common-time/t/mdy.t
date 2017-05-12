use strict;
use vars qw(@match $num_tests %RE);

# Get day/month names in current locale
my ($Jan, $Feb, $Mar, $Apr, $May, $Jun, $Jul, $Aug, $Sep, $Oct, $Nov, $Dec);
my ($January, $February, $March, $April, $MayFull, $June, $July, $August, $September, $October, $November, $December);

BEGIN
{
    eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo MON_1 ABMON_1 MON_2 ABMON_2 MON_3 ABMON_3 MON_4 ABMON_4 MON_5 ABMON_5 MON_6 ABMON_6 MON_7 ABMON_7 MON_8 ABMON_8 MON_9 ABMON_9 MON_10 ABMON_10 MON_11 ABMON_11 MON_12 ABMON_12));
        ($Jan, $Feb, $Mar, $Apr, $May, $Jun, $Jul, $Aug, $Sep, $Oct, $Nov, $Dec)
            = map langinfo($_), (ABMON_1(), ABMON_2(), ABMON_3(), ABMON_4(), ABMON_5(), ABMON_6(), ABMON_7(), ABMON_8(), ABMON_9(), ABMON_10(), ABMON_11(), ABMON_12());
        ($January, $February, $March, $April, $MayFull, $June, $July, $August, $September, $October, $November, $December)
            = map langinfo($_), (MON_1(), MON_2(), MON_3(), MON_4(), MON_5(), MON_6(), MON_7(), MON_8(), MON_9(), MON_10(), MON_11(), MON_12());
    };
    if ($@)
    {
        ($Jan, $Feb, $Mar, $Apr, $May, $Jun, $Jul, $Aug, $Sep, $Oct, $Nov, $Dec)
            = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        ($January, $February, $March, $April, $MayFull, $June, $July, $August, $September, $October, $November, $December)
            = qw(January February March April May June July August September October November December);
    }

    @match = (
# mdy tests.
              ['10/19/2005', 'mdy', [], 1, [qw(10/19/2005 10 19 2005)]],
              ['10.19.2005', 'mdy', [], 1, [qw(10.19.2005 10 19 2005)]],
              ['10-19-2005', 'mdy', [], 1, [qw(10-19-2005 10 19 2005)]],
              ['10x19x2005', 'mdy', [], 0, ],
              ['10192005',   'mdy', [], 1, [qw(10192005   10 19 2005)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc10/19/2005xyz', 'mdy', [], 1, [qw(10/19/2005 10 19 2005)]],
              ['abc10.19.2005xyz', 'mdy', [], 1, [qw(10.19.2005 10 19 2005)]],
              ['abc10-19-2005xyz', 'mdy', [], 1, [qw(10-19-2005 10 19 2005)]],
              ['abc10x19x2005xyz', 'mdy', [], 0, ],
              ['abc10192005xyz',   'mdy', [], 1, [qw(10192005 10 19 2005)]],
              # However, leading digits cause loose m to fail, and trailing digits cause loose y to fail
              ['010/19/2005', 'mdy', [], 0, ],
              ['10/19/20050', 'mdy', [], 0, ],
              ['10/19/050',   'mdy', [], 0, ],
              # Mismatched or invalid separators
              ['10/19-2005', 'mdy', [], 0, ],
              ['10-19.2005', 'mdy', [], 0, ],
              ['10%19%2005', 'mdy', [], 0, ],
              # Two-year date should match mdy as well
              ['10/19/05', 'mdy', [], 1, [qw(10/19/05 10 19 05)]],
              ['10.19.05', 'mdy', [], 1, [qw(10.19.05 10 19 05)]],
              ['10-19-05', 'mdy', [], 1, [qw(10-19-05 10 19 05)]],
              ['10x19x05', 'mdy', [], 0, ],
              ['101905',   'mdy', [], 1, [qw(101905 10 19 05)]],
              # one-digit month
              ['1/19/2005', 'mdy', [], 1, [qw(1/19/2005 1 19 2005)]],
              ['1.19.2005', 'mdy', [], 1, [qw(1.19.2005 1 19 2005)]],
              ['1-19-2005', 'mdy', [], 1, [qw(1-19-2005 1 19 2005)]],
              ['1x19x2005', 'mdy', [], 0, ],
              ['1192005',   'mdy', [], 0, ],
              # one-digit day
              ['10/9/2005', 'mdy', [], 1, [qw(10/9/2005 10 9 2005)]],
              ['10.9.2005', 'mdy', [], 1, [qw(10.9.2005 10 9 2005)]],
              ['10-9-2005', 'mdy', [], 1, [qw(10-9-2005 10 9 2005)]],
              ['10x9x2005', 'mdy', [], 0, ],
              ['1092005',   'mdy', [], 0, ],
              # one-digit month and day
              ['1/9/2005', 'mdy', [], 1, [qw(1/9/2005 1 9 2005)]],
              ['1.9.2005', 'mdy', [], 1, [qw(1.9.2005 1 9 2005)]],
              ['1-9-2005', 'mdy', [], 1, [qw(1-9-2005 1 9 2005)]],
              ['1x9x2005', 'mdy', [], 0, ],
              ['192005',   'mdy', [], 0, ],
              # m/dd/yy
              ['1/19/05', 'mdy', [], 1, [qw(1/19/05 1 19 05)]],
              ['1.19.05', 'mdy', [], 1, [qw(1.19.05 1 19 05)]],
              ['1-19-05', 'mdy', [], 1, [qw(1-19-05 1 19 05)]],
              ['1x19x05', 'mdy', [], 0, ],
              ['11905',   'mdy', [], 0, ],
              # mm/d/yy
              ['10/9/05', 'mdy', [], 1, [qw(10/9/05 10 9 05)]],
              ['10.9.05', 'mdy', [], 1, [qw(10.9.05 10 9 05)]],
              ['10-9-05', 'mdy', [], 1, [qw(10-9-05 10 9 05)]],
              ['10x9x05', 'mdy', [], 0, ],
              ['10905',   'mdy', [], 0, ],
              # m/d/yy
              ['1/9/05', 'mdy', [], 1, [qw(1/9/05 1 9 05)]],
              ['1.9.05', 'mdy', [], 1, [qw(1.9.05 1 9 05)]],
              ['1-9-05', 'mdy', [], 1, [qw(1-9-05 1 9 05)]],
              ['1x9x05', 'mdy', [], 0, ],
              ['1905',   'mdy', [], 0, ],
              # Invalid month
              ['13/19/2005', 'mdy', [], 0, ],
              ['21/19/2005', 'mdy', [], 0, ],
              ['0/19/2005',  'mdy', [], 0, ],
              ['00/19/2005', 'mdy', [], 0, ],
              # Invalid day
              ['12/0/2005', 'mdy',  [], 0, ],
              ['12/00/2005', 'mdy', [], 0, ],
              ['12/40/2005', 'mdy', [], 0, ],
              ['12/32/2005', 'mdy', [], 0, ],

# mdy4 tests.  Mostly the same as above.
              ['10/19/2005', 'mdy4', [], 1, [qw(10/19/2005 10 19 2005)]],
              ['10.19.2005', 'mdy4', [], 1, [qw(10.19.2005 10 19 2005)]],
              ['10-19-2005', 'mdy4', [], 1, [qw(10-19-2005 10 19 2005)]],
              ['10x19x2005', 'mdy4', [], 0, ],
              ['10192005',   'mdy4', [], 1, [qw(10192005 10 19 2005)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc10/19/2005000', 'mdy4', [], 1, [qw(10/19/2005 10 19 2005)]],
              ['abc10.19.2005000', 'mdy4', [], 1, [qw(10.19.2005 10 19 2005)]],
              ['abc10-19-2005xyz', 'mdy4', [], 1, [qw(10-19-2005 10 19 2005)]],
              ['abc10x19x2005xyz', 'mdy4', [], 0, ],
              ['abc10192005000',   'mdy4', [], 1, [qw(10192005 10 19 2005)]],
              # However, leading digits cause loose m to fail
              ['010/19/2005', 'mdy4', [], 0, ],
              # Mismatched or invalid separators
              ['10/19-2005', 'mdy4', [], 0, ],
              ['10-19.2005', 'mdy4', [], 0, ],
              ['10%19%2005', 'mdy4', [], 0, ],
              # Two-year date should not match mdy4
              ['10/19/05', 'mdy4', [], 0, ],
              ['10.19.05', 'mdy4', [], 0, ],
              ['10-19-05', 'mdy4', [], 0, ],
              ['10x19x05', 'mdy4', [], 0, ],
              ['101905',   'mdy4', [], 0, ],
              # one-digit month
              ['1/19/2005', 'mdy4', [], 1, [qw(1/19/2005 1 19 2005)]],
              ['1.19.2005', 'mdy4', [], 1, [qw(1.19.2005 1 19 2005)]],
              ['1-19-2005', 'mdy4', [], 1, [qw(1-19-2005 1 19 2005)]],
              ['1x19x2005', 'mdy4', [], 0, ],
              ['1192005',   'mdy4', [], 0, ],
              # one-digit day
              ['10/9/2005', 'mdy4', [], 1, [qw(10/9/2005 10 9 2005)]],
              ['10.9.2005', 'mdy4', [], 1, [qw(10.9.2005 10 9 2005)]],
              ['10-9-2005', 'mdy4', [], 1, [qw(10-9-2005 10 9 2005)]],
              ['10x9x2005', 'mdy4', [], 0, ],
              ['1092005',   'mdy4', [], 0, ],
              # one-digit month and day
              ['1/9/2005', 'mdy4', [], 1, [qw(1/9/2005 1 9 2005)]],
              ['1.9.2005', 'mdy4', [], 1, [qw(1.9.2005 1 9 2005)]],
              ['1-9-2005', 'mdy4', [], 1, [qw(1-9-2005 1 9 2005)]],
              ['1x9x2005', 'mdy4', [], 0, ],
              ['192005',   'mdy4', [], 0, ],
              # m/dd/yy
              ['1/19/05', 'mdy4', [], 0, ],
              ['1.19.05', 'mdy4', [], 0, ],
              ['1-19-05', 'mdy4', [], 0, ],
              ['1x19x05', 'mdy4', [], 0, ],
              ['11905',   'mdy4', [], 0, ],
              ['11905',   'mdy4', [], 0, ],
              # mm/d/yy
              ['10/9/05', 'mdy4', [], 0, ],
              ['10.9.05', 'mdy4', [], 0, ],
              ['10-9-05', 'mdy4', [], 0, ],
              ['10x9x05', 'mdy4', [], 0, ],
              ['10905',   'mdy4', [], 0, ],
              # m/d/yy
              ['1/9/05', 'mdy4', [], 0, ],
              ['1.9.05', 'mdy4', [], 0, ],
              ['1-9-05', 'mdy4', [], 0, ],
              ['1x9x05', 'mdy4', [], 0, ],
              ['1905',   'mdy4', [], 0, ],
              # Invalid month
              ['13/19/2005', 'mdy4', [], 0, ],
              ['21/19/2005', 'mdy4', [], 0, ],
              ['0/19/2005',  'mdy4', [], 0, ],
              ['00/19/2005', 'mdy4', [], 0, ],
              # Invalid day
              ['12/0/2005', 'mdy4',  [], 0, ],
              ['12/00/2005', 'mdy4', [], 0, ],
              ['12/40/2005', 'mdy4', [], 0, ],
              ['12/32/2005', 'mdy4', [], 0, ],

# mdy2 tests
              ['10/19/2005', 'mdy2', [], 1, [qw(10/19/20 10 19 20)]],
              ['10.19.2005', 'mdy2', [], 1, [qw(10.19.20 10 19 20)]],
              ['10-19-2005', 'mdy2', [], 1, [qw(10-19-20 10 19 20)]],
              ['10x19x2005', 'mdy2', [], 0, ],
              ['10192005',   'mdy2', [], 1, [qw(101920 10 19 20)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc10/19/2005000', 'mdy2', [], 1, [qw(10/19/20 10 19 20)]],
              ['abc10.19.2005000', 'mdy2', [], 1, [qw(10.19.20 10 19 20)]],
              ['abc10-19-20vwxyz', 'mdy2', [], 1, [qw(10-19-20 10 19 20)]],
              ['abc10x19x20vwxyz', 'mdy2', [], 0, ],
              ['abc10192005000',   'mdy2', [], 1, [qw(101920 10 19 20)]],
              # However, leading digits cause loose m to fail
              ['910/19/2005000', 'mdy2', [], 0, ],
              # Mismatched or invalid separators
              ['10/19-05', 'mdy2', [], 0, ],
              ['10-19.05', 'mdy2', [], 0, ],
              ['10%19%05', 'mdy2', [], 0, ],
              # Two-year date should match
              ['10/19/05', 'mdy2', [], 1, [qw(10/19/05 10 19 05)]],
              ['10.19.05', 'mdy2', [], 1, [qw(10.19.05 10 19 05)]],
              ['10-19-05', 'mdy2', [], 1, [qw(10-19-05 10 19 05)]],
              ['10x19x05', 'mdy2', [], 0, ],
              ['101905',   'mdy2', [], 1, [qw(101905 10 19 05)]],
              # one-digit month
              ['1/19/2005', 'mdy2', [], 1, [qw(1/19/20 1 19 20)]],
              ['1.19.2005', 'mdy2', [], 1, [qw(1.19.20 1 19 20)]],
              ['1-19-2005', 'mdy2', [], 1, [qw(1-19-20 1 19 20)]],
              ['1x19x2005', 'mdy2', [], 0, ],
              ['1192005',   'mdy2', [], 0, ],
              # one-digit day
              ['10/9/2005', 'mdy2', [], 1, [qw(10/9/20 10 9 20)]],
              ['10.9.2005', 'mdy2', [], 1, [qw(10.9.20 10 9 20)]],
              ['10-9-2005', 'mdy2', [], 1, [qw(10-9-20 10 9 20)]],
              ['10x9x2005', 'mdy2', [], 0, ],
              ['1092005',   'mdy2', [], 0, ],
              # one-digit month and day
              ['1/9/2005', 'mdy2', [], 1, [qw(1/9/20 1 9 20)]],
              ['1.9.2005', 'mdy2', [], 1, [qw(1.9.20 1 9 20)]],
              ['1-9-2005', 'mdy2', [], 1, [qw(1-9-20 1 9 20)]],
              ['1x9x2005', 'mdy2', [], 0, ],
              ['192005',   'mdy2', [], 0, ],
              # m/dd/yy
              ['1/19/05', 'mdy2', [], 1, [qw(1/19/05 1 19 05)]],
              ['1.19.05', 'mdy2', [], 1, [qw(1.19.05 1 19 05)]],
              ['1-19-05', 'mdy2', [], 1, [qw(1-19-05 1 19 05)]],
              ['1x19x05', 'mdy2', [], 0, ],
              ['11905',   'mdy2', [], 0, ],
              # mm/d/yy
              ['10/9/05', 'mdy2', [], 1, [qw(10/9/05 10 9 05)]],
              ['10.9.05', 'mdy2', [], 1, [qw(10.9.05 10 9 05)]],
              ['10-9-05', 'mdy2', [], 1, [qw(10-9-05 10 9 05)]],
              ['10x9x05', 'mdy2', [], 0, ],
              ['10905',   'mdy2', [], 0, ],
              # m/d/yy
              ['1/9/05', 'mdy2', [], 1, [qw(1/9/05 1 9 05)]],
              ['1.9.05', 'mdy2', [], 1, [qw(1.9.05 1 9 05)]],
              ['1-9-05', 'mdy2', [], 1, [qw(1-9-05 1 9 05)]],
              ['1x9x05', 'mdy2', [], 0, ],
              ['1905',   'mdy2', [], 0, ],
              # Invalid month
              ['13/19/05', 'mdy2', [], 0, ],
              ['21/19/05', 'mdy2', [], 0, ],
              ['0/19/05',  'mdy2', [], 0, ],
              ['00/19/05', 'mdy2', [], 0, ],
              # Invalid day
              ['12/0/05',  'mdy2', [], 0, ],
              ['12/00/05', 'mdy2', [], 0, ],
              ['12/40/05', 'mdy2', [], 0, ],
              ['12/32/05', 'mdy2', [], 0, ],

# m2d2y4 tests
              ['10/19/2005', 'm2d2y4', [], 1, [qw(10/19/2005 10 19 2005)]],
              ['10.19.2005', 'm2d2y4', [], 1, [qw(10.19.2005 10 19 2005)]],
              ['10-19-2005', 'm2d2y4', [], 1, [qw(10-19-2005 10 19 2005)]],
              ['10x19x2005', 'm2d2y4', [], 0, ],
              ['10192005',   'm2d2y4', [], 1, [qw(10192005 10 19 2005)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc10/19/2005000', 'm2d2y4', [], 1, [qw(10/19/2005 10 19 2005)]],
              ['abc10.19.2005000', 'm2d2y4', [], 1, [qw(10.19.2005 10 19 2005)]],
              ['00010-19-2005000', 'm2d2y4', [], 1, [qw(10-19-2005 10 19 2005)]],
              ['abc10x19x2005000', 'm2d2y4', [], 0, ],
              ['10192005000',   'm2d2y4', [], 1, [qw(10192005 10 19 2005)]],
              # Mismatched or invalid separators
              ['10/19-2005', 'm2d2y4', [], 0, ],
              ['10-19.2005', 'm2d2y4', [], 0, ],
              ['10%19%2005', 'm2d2y4', [], 0, ],
              # Two-year date should not match
              ['10/19/05', 'm2d2y4', [], 0, ],
              ['10.19.05', 'm2d2y4', [], 0, ],
              ['10-19-05', 'm2d2y4', [], 0, ],
              ['10x19x05', 'm2d2y4', [], 0, ],
              ['101905',   'm2d2y4', [], 0, ],
              # one-digit month
              ['1/19/2005', 'm2d2y4', [], 0, ],
              ['1.19.2005', 'm2d2y4', [], 0, ],
              ['1-19-2005', 'm2d2y4', [], 0, ],
              ['1x19x2005', 'm2d2y4', [], 0, ],
              ['1192005',   'm2d2y4', [], 0, ],
              # one-digit day
              ['10/9/2005', 'm2d2y4', [], 0, ],
              ['10.9.2005', 'm2d2y4', [], 0, ],
              ['10-9-2005', 'm2d2y4', [], 0, ],
              ['10x9x2005', 'm2d2y4', [], 0, ],
              ['1092005',   'm2d2y4', [], 0, ],
              # one-digit month and day
              ['1/9/2005', 'm2d2y4', [], 0, ],
              ['1.9.2005', 'm2d2y4', [], 0, ],
              ['1-9-2005', 'm2d2y4', [], 0, ],
              ['1x9x2005', 'm2d2y4', [], 0, ],
              ['192005',   'm2d2y4', [], 0, ],
              # m/dd/yy
              ['1/19/05', 'm2d2y4', [], 0, ],
              ['1.19.05', 'm2d2y4', [], 0, ],
              ['1-19-05', 'm2d2y4', [], 0, ],
              ['1x19x05', 'm2d2y4', [], 0, ],
              ['11905',   'm2d2y4', [], 0, ],
              # mm/d/yy
              ['10/9/05', 'm2d2y4', [], 0, ],
              ['10.9.05', 'm2d2y4', [], 0, ],
              ['10-9-05', 'm2d2y4', [], 0, ],
              ['10x9x05', 'm2d2y4', [], 0, ],
              ['10905',   'm2d2y4', [], 0, ],
              # m/d/yy
              ['1/9/05', 'm2d2y4', [], 0, ],
              ['1.9.05', 'm2d2y4', [], 0, ],
              ['1-9-05', 'm2d2y4', [], 0, ],
              ['1x9x05', 'm2d2y4', [], 0, ],
              ['1905',   'm2d2y4', [], 0, ],
              # Invalid month
              ['13/19/2005', 'm2d2y4', [], 0, ],
              ['21/19/2005', 'm2d2y4', [], 0, ],
              ['0/19/2005',  'm2d2y4', [], 0, ],
              ['00/19/2005', 'm2d2y4', [], 0, ],
              # Invalid day
              ['12/0/2005',  'm2d2y4', [], 0, ],
              ['12/00/2005', 'm2d2y4', [], 0, ],
              ['12/40/2005', 'm2d2y4', [], 0, ],
              ['12/32/2005', 'm2d2y4', [], 0, ],

# m2d2y2 tests
              ['10/19/2005', 'm2d2y2', [], 1, [qw(10/19/20 10 19 20)]],
              ['10.19.2005', 'm2d2y2', [], 1, [qw(10.19.20 10 19 20)]],
              ['10-19-2005', 'm2d2y2', [], 1, [qw(10-19-20 10 19 20)]],
              ['10x19x2005', 'm2d2y2', [], 0, ],
              ['10192005',   'm2d2y2', [], 1, [qw(101920 10 19 20)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc10/19/2005000', 'm2d2y2', [], 1, [qw(10/19/20 10 19 20)]],
              ['abc10.19.2005000', 'm2d2y2', [], 1, [qw(10.19.20 10 19 20)]],
              ['00010-19-2005000', 'm2d2y2', [], 1, [qw(10-19-20 10 19 20)]],
              ['abc10x19x2005000', 'm2d2y2', [], 0, ],
              ['abc10192005000',   'm2d2y2', [], 1, [qw(101920 10 19 20)]],
              # Mismatched or invalid separators
              ['10/19-05', 'm2d2y2', [], 0, ],
              ['10-19.05', 'm2d2y2', [], 0, ],
              ['10%19%05', 'm2d2y2', [], 0, ],
              # Two-year date should match
              ['10/19/05', 'm2d2y2', [], 1, [qw(10/19/05 10 19 05)]],
              ['10.19.05', 'm2d2y2', [], 1, [qw(10.19.05 10 19 05)]],
              ['10-19-05', 'm2d2y2', [], 1, [qw(10-19-05 10 19 05)]],
              ['10x19x05', 'm2d2y2', [], 0, ],
              ['101905',   'm2d2y2', [], 1, [qw(101905 10 19 05)]],
              # one-digit month
              ['1/19/2005', 'm2d2y2', [], 0, ],
              ['1.19.2005', 'm2d2y2', [], 0, ],
              ['1-19-2005', 'm2d2y2', [], 0, ],
              ['1x19x2005', 'm2d2y2', [], 0, ],
              ['1192005',   'm2d2y2', [], 0, ],
              # one-digit day
              ['10/9/2005', 'm2d2y2', [], 0, ],
              ['10.9.2005', 'm2d2y2', [], 0, ],
              ['10-9-2005', 'm2d2y2', [], 0, ],
              ['10x9x2005', 'm2d2y2', [], 0, ],
              ['1092005',   'm2d2y2', [], 1, [qw(092005 09 20 05)]],
              # one-digit month and day
              ['1/9/2005', 'm2d2y2', [], 0, ],
              ['1.9.2005', 'm2d2y2', [], 0, ],
              ['1-9-2005', 'm2d2y2', [], 0, ],
              ['1x9x2005', 'm2d2y2', [], 0, ],
              ['192005',   'm2d2y2', [], 0, ],
              # m/dd/yy
              ['1/19/05', 'm2d2y2', [], 0, ],
              ['1.19.05', 'm2d2y2', [], 0, ],
              ['1-19-05', 'm2d2y2', [], 0, ],
              ['1x19x05', 'm2d2y2', [], 0, ],
              ['11905',   'm2d2y2', [], 0, ],
              # mm/d/yy
              ['10/9/05', 'm2d2y2', [], 0, ],
              ['10.9.05', 'm2d2y2', [], 0, ],
              ['10-9-05', 'm2d2y2', [], 0, ],
              ['10x9x05', 'm2d2y2', [], 0, ],
              ['10905',   'm2d2y2', [], 0, ],
              # m/d/yy
              ['1/9/05', 'm2d2y2', [], 0, ],
              ['1.9.05', 'm2d2y2', [], 0, ],
              ['1-9-05', 'm2d2y2', [], 0, ],
              ['1x9x05', 'm2d2y2', [], 0, ],
              ['1905',   'm2d2y2', [], 0, ],
              # Invalid month
              ['13/19/05', 'm2d2y2', [], 0, ],
              ['21/19/05', 'm2d2y2', [], 0, ],
              ['0/19/05',  'm2d2y2', [], 0, ],
              ['00/19/05', 'm2d2y2', [], 0, ],
              # Invalid day
              ['12/0/05',  'm2d2y2', [], 0, ],
              ['12/00/05', 'm2d2y2', [], 0, ],
              ['12/40/05', 'm2d2y2', [], 0, ],
              ['12/32/05', 'm2d2y2', [], 0, ],

# mdy tests with named month.
              # Basic test case
              ["$Jan 01, 2005",       "mdy", [], 1, ["$Jan 01, 2005",      $Jan, qw( 01 2005)]],
              # 2-digit year
              ["$Jan 01, 05",         "mdy", [], 1, ["$Jan 01, 05",        $Jan, qw( 01 05)]],
              # No separator
              ["${Jan}012005",        "mdy", [], 1, ["${Jan}012005",       $Jan, qw( 01 2005)]],
              ["${Jan}0105",          "mdy", [], 1, ["${Jan}0105",         $Jan, qw( 01 05)]],
              # odd number of digits in year
              [   "$Jan 01, 9",       "mdy", [], 0, ],
              [ "$Jan 01, 120",       "mdy", [], 0, ],
              ["$Jan 01, 90120",      "mdy", [], 0, ],
              # Name spelled out
              ["$January 01, 2005",   "mdy", [], 1, ["$January 01, 2005",  $January, qw( 01 2005)]],
              # Partial name should fail
              ["${Jan}u 01, 2005",    "mdy", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["$February 1, 2005",   "mdy", [], 1, ["$February 1, 2005",   $February, qw(   1 2005)]],
              ["$March 2, 2005",      "mdy", [], 1, ["$March 2, 2005",      $March, qw(      2 2005)]],
              ["$April 09, 2005",     "mdy", [], 1, ["$April 09, 2005",     $April, qw(     09 2005)]],
              ["$MayFull 9, 2005",    "mdy", [], 1, ["$MayFull 9, 2005",    "$MayFull", qw(        9 2005)]],
              ["$June 10, 2005",      "mdy", [], 1, ["$June 10, 2005",      $June, qw(      10 2005)]],
              ["$July 11, 2005",      "mdy", [], 1, ["$July 11, 2005",      $July, qw(      11 2005)]],
              ["$August 19, 2005",    "mdy", [], 1, ["$August 19, 2005",    $August, qw(    19 2005)]],
              ["$September 20, 2005", "mdy", [], 1, ["$September 20, 2005", $September, qw( 20 2005)]],
              ["$October 21, 2005",   "mdy", [], 1, ["$October 21, 2005",   $October, qw(   21 2005)]],
              ["$November 30, 2005",  "mdy", [], 1, ["$November 30, 2005",  $November, qw(  30 2005)]],
              ["$December 31, 2005",  "mdy", [], 1, ["$December 31, 2005",  $December, qw(  31 2005)]],
              ["$Feb 1, 2005",        "mdy", [], 1, ["$Feb 1, 2005",        $Feb, qw(  1 2005)]],
              ["$Mar 2, 2005",        "mdy", [], 1, ["$Mar 2, 2005",        $Mar, qw(  2 2005)]],
              ["$Apr 09, 2005",       "mdy", [], 1, ["$Apr 09, 2005",       $Apr, qw( 09 2005)]],
              ["$May 9, 2005",        "mdy", [], 1, ["$May 9, 2005",        $May, qw(  9 2005)]],
              ["$Jun 10, 2005",       "mdy", [], 1, ["$Jun 10, 2005",       $Jun, qw( 10 2005)]],
              ["$Jul 11, 2005",       "mdy", [], 1, ["$Jul 11, 2005",       $Jul, qw( 11 2005)]],
              ["$Aug 19, 2005",       "mdy", [], 1, ["$Aug 19, 2005",       $Aug, qw( 19 2005)]],
              ["$Sep 20, 2005",       "mdy", [], 1, ["$Sep 20, 2005",       $Sep, qw( 20 2005)]],
              ["$Oct 21, 2005",       "mdy", [], 1, ["$Oct 21, 2005",       $Oct, qw( 21 2005)]],
              ["$Nov 30, 2005",       "mdy", [], 1, ["$Nov 30, 2005",       $Nov, qw( 30 2005)]],
              ["$Dec 31, 2005",       "mdy", [], 1, ["$Dec 31, 2005",       $Dec, qw( 31 2005)]],
              # Case insensitivity
              ["\L$Jan 01, 2005",     "mdy", [], 1, ["\L$Jan 01, 2005",     "\L$Jan", qw( 01 2005)]],
              ["\U\l$Jan 01, 2005",   "mdy", [], 1, ["\U\l$Jan 01, 2005",   "\U\l$Jan", qw( 01 2005)]],
              # Alternate separators
              ["$Jan 01 ,2005",       "mdy", [], 0, ],
              ["$Jan 01 2005",        "mdy", [], 1, ["$Jan 01 2005",        $Jan, qw( 01 2005)]],
              ["$Jan-01-2005",        "mdy", [], 1, ["$Jan-01-2005",        $Jan, qw( 01 2005)]],
              # Mismatched or invalid separators
              ["$Jan/19-2005",        "mdy", [], 0, ],
              ["$Jan-19.2005",        "mdy", [], 0, ],
              ["$Jan%19%2005",        "mdy", [], 0, ],
              ["$Jan-01,-2005",       "mdy", [], 0, ],
              ["$Jan:01,:2005",       "mdy", [], 0, ],
              # Schmutz before/after the date
              ["blah$Jan 01, 2005",   "mdy", [], 1, ["$Jan 01, 2005",       $Jan, qw( 01 2005)]],
              ["$Jan 01, 2005blah",   "mdy", [], 1, ["$Jan 01, 2005",       $Jan, qw( 01 2005)]],
              # Bad day
              ["$Jan 00, 2005",       "mdy", [], 0, ],
              ["$Jan 0, 2005",        "mdy", [], 0, ],
              ["$Jan 32, 2005",       "mdy", [], 0, ],
              ["$Jan 40, 2005",       "mdy", [], 0, ],
              ["$Jan 99, 2005",       "mdy", [], 0, ],

# mdy4 tests with named month.
              # Basic test case
              ["$Jan 01, 2005",       "mdy4", [], 1, ["$Jan 01, 2005",      $Jan, qw( 01 2005)]],
              # 2-digit year
              ["$Jan 01, 05",         "mdy4", [], 0, ],
              # No separator
              ["${Jan}012005",        "mdy4", [], 1, ["${Jan}012005",       $Jan, qw( 01 2005)]],
              ["${Jan}0105",          "mdy4", [], 0, ],
              # odd number of digits in year
              [   "$Jan 01, 9",       "mdy4", [], 0, ],
              [ "$Jan 01, 120",       "mdy4", [], 0, ],
              ["$Jan 01, 90120",      "mdy4", [], 1, ["$Jan 01, 9012",      $Jan, qw( 01 9012)]],
              # Name spelled out
              ["$January 01, 2005",   "mdy4", [], 1, ["$January 01, 2005",  $January, qw( 01 2005)]],
              # Partial name should fail
              ["${Jan}u 01, 2005",    "mdy4", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["$February 1, 2005",   "mdy4", [], 1, ["$February 1, 2005",   $February, qw(   1 2005)]],
              ["$March 2, 2005",      "mdy4", [], 1, ["$March 2, 2005",      $March, qw(      2 2005)]],
              ["$April 09, 2005",     "mdy4", [], 1, ["$April 09, 2005",     $April, qw(     09 2005)]],
              ["$MayFull 9, 2005",    "mdy4", [], 1, ["$MayFull 9, 2005",    "$MayFull", qw(        9 2005)]],
              ["$June 10, 2005",      "mdy4", [], 1, ["$June 10, 2005",      $June, qw(      10 2005)]],
              ["$July 11, 2005",      "mdy4", [], 1, ["$July 11, 2005",      $July, qw(      11 2005)]],
              ["$August 19, 2005",    "mdy4", [], 1, ["$August 19, 2005",    $August, qw(    19 2005)]],
              ["$September 20, 2005", "mdy4", [], 1, ["$September 20, 2005", $September, qw( 20 2005)]],
              ["$October 21, 2005",   "mdy4", [], 1, ["$October 21, 2005",   $October, qw(   21 2005)]],
              ["$November 30, 2005",  "mdy4", [], 1, ["$November 30, 2005",  $November, qw(  30 2005)]],
              ["$December 31, 2005",  "mdy4", [], 1, ["$December 31, 2005",  $December, qw(  31 2005)]],
              ["$Feb 1, 2005",        "mdy4", [], 1, ["$Feb 1, 2005",        $Feb, qw(  1 2005)]],
              ["$Mar 2, 2005",        "mdy4", [], 1, ["$Mar 2, 2005",        $Mar, qw(  2 2005)]],
              ["$Apr 09, 2005",       "mdy4", [], 1, ["$Apr 09, 2005",       $Apr, qw( 09 2005)]],
              ["$May 9, 2005",        "mdy4", [], 1, ["$May 9, 2005",        $May, qw(  9 2005)]],
              ["$Jun 10, 2005",       "mdy4", [], 1, ["$Jun 10, 2005",       $Jun, qw( 10 2005)]],
              ["$Jul 11, 2005",       "mdy4", [], 1, ["$Jul 11, 2005",       $Jul, qw( 11 2005)]],
              ["$Aug 19, 2005",       "mdy4", [], 1, ["$Aug 19, 2005",       $Aug, qw( 19 2005)]],
              ["$Sep 20, 2005",       "mdy4", [], 1, ["$Sep 20, 2005",       $Sep, qw( 20 2005)]],
              ["$Oct 21, 2005",       "mdy4", [], 1, ["$Oct 21, 2005",       $Oct, qw( 21 2005)]],
              ["$Nov 30, 2005",       "mdy4", [], 1, ["$Nov 30, 2005",       $Nov, qw( 30 2005)]],
              ["$Dec 31, 2005",       "mdy4", [], 1, ["$Dec 31, 2005",       $Dec, qw( 31 2005)]],
              # Case insensitivity
              ["\L$Jan 01, 2005",     "mdy4", [], 1, ["\L$Jan 01, 2005",     "\L$Jan", qw( 01 2005)]],
              ["\U\l$Jan 01, 2005",   "mdy4", [], 1, ["\U\l$Jan 01, 2005",   "\U\l$Jan", qw( 01 2005)]],
              # Alternate separators
              ["$Jan 01 ,2005",       "mdy4", [], 0, ],
              ["$Jan 01 2005",        "mdy4", [], 1, ["$Jan 01 2005",        $Jan, qw( 01 2005)]],
              ["$Jan-01-2005",        "mdy4", [], 1, ["$Jan-01-2005",        $Jan, qw( 01 2005)]],
              # Mismatched or invalid separators
              ["$Jan/19-2005",        "mdy4", [], 0, ],
              ["$Jan-19.2005",        "mdy4", [], 0, ],
              ["$Jan%19%2005",        "mdy4", [], 0, ],
              ["$Jan-01,-2005",       "mdy4", [], 0, ],
              ["$Jan:01,:2005",       "mdy4", [], 0, ],
              # Schmutz before/after the date
              ["blah$Jan 01, 2005",   "mdy4", [], 1, ["$Jan 01, 2005",       $Jan, qw( 01 2005)]],
              ["$Jan 01, 2005blah",   "mdy4", [], 1, ["$Jan 01, 2005",       $Jan, qw( 01 2005)]],
              # Bad day
              ["$Jan 00, 2005",       "mdy4", [], 0, ],
              ["$Jan 0, 2005",        "mdy4", [], 0, ],
              ["$Jan 32, 2005",       "mdy4", [], 0, ],
              ["$Jan 40, 2005",       "mdy4", [], 0, ],
              ["$Jan 99, 2005",       "mdy4", [], 0, ],

# mdy2 tests with named month.
              # Basic test case
              ["$Jan 01, 2005",       "mdy2", [], 1, ["$Jan 01, 20",      $Jan, qw( 01 20)]],
              # 2-digit year
              ["$Jan 01, 05",         "mdy2", [], 1, ["$Jan 01, 05",      $Jan, qw( 01 05)]],
              # No separator
              ["${Jan}012005",        "mdy2", [], 1, ["${Jan}0120",        $Jan, qw( 01 20)]],
              ["${Jan}0105",          "mdy2", [], 1, ["${Jan}0105",          $Jan, qw( 01 05)]],
              # odd number of digits in year
              [   "$Jan 01, 9",       "mdy2", [], 0, ],
              [ "$Jan 01, 120",       "mdy2", [], 1, ["$Jan 01, 12",        $Jan, qw( 01 12)]],
              # Name spelled out
              ["$January 01, 2005",   "mdy2", [], 1, ["$January 01, 20",    $January, qw( 01 20)]],
              # Partial name should fail
              ["${Jan}u 01, 2005",    "mdy2", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["$February 1, 05",   "mdy2", [], 1, ["$February 1, 05",   $February, qw(   1 05)]],
              ["$March 2, 05",      "mdy2", [], 1, ["$March 2, 05",      $March, qw(      2 05)]],
              ["$April 09, 05",     "mdy2", [], 1, ["$April 09, 05",     $April, qw(     09 05)]],
              ["$MayFull 9, 05",    "mdy2", [], 1, ["$MayFull 9, 05",    "$MayFull", qw(        9 05)]],
              ["$June 10, 05",      "mdy2", [], 1, ["$June 10, 05",      $June, qw(      10 05)]],
              ["$July 11, 05",      "mdy2", [], 1, ["$July 11, 05",      $July, qw(      11 05)]],
              ["$August 19, 05",    "mdy2", [], 1, ["$August 19, 05",    $August, qw(    19 05)]],
              ["$September 20, 05", "mdy2", [], 1, ["$September 20, 05", $September, qw( 20 05)]],
              ["$October 21, 05",   "mdy2", [], 1, ["$October 21, 05",   $October, qw(   21 05)]],
              ["$November 30, 05",  "mdy2", [], 1, ["$November 30, 05",  $November, qw(  30 05)]],
              ["$December 31, 05",  "mdy2", [], 1, ["$December 31, 05",  $December, qw(  31 05)]],
              ["$Feb 1, 05",        "mdy2", [], 1, ["$Feb 1, 05",        $Feb, qw(  1 05)]],
              ["$Mar 2, 05",        "mdy2", [], 1, ["$Mar 2, 05",        $Mar, qw(  2 05)]],
              ["$Apr 09, 05",       "mdy2", [], 1, ["$Apr 09, 05",       $Apr, qw( 09 05)]],
              ["$May 9, 05",        "mdy2", [], 1, ["$May 9, 05",        $May, qw(  9 05)]],
              ["$Jun 10, 05",       "mdy2", [], 1, ["$Jun 10, 05",       $Jun, qw( 10 05)]],
              ["$Jul 11, 05",       "mdy2", [], 1, ["$Jul 11, 05",       $Jul, qw( 11 05)]],
              ["$Aug 19, 05",       "mdy2", [], 1, ["$Aug 19, 05",       $Aug, qw( 19 05)]],
              ["$Sep 20, 05",       "mdy2", [], 1, ["$Sep 20, 05",       $Sep, qw( 20 05)]],
              ["$Oct 21, 05",       "mdy2", [], 1, ["$Oct 21, 05",       $Oct, qw( 21 05)]],
              ["$Nov 30, 05",       "mdy2", [], 1, ["$Nov 30, 05",       $Nov, qw( 30 05)]],
              ["$Dec 31, 05",       "mdy2", [], 1, ["$Dec 31, 05",       $Dec, qw( 31 05)]],
              # Case insensitivity
              ["\L$Jan 01, 05",     "mdy2", [], 1, ["\L$Jan 01, 05",     "\L$Jan", qw( 01 05)]],
              ["\U\l$Jan 01, 05",   "mdy2", [], 1, ["\U\l$Jan 01, 05",   "\U\l$Jan", qw( 01 05)]],
              # Alternate separators
              ["$Jan 01 ,05",       "mdy2", [], 0, ],
              ["$Jan 01 05",        "mdy2", [], 1, ["$Jan 01 05",        $Jan, qw( 01 05)]],
              ["$Jan-01-05",        "mdy2", [], 1, ["$Jan-01-05",        $Jan, qw( 01 05)]],
              # Mismatched or invalid separators
              ["$Jan/19-05",        "mdy2", [], 0, ],
              ["$Jan-19.05",        "mdy2", [], 0, ],
              ["$Jan%19%05",        "mdy2", [], 0, ],
              ["$Jan-01,-05",       "mdy2", [], 0, ],
              ["$Jan:01,:05",       "mdy2", [], 0, ],
              # Schmutz before/after the date
              ["blah$Jan 01, 05",   "mdy2", [], 1, ["$Jan 01, 05",       $Jan, qw( 01 05)]],
              ["$Jan 01, 05blah",   "mdy2", [], 1, ["$Jan 01, 05",       $Jan, qw( 01 05)]],
              # Bad day
              ["$Jan 00, 05",       "mdy2", [], 0, ],
              ["$Jan 0, 05",        "mdy2", [], 0, ],
              ["$Jan 32, 05",       "mdy2", [], 0, ],
              ["$Jan 40, 05",       "mdy2", [], 0, ],
              ["$Jan 99, 05",       "mdy2", [], 0, ],

# m2d2y4 tests with named month.
              # Basic test case
              ["$Jan 01, 2005",       "m2d2y4", [], 0, ],
              # 2-digit year
              ["$Jan 01, 05",         "m2d2y4", [], 0, ],
              # No separator
              ["${Jan}012005",        "m2d2y4", [], 0, ],
              ["${Jan}0105",          "m2d2y4", [], 0, ],
              # odd number of digits in year
              [   "$Jan 01, 9",       "m2d2y4", [], 0, ],
              [ "$Jan 01, 120",       "m2d2y4", [], 0, ],
              ["$Jan 01, 90120",      "m2d2y4", [], 0, ],
              # Name spelled out
              ["$January 01, 2005",   "m2d2y4", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["$February 1, 2005",   "m2d2y4", [], 0, ],
              ["$March 2, 2005",      "m2d2y4", [], 0, ],
              ["$April 09, 2005",     "m2d2y4", [], 0, ],
              ["$MayFull 9, 2005",    "m2d2y4", [], 0, ],
              ["$June 10, 2005",      "m2d2y4", [], 0, ],
              ["$July 11, 2005",      "m2d2y4", [], 0, ],
              ["$August 19, 2005",    "m2d2y4", [], 0, ],
              ["$September 20, 2005", "m2d2y4", [], 0, ],
              ["$October 21, 2005",   "m2d2y4", [], 0, ],
              ["$November 30, 2005",  "m2d2y4", [], 0, ],
              ["$December 31, 2005",  "m2d2y4", [], 0, ],
              ["$Feb 1, 2005",        "m2d2y4", [], 0, ],
              ["$Mar 2, 2005",        "m2d2y4", [], 0, ],
              ["$Apr 09, 2005",       "m2d2y4", [], 0, ],
              ["$May 9, 2005",        "m2d2y4", [], 0, ],
              ["$Jun 10, 2005",       "m2d2y4", [], 0, ],
              ["$Jul 11, 2005",       "m2d2y4", [], 0, ],
              ["$Aug 19, 2005",       "m2d2y4", [], 0, ],
              ["$Sep 20, 2005",       "m2d2y4", [], 0, ],
              ["$Oct 21, 2005",       "m2d2y4", [], 0, ],
              ["$Nov 30, 2005",       "m2d2y4", [], 0, ],
              ["$Dec 31, 2005",       "m2d2y4", [], 0, ],
              # Case insensitivity
              ["\L$Jan 01, 2005",     "m2d2y4", [], 0, ],
              ["\U\l$Jan 01, 2005",   "m2d2y4", [], 0, ],
              # Alternate separators
              ["$Jan 01 ,2005",       "m2d2y4", [], 0, ],
              ["$Jan 01 2005",        "m2d2y4", [], 0, ],
              ["$Jan-01-2005",        "m2d2y4", [], 0, ],
              # Mismatched or invalid separators
              ["$Jan/19-2005",        "mdy", [], 0, ],
              ["$Jan-19.2005",        "mdy", [], 0, ],
              ["$Jan%19%2005",        "mdy", [], 0, ],
              ["$Jan-01,-2005",       "mdy", [], 0, ],
              ["$Jan:01,:2005",       "mdy", [], 0, ],
              # Schmutz before/after the date
              ["blah$Jan 01, 2005",   "m2d2y4", [], 0, ],
              ["$Jan 01, 2005blah",   "m2d2y4", [], 0, ],
              # Bad day
              ["$Jan 00, 2005",       "m2d2y4", [], 0, ],
              ["$Jan 0, 2005",        "m2d2y4", [], 0, ],
              ["$Jan 32, 2005",       "m2d2y4", [], 0, ],
              ["$Jan 40, 2005",       "m2d2y4", [], 0, ],
              ["$Jan 99, 2005",       "m2d2y4", [], 0, ],

# m2d2y2 tests with named month.
              # Basic test case
              ["$Jan 01, 2005",       "m2d2y2", [], 0, ],
              # 2-digit year
              ["$Jan 01, 05",         "m2d2y2", [], 0, ],
              # No separator
              ["${Jan}012005",        "m2d2y2", [], 1, [qw(012005 01 20 05)]],
              ["${Jan}0105",          "m2d2y2", [], 0, ],
              # odd number of digits in year
              [   "$Jan 01, 9",       "m2d2y2", [], 0, ],
              [ "$Jan 01, 120",       "m2d2y2", [], 0, ],
              # Name spelled out
              ["$January 01, 2005",   "m2d2y2", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["$February 1, 05",   "m2d2y2", [], 0, ],
              ["$March 2, 05",      "m2d2y2", [], 0, ],
              ["$April 09, 05",     "m2d2y2", [], 0, ],
              ["$May 9, 05",        "m2d2y2", [], 0, ],
              ["$June 10, 05",      "m2d2y2", [], 0, ],
              ["$July 11, 05",      "m2d2y2", [], 0, ],
              ["$August 19, 05",    "m2d2y2", [], 0, ],
              ["$September 20, 05", "m2d2y2", [], 0, ],
              ["$October 21, 05",   "m2d2y2", [], 0, ],
              ["$November 30, 05",  "m2d2y2", [], 0, ],
              ["$December 31, 05",  "m2d2y2", [], 0, ],
              ["$Feb 1, 05",        "m2d2y2", [], 0, ],
              ["$Mar 2, 05",        "m2d2y2", [], 0, ],
              ["$Apr 09, 05",       "m2d2y2", [], 0, ],
              ["$May 9, 05",        "m2d2y2", [], 0, ],
              ["$Jun 10, 05",       "m2d2y2", [], 0, ],
              ["$Jul 11, 05",       "m2d2y2", [], 0, ],
              ["$Aug 19, 05",       "m2d2y2", [], 0, ],
              ["$Sep 20, 05",       "m2d2y2", [], 0, ],
              ["$Oct 21, 05",       "m2d2y2", [], 0, ],
              ["$Nov 30, 05",       "m2d2y2", [], 0, ],
              ["$Dec 31, 05",       "m2d2y2", [], 0, ],
              # Case insensitivity
              ["\L$Jan 01, 05",     "m2d2y2", [], 0, ],
              ["\U\l$Jan 01, 05",   "m2d2y2", [], 0, ],
              # Alternate separators
              ["$Jan 01 ,05",       "m2d2y2", [], 0, ],
              ["$Jan 01 05",        "m2d2y2", [], 0, ],
              ["$Jan-01-05",        "m2d2y2", [], 0, ],
              # Mismatched or invalid separators
              ["$Jan/19-05",        "mdy", [], 0, ],
              ["$Jan-19.05",        "mdy", [], 0, ],
              ["$Jan%19%05",        "mdy", [], 0, ],
              ["$Jan-01,-05",       "mdy", [], 0, ],
              ["$Jan:01,:05",       "mdy", [], 0, ],
              # Schmutz before/after the date
              ["blah$Jan 01, 05",   "m2d2y2", [], 0, ],
              ["$Jan 01, 05blah",   "m2d2y2", [], 0, ],
              # Bad day
              ["$Jan 00, 05",       "m2d2y2", [], 0, ],
              ["$Jan 0, 05",        "m2d2y2", [], 0, ],
              ["$Jan 32, 05",       "m2d2y2", [], 0, ],
              ["$Jan 40, 05",       "m2d2y2", [], 0, ],
              ["$Jan 99, 05",       "m2d2y2", [], 0, ],

             );

    # MDY is an exact synonym for m2d2y4
    my @MDY = grep { $_->[1] eq 'm2d2y4' } @match;
    $_->[1] = 'MDY' for @MDY;
    push @match, @MDY;

    # How many matches will succeed?
    my $to_succeed = scalar grep $_->[3], @match;

    # Run two tests per match, plus two additional per expected success
    $num_tests = 2 * scalar(@match)  +  2 * $to_succeed;

    # Plus one for the 'use_ok' call
    $num_tests += 1;
}

use Test::More tests => $num_tests;

use_ok('Regexp::Common', 'time');

foreach my $match (@match)
{
    my ($text, $name, $flags, $should_succeed, $matchvars) = @$match;
    my $testname = qq{"$text" =~ "$name"};
    my $did_succeed;
    my @captures;     # Regexp captures

    # FIRST: check whether it succeeded or failed as expected.
    # 'keep' option is OFF; should be no captures.
    if (@$flags)
    {
        my $flags = join $; => @$flags;
        @captures = $text =~ /$RE{time}{$name}{$flags}/;
    }
    else
    {
        @captures = $text =~ /$RE{time}{$name}/;
    }
    $did_succeed = @captures > 0;

    my $ought  = $should_succeed? 'match' : 'fail';
    my $actual = $did_succeed == $should_succeed?    "${ought}ed" : "did not $ought";

    # TEST 1: simple matching
    ok ( ($should_succeed && $did_succeed)
     || (!$should_succeed && !$did_succeed),
       "$testname - $actual as expected (nokeep).");

    # TEST 2: Shouldn't capture anything
    if ($should_succeed)
    {
        SKIP:
        {
            skip "$testname - can't check captures since match unsuccessful", 1 if !$did_succeed;
            is_deeply(\@captures, [1], "$testname - didn't unduly capture");
        }
    }

    # SECOND: use 'keep' option to check captures.
    if (@$flags)
    {
        my $flags = join $; => @$flags;
        @captures = $text =~ /$RE{time}{$name}{$flags}{-keep}/;
    }
    else
    {
        @captures = $text =~ /$RE{time}{$name}{-keep}/;
    }
    $did_succeed = @captures > 0;

    # TEST 3: matching with 'keep'
    ok ( ($should_succeed && $did_succeed)
     || (!$should_succeed && !$did_succeed),
       "$testname - $actual as expected (keep).");

    # TEST 4: capture variables should be set.
    if ($should_succeed)
    {
        SKIP:
        {
            skip "$testname - can't check captures since match unsuccessful", 1 if !$did_succeed;
            is_deeply(\@captures, $matchvars, "$testname - correct capture variables");
        }
    }
}
