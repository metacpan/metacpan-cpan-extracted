use strict;
use warnings;

my (@match, $num_tests);

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
            = qw(January February March April MayFull June July August September October November December);
    }

    @match = (
# ymd tests.
              ['2005/10/19', 'ymd', [], 1, [qw(2005/10/19 2005 10 19)]],
              ['2005.10.19', 'ymd', [], 1, [qw(2005.10.19 2005 10 19)]],
              ['2005-10-19', 'ymd', [], 1, [qw(2005-10-19 2005 10 19)]],
              ['2005x10x19', 'ymd', [], 0, ],
              ['20051019',   'ymd', [], 1, [qw(20051019   2005 10 19)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc2005/10/19xyz', 'ymd', [], 1, [qw(2005/10/19 2005 10 19)]],
              ['abc2005.10.19xyz', 'ymd', [], 1, [qw(2005.10.19 2005 10 19)]],
              ['abc2005-10-19xyz', 'ymd', [], 1, [qw(2005-10-19 2005 10 19)]],
              ['abc2005x10x19xyz', 'ymd', [], 0, ],
              ['abc20051019xyz',   'ymd', [], 1, [qw(20051019   2005 10 19)]],
              # However, leading or trailing digits should cause this loose match to fail.
              ['abc2005/10/190', 'ymd', [], 0, ],
              ['02005-10-19xyz', 'ymd', [], 0, ],
              # Mismatched or otherwise bogus separators
              ['2005:10:19', 'ymd', [], 0, ],
              ['2005/10-19', 'ymd', [], 0, ],
              ['2005-10/19', 'ymd', [], 0, ],
              ['2005-10.19', 'ymd', [], 0, ],
              ['2005.10-19', 'ymd', [], 0, ],
              ['2005-1019',  'ymd', [], 0, ],
              ['2005.1019',  'ymd', [], 0, ],
              ['2005/1019',  'ymd', [], 0, ],
              ['200510-19',  'ymd', [], 1, [qw(200510 20 05 10)]],
              ['200510.19',  'ymd', [], 1, [qw(200510 20 05 10)]],
              ['200510/19',  'ymd', [], 1, [qw(200510 20 05 10)]],
              # Odd number of digits in year
              ['5/10/19',    'ymd', [], 0, ],
              ['205/10/19',  'ymd', [], 0, ],
              ['12005/10/19','ymd', [], 0, ],
              # Two-year date should match ymd as well
              ['05/10/19', 'ymd', [], 1, [qw(05/10/19 05 10 19)]],
              ['05.10.19', 'ymd', [], 1, [qw(05.10.19 05 10 19)]],
              ['05-10-19', 'ymd', [], 1, [qw(05-10-19 05 10 19)]],
              ['05x10x19', 'ymd', [], 0, ],
              ['051019',   'ymd', [], 1, [qw(051019   05 10 19)]],
              # one-digit month
              ['2005/1/19', 'ymd', [], 1, [qw(2005/1/19 2005 1 19)]],
              ['2005.1.19', 'ymd', [], 1, [qw(2005.1.19 2005 1 19)]],
              ['2005-1-19', 'ymd', [], 1, [qw(2005-1-19 2005 1 19)]],
              ['2005x1x19', 'ymd', [], 0, ],
              ['2005119',   'ymd', [], 0, ],
              # one-digit day
              ['2005/10/9', 'ymd', [], 1, [qw(2005/10/9 2005 10 9)]],
              ['2005.10.9', 'ymd', [], 1, [qw(2005.10.9 2005 10 9)]],
              ['2005-10-9', 'ymd', [], 1, [qw(2005-10-9 2005 10 9)]],
              ['2005x10x9', 'ymd', [], 0, ],
              ['2005109',   'ymd', [], 0, ],
              # one-digit month and day
              ['2005/1/9', 'ymd', [], 1, [qw(2005/1/9 2005 1 9)]],
              ['2005.1.9', 'ymd', [], 1, [qw(2005.1.9 2005 1 9)]],
              ['2005-1-9', 'ymd', [], 1, [qw(2005-1-9 2005 1 9)]],
              ['2005x1x9', 'ymd', [], 0, ],
              ['200519',   'ymd', [], 1, [qw(200519 20 05 19)]],
              # yy/m/dd
              ['05/1/19', 'ymd', [], 1, [qw(05/1/19 05 1 19)]],
              ['05.1.19', 'ymd', [], 1, [qw(05.1.19 05 1 19)]],
              ['05-1-19', 'ymd', [], 1, [qw(05-1-19 05 1 19)]],
              ['05x1x19', 'ymd', [], 0, ],
              ['05119',   'ymd', [], 0, ],
              # yy/mm/d
              ['05/10/9', 'ymd', [], 1, [qw(05/10/9 05 10 9)]],
              ['05.10.9', 'ymd', [], 1, [qw(05.10.9 05 10 9)]],
              ['05-10-9', 'ymd', [], 1, [qw(05-10-9 05 10 9)]],
              ['05x10x9', 'ymd', [], 0, ],
              ['05109',   'ymd', [], 0, ],
              # yy/m/d
              ['05/1/9', 'ymd', [], 1, [qw(05/1/9 05 1 9)]],
              ['05.1.9', 'ymd', [], 1, [qw(05.1.9 05 1 9)]],
              ['05-1-9', 'ymd', [], 1, [qw(05-1-9 05 1 9)]],
              ['05x1x9', 'ymd', [], 0, ],
              ['0519',   'ymd', [], 0, ],
              # Invalid month
              ['2005/13/19', 'ymd', [], 0, ],
              ['2005/21/19', 'ymd', [], 0, ],
              ['2005/0/19',  'ymd', [], 0, ],
              ['2005/00/19', 'ymd', [], 0, ],
              # Invalid day
              ['2005/12/0', 'ymd',  [], 0, ],
              ['2005/12/00', 'ymd', [], 0, ],
              ['2005/12/40', 'ymd', [], 0, ],
              ['2005/12/32', 'ymd', [], 0, ],

# y4md tests.  Mostly the same as above.
              ['2005/10/19', 'y4md', [], 1, [qw(2005/10/19 2005 10 19)]],
              ['2005.10.19', 'y4md', [], 1, [qw(2005.10.19 2005 10 19)]],
              ['2005-10-19', 'y4md', [], 1, [qw(2005-10-19 2005 10 19)]],
              ['2005x10x19', 'y4md', [], 0, ],
              ['20051019',   'y4md', [], 1, [qw(20051019   2005 10 19)]],
              # leading/trailing junk shouldn't cause the match to change
              # however, trailing digits will cause loose d to fail
              ['abc2005/10/19xyz', 'y4md', [], 1, [qw(2005/10/19 2005 10 19)]],
              ['abc2005.10.19000', 'y4md', [], 0, ],
              ['0002005-10-19000', 'y4md', [], 0, ],
              ['abc2005x10x19000', 'y4md', [], 0, ],
              ['abc20051019xyz',   'y4md', [], 1, [qw(20051019   2005 10 19)]],
              ['abc20051019000',   'y4md', [], 0, ],
              # Mismatched or otherwise bogus separators
              ['2005:10:19', 'y4md', [], 0, ],
              ['2005/10-19', 'y4md', [], 0, ],
              ['2005-10/19', 'y4md', [], 0, ],
              ['2005-10.19', 'y4md', [], 0, ],
              ['2005.10-19', 'y4md', [], 0, ],
              ['2005-1019',  'y4md', [], 0, ],
              ['2005.1019',  'y4md', [], 0, ],
              ['2005/1019',  'y4md', [], 0, ],
              ['200510-19',  'y4md', [], 0, ],
              ['200510.19',  'y4md', [], 0, ],
              ['200510/19',  'y4md', [], 0, ],
              # Two-year date should not match y4md
              ['05/10/19', 'y4md', [], 0, ],
              ['05.10.19', 'y4md', [], 0, ],
              ['05-10-19', 'y4md', [], 0, ],
              ['05x10x19', 'y4md', [], 0, ],
              ['051019',   'y4md', [], 0, ],
              # one-digit month
              ['2005/1/19', 'y4md', [], 1, [qw(2005/1/19 2005 1 19)]],
              ['2005.1.19', 'y4md', [], 1, [qw(2005.1.19 2005 1 19)]],
              ['2005-1-19', 'y4md', [], 1, [qw(2005-1-19 2005 1 19)]],
              ['2005x1x19', 'y4md', [], 0, ],
              ['2005119',   'y4md', [], 0, ],
              # one-digit day
              ['2005/10/9', 'y4md', [], 1, [qw(2005/10/9 2005 10 9)]],
              ['2005.10.9', 'y4md', [], 1, [qw(2005.10.9 2005 10 9)]],
              ['2005-10-9', 'y4md', [], 1, [qw(2005-10-9 2005 10 9)]],
              ['2005x10x9', 'y4md', [], 0, ],
              ['2005109',   'y4md', [], 0, ],
              # one-digit month and day
              ['2005/1/9', 'y4md', [], 1, [qw(2005/1/9 2005 1 9)]],
              ['2005.1.9', 'y4md', [], 1, [qw(2005.1.9 2005 1 9)]],
              ['2005-1-9', 'y4md', [], 1, [qw(2005-1-9 2005 1 9)]],
              ['2005x1x9', 'y4md', [], 0, ],
              ['200519',   'y4md', [], 0, ],
              # yy/m/dd
              ['05/1/19', 'y4md', [], 0, ],
              ['05.1.19', 'y4md', [], 0, ],
              ['05-1-19', 'y4md', [], 0, ],
              ['05x1x19', 'y4md', [], 0, ],
              ['05119',   'y4md', [], 0, ],
              # yy/mm/d
              ['05/10/9', 'y4md', [], 0, ],
              ['05.10.9', 'y4md', [], 0, ],
              ['05-10-9', 'y4md', [], 0, ],
              ['05x10x9', 'y4md', [], 0, ],
              ['05109',   'y4md', [], 0, ],
              # yy/m/d
              ['05/1/9', 'y4md', [], 0, ],
              ['05.1.9', 'y4md', [], 0, ],
              ['05-1-9', 'y4md', [], 0, ],
              ['05x1x9', 'y4md', [], 0, ],
              ['0519',   'y4md', [], 0, ],
              # Invalid month
              ['2005/13/19', 'y4md', [], 0, ],
              ['2005/21/19', 'y4md', [], 0, ],
              ['2005/0/19',  'y4md', [], 0, ],
              ['2005/00/19', 'y4md', [], 0, ],
              # Invalid day
              ['2005/12/0', 'y4md',  [], 0, ],
              ['2005/12/00', 'y4md', [], 0, ],
              ['2005/12/40', 'y4md', [], 0, ],
              ['2005/12/32', 'y4md', [], 0, ],

# y2md tests
              ['2005/10/19', 'y2md', [], 1, [qw(05/10/19 05 10 19)]],
              ['2005.10.19', 'y2md', [], 1, [qw(05.10.19 05 10 19)]],
              ['2005-10-19', 'y2md', [], 1, [qw(05-10-19 05 10 19)]],
              ['2005x10x19', 'y2md', [], 0, ],
              ['20051019',   'y2md', [], 1, [qw(051019   05 10 19)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc2005/10/19xyz', 'y2md', [], 1, [qw(05/10/19 05 10 19)]],
              ['abc2005.10.19xyz', 'y2md', [], 1, [qw(05.10.19 05 10 19)]],
              ['abc2005-10-19xyz', 'y2md', [], 1, [qw(05-10-19 05 10 19)]],
              ['abc2005x10x19xyz', 'y2md', [], 0, ],
              ['abc20051019xyz',   'y2md', [], 1, [qw(051019  05 10 19)]],
              # However, trailing digits will cause loose d to fail
              ['02005/10/19xyz',   'y2md', [], 1, [qw(05/10/19 05 10 19)]],
              ['abc2005.10.19000', 'y2md', [], 0, ],
              # Mismatched or otherwise bogus separators
              ['05:10:19', 'y2md', [], 0, ],
              ['05/10-19', 'y2md', [], 0, ],
              ['05-10/19', 'y2md', [], 0, ],
              ['05-10.19', 'y2md', [], 0, ],
              ['05.10-19', 'y2md', [], 0, ],
              ['05-1019',  'y2md', [], 0, ],
              ['05.1019',  'y2md', [], 0, ],
              ['05/1019',  'y2md', [], 0, ],
              ['0510-19',  'y2md', [], 0, ],
              ['0510.19',  'y2md', [], 0, ],
              ['0510/19',  'y2md', [], 0, ],
              # Two-year date should match
              ['05/10/19', 'y2md', [], 1, [qw(05/10/19 05 10 19)]],
              ['05.10.19', 'y2md', [], 1, [qw(05.10.19 05 10 19)]],
              ['05-10-19', 'y2md', [], 1, [qw(05-10-19 05 10 19)]],
              ['05x10x19', 'y2md', [], 0, ],
              ['051019',   'y2md', [], 1, [qw(051019   05 10 19)]],
              # separators
              ['05/10/19', 'y2md', [],  1, [qw(05/10/19 05 10 19)]],
              ['05.10.19', 'y2md', [],  1, [qw(05.10.19 05 10 19)]],
              ['05-10-19', 'y2md', [],  1, [qw(05-10-19 05 10 19)]],
              ['05x10x19', 'y2md', [],  0, ],
              ['051019',   'y2md', [],  1, [qw(051019   05 10 19)]],
              # one-digit month
              ['2005/1/19', 'y2md', [], 1, [qw(05/1/19 05 1 19)]],
              ['2005.1.19', 'y2md', [], 1, [qw(05.1.19 05 1 19)]],
              ['2005-1-19', 'y2md', [], 1, [qw(05-1-19 05 1 19)]],
              ['2005x1x19', 'y2md', [], 0, ],
              ['2005119',   'y2md', [], 0, ],
              # one-digit day
              ['2005/10/9', 'y2md', [], 1, [qw(05/10/9 05 10 9)]],
              ['2005.10.9', 'y2md', [], 1, [qw(05.10.9 05 10 9)]],
              ['2005-10-9', 'y2md', [], 1, [qw(05-10-9 05 10 9)]],
              ['2005x10x9', 'y2md', [], 0, ],
              ['2005109',   'y2md', [], 0, ],
              # one-digit month and day
              ['2005/1/9', 'y2md', [], 1, [qw(05/1/9 05 1 9)]],
              ['2005.1.9', 'y2md', [], 1, [qw(05.1.9 05 1 9)]],
              ['2005-1-9', 'y2md', [], 1, [qw(05-1-9 05 1 9)]],
              ['2005x1x9', 'y2md', [], 0, ],
              ['200519',   'y2md', [], 1, [qw(200519 20 05 19)]],
              # yy/m/dd
              ['05/1/19', 'y2md', [], 1, [qw(05/1/19 05 1 19)]],
              ['05.1.19', 'y2md', [], 1, [qw(05.1.19 05 1 19)]],
              ['05-1-19', 'y2md', [], 1, [qw(05-1-19 05 1 19)]],
              ['05x1x19', 'y2md', [], 0, ],
              ['05119',   'y2md', [], 0, ],
              # yy/mm/d
              ['05/10/9', 'y2md', [], 1, [qw(05/10/9 05 10 9)]],
              ['05.10.9', 'y2md', [], 1, [qw(05.10.9 05 10 9)]],
              ['05-10-9', 'y2md', [], 1, [qw(05-10-9 05 10 9)]],
              ['05x10x9', 'y2md', [], 0, ],
              ['05109',   'y2md', [], 0, ],
              # yy/m/d
              ['05/1/9', 'y2md', [], 1, [qw(05/1/9 05 1 9)]],
              ['05.1.9', 'y2md', [], 1, [qw(05.1.9 05 1 9)]],
              ['05-1-9', 'y2md', [], 1, [qw(05-1-9 05 1 9)]],
              ['05x1x9', 'y2md', [], 0, ],
              ['0519',   'y2md', [], 0, ],
              # Invalid month
              ['05/13/19', 'y2md', [], 0, ],
              ['05/21/19', 'y2md', [], 0, ],
              ['05/0/19',  'y2md', [], 0, ],
              ['05/00/19', 'y2md', [], 0, ],
              # Invalid day
              ['05/12/0',  'y2md', [], 0, ],
              ['05/12/00', 'y2md', [], 0, ],
              ['05/12/40', 'y2md', [], 0, ],
              ['05/12/32', 'y2md', [], 0, ],

# y4m2d2 tests
              ['2005/10/19', 'y4m2d2', [], 1, [qw(2005/10/19 2005 10 19)]],
              ['2005.10.19', 'y4m2d2', [], 1, [qw(2005.10.19 2005 10 19)]],
              ['2005-10-19', 'y4m2d2', [], 1, [qw(2005-10-19 2005 10 19)]],
              ['2005x10x19', 'y4m2d2', [], 0, ],
              ['20051019',   'y4m2d2', [], 1, [qw(20051019   2005 10 19)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc2005/10/19000', 'y4m2d2', [], 1, [qw(2005/10/19 2005 10 19)]],
              ['0002005.10.19000', 'y4m2d2', [], 1, [qw(2005.10.19 2005 10 19)]],
              ['0002005-10-19000', 'y4m2d2', [], 1, [qw(2005-10-19 2005 10 19)]],
              ['abc2005x10x19000', 'y4m2d2', [], 0, ],
              ['abc20051019000',   'y4m2d2', [], 1, [qw(20051019   2005 10 19)]],
              # Two-year date should not match
              ['05/10/19', 'y4m2d2', [], 0, ],
              ['05.10.19', 'y4m2d2', [], 0, ],
              ['05-10-19', 'y4m2d2', [], 0, ],
              ['05x10x19', 'y4m2d2', [], 0, ],
              ['051019',   'y4m2d2', [], 0, ],
              # separators
              ['2005/10/19', 'y4m2d2', [],  1, [qw(2005/10/19 2005 10 19)]],
              ['2005.10.19', 'y4m2d2', [],  1, [qw(2005.10.19 2005 10 19)]],
              ['2005-10-19', 'y4m2d2', [],  1, [qw(2005-10-19 2005 10 19)]],
              ['2005x10x19', 'y4m2d2', [],  0, ],
              ['2005 10 19', 'y4m2d2', [],  1, ['2005 10 19', qw(2005 10 19)]],
              # one-digit month
              ['2005/1/19', 'y4m2d2', [], 0, ],
              ['2005.1.19', 'y4m2d2', [], 0, ],
              ['2005-1-19', 'y4m2d2', [], 0, ],
              ['2005x1x19', 'y4m2d2', [], 0, ],
              ['2005119',   'y4m2d2', [], 0, ],
              # one-digit day
              ['2005/10/9', 'y4m2d2', [], 0, ],
              ['2005.10.9', 'y4m2d2', [], 0, ],
              ['2005-10-9', 'y4m2d2', [], 0, ],
              ['2005x10x9', 'y4m2d2', [], 0, ],
              ['2005109',   'y4m2d2', [], 0, ],
              # one-digit month and day
              ['2005/1/9', 'y4m2d2', [], 0, ],
              ['2005.1.9', 'y4m2d2', [], 0, ],
              ['2005-1-9', 'y4m2d2', [], 0, ],
              ['2005x1x9', 'y4m2d2', [], 0, ],
              ['200519',   'y4m2d2', [], 0, ],
              # yy/m/dd
              ['05/1/19', 'y4m2d2', [], 0, ],
              ['05.1.19', 'y4m2d2', [], 0, ],
              ['05-1-19', 'y4m2d2', [], 0, ],
              ['05x1x19', 'y4m2d2', [], 0, ],
              ['05119',   'y4m2d2', [], 0, ],
              # yy/mm/d
              ['05/10/9', 'y4m2d2', [], 0, ],
              ['05.10.9', 'y4m2d2', [], 0, ],
              ['05-10-9', 'y4m2d2', [], 0, ],
              ['05x10x9', 'y4m2d2', [], 0, ],
              ['05109',   'y4m2d2', [], 0, ],
              # yy/m/d
              ['05/1/9', 'y4m2d2', [], 0, ],
              ['05.1.9', 'y4m2d2', [], 0, ],
              ['05-1-9', 'y4m2d2', [], 0, ],
              ['05x1x9', 'y4m2d2', [], 0, ],
              ['0519',   'y4m2d2', [], 0, ],
              # Invalid month
              ['2005/13/19', 'y4m2d2', [], 0, ],
              ['2005/21/19', 'y4m2d2', [], 0, ],
              ['2005/0/19',  'y4m2d2', [], 0, ],
              ['2005/00/19', 'y4m2d2', [], 0, ],
              # Invalid day
              ['2005/12/0',  'y4m2d2', [], 0, ],
              ['2005/12/00', 'y4m2d2', [], 0, ],
              ['2005/12/40', 'y4m2d2', [], 0, ],
              ['2005/12/32', 'y4m2d2', [], 0, ],

# y2m2d2 tests
              ['2005/10/19', 'y2m2d2', [], 1, [qw(05/10/19 05 10 19)]],
              ['2005.10.19', 'y2m2d2', [], 1, [qw(05.10.19 05 10 19)]],
              ['2005-10-19', 'y2m2d2', [], 1, [qw(05-10-19 05 10 19)]],
              ['2005x10x19', 'y2m2d2', [], 0, ],
              ['20051019',   'y2m2d2', [], 1, [qw(200510   20 05 10)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc2005/10/19000', 'y2m2d2', [], 1, [qw(05/10/19 05 10 19)]],
              ['abc2005.10.19000', 'y2m2d2', [], 1, [qw(05.10.19 05 10 19)]],
              ['abc2005-10-19000', 'y2m2d2', [], 1, [qw(05-10-19 05 10 19)]],
              ['abc2005x10x19000', 'y2m2d2', [], 0, ],
              ['abc20051019000',   'y2m2d2', [], 1, [qw(200510   20 05 10)]],
              # Two-year date should match
              ['05/10/19', 'y2m2d2', [], 1, [qw(05/10/19 05 10 19)]],
              ['05.10.19', 'y2m2d2', [], 1, [qw(05.10.19 05 10 19)]],
              ['05-10-19', 'y2m2d2', [], 1, [qw(05-10-19 05 10 19)]],
              ['05x10x19', 'y2m2d2', [], 0, ],
              ['051019',   'y2m2d2', [], 1, [qw(051019   05 10 19)]],
              # separators
              ['05/10/19', 'y2m2d2', [],  1, [qw(05/10/19 05 10 19)]],
              ['05.10.19', 'y2m2d2', [],  1, [qw(05.10.19 05 10 19)]],
              ['05-10-19', 'y2m2d2', [],  1, [qw(05-10-19 05 10 19)]],
              ['05x10x19', 'y2m2d2', [],  0, ],
              ['051019',   'y2m2d2', [],  1, [qw(051019   05 10 19)]],
              # one-digit month
              ['2005/1/19', 'y2m2d2', [], 0, ],
              ['2005.1.19', 'y2m2d2', [], 0, ],
              ['2005-1-19', 'y2m2d2', [], 0, ],
              ['2005x1x19', 'y2m2d2', [], 0, ],
              ['2005119',   'y2m2d2', [], 1, [qw(200511 20 05 11)]],
              # one-digit day
              ['2005/10/9', 'y2m2d2', [], 0, ],
              ['2005.10.9', 'y2m2d2', [], 0, ],
              ['2005-10-9', 'y2m2d2', [], 0, ],
              ['2005x10x9', 'y2m2d2', [], 0, ],
              ['2005109',   'y2m2d2', [], 1, [qw(200510 20 05 10)]],
              # one-digit month and day
              ['2005/1/9', 'y2m2d2', [], 0, ],
              ['2005.1.9', 'y2m2d2', [], 0, ],
              ['2005-1-9', 'y2m2d2', [], 0, ],
              ['2005x1x9', 'y2m2d2', [], 0, ],
              ['200519',   'y2m2d2', [], 1, [qw(200519 20 05 19)]],
              # yy/m/dd
              ['05/1/19', 'y2m2d2', [], 0, ],
              ['05.1.19', 'y2m2d2', [], 0, ],
              ['05-1-19', 'y2m2d2', [], 0, ],
              ['05x1x19', 'y2m2d2', [], 0, ],
              ['05119',   'y2m2d2', [], 0, ],
              # yy/mm/d
              ['05/10/9', 'y2m2d2', [], 0, ],
              ['05.10.9', 'y2m2d2', [], 0, ],
              ['05-10-9', 'y2m2d2', [], 0, ],
              ['05x10x9', 'y2m2d2', [], 0, ],
              ['05109',   'y2m2d2', [], 0, ],
              # yy/m/d
              ['05/1/9', 'y2m2d2', [], 0, ],
              ['05.1.9', 'y2m2d2', [], 0, ],
              ['05-1-9', 'y2m2d2', [], 0, ],
              ['05x1x9', 'y2m2d2', [], 0, ],
              ['0519',   'y2m2d2', [], 0, ],
              # Invalid month
              ['05/13/19', 'y2m2d2', [], 0, ],
              ['05/21/19', 'y2m2d2', [], 0, ],
              ['05/0/19',  'y2m2d2', [], 0, ],
              ['05/00/19', 'y2m2d2', [], 0, ],
              # Invalid day
              ['05/12/0',  'y2m2d2', [], 0, ],
              ['05/12/00', 'y2m2d2', [], 0, ],
              ['05/12/40', 'y2m2d2', [], 0, ],
              ['05/12/32', 'y2m2d2', [], 0, ],

# ymd tests with month names.
              # Basic test case
              ["2005 $Jan 01",       "ymd", [], 1, ["2005 $Jan 01",   '2005', $Jan, '01']],
              # 2-digit year
              [  "05 $Jan 01",       "ymd", [], 1, [  "05 $Jan 01",     '05', $Jan, '01']],
              # odd number of digits in year
              [   "0 $Jan 01",       "ymd", [], 0, ],
              [ "120 $Jan 01",       "ymd", [], 0, ],
              # Name spelled out
              ["2005 $January 01",   "ymd", [], 1, ["2005 $January 01", '2005', $January, '01']],
              # Partial name should fail
              ["2005 ${Jan}u 01",    "ymd", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["2005 $February 1",   "ymd", [], 1, ["2005 $February 1",   '2005', $February,   '1']],
              ["2005 $March 2",      "ymd", [], 1, ["2005 $March 2",      '2005', $March,      '2']],
              ["2005 $April 09",     "ymd", [], 1, ["2005 $April 09",     '2005', $April,     '09']],
              ["2005 $May 9",        "ymd", [], 1, ["2005 $May 9",        '2005', $May,        '9']],
              ["2005 $June 10",      "ymd", [], 1, ["2005 $June 10",      '2005', $June,      '10']],
              ["2005 $July 11",      "ymd", [], 1, ["2005 $July 11",      '2005', $July,      '11']],
              ["2005 $August 19",    "ymd", [], 1, ["2005 $August 19",    '2005', $August,    '19']],
              ["2005 $September 20", "ymd", [], 1, ["2005 $September 20", '2005', $September, '20']],
              ["2005 $October 21",   "ymd", [], 1, ["2005 $October 21",   '2005', $October,   '21']],
              ["2005 $November 30",  "ymd", [], 1, ["2005 $November 30",  '2005', $November,  '30']],
              ["2005 $December 31",  "ymd", [], 1, ["2005 $December 31",  '2005', $December,  '31']],
              ["2005 $Feb 1",        "ymd", [], 1, ["2005 $Feb 1",        '2005', $Feb,  '1']],
              ["2005 $Mar 2",        "ymd", [], 1, ["2005 $Mar 2",        '2005', $Mar,  '2']],
              ["2005 $Apr 09",       "ymd", [], 1, ["2005 $Apr 09",       '2005', $Apr, '09']],
              ["2005 $May 9",        "ymd", [], 1, ["2005 $May 9",        '2005', $May,  '9']],
              ["2005 $Jun 10",       "ymd", [], 1, ["2005 $Jun 10",       '2005', $Jun, '10']],
              ["2005 $Jul 11",       "ymd", [], 1, ["2005 $Jul 11",       '2005', $Jul, '11']],
              ["2005 $Aug 19",       "ymd", [], 1, ["2005 $Aug 19",       '2005', $Aug, '19']],
              ["2005 $Sep 20",       "ymd", [], 1, ["2005 $Sep 20",       '2005', $Sep, '20']],
              ["2005 $Oct 21",       "ymd", [], 1, ["2005 $Oct 21",       '2005', $Oct, '21']],
              ["2005 $Nov 30",       "ymd", [], 1, ["2005 $Nov 30",       '2005', $Nov, '30']],
              ["2005 $Dec 31",       "ymd", [], 1, ["2005 $Dec 31",       '2005', $Dec, '31']],
              # Case insensitivity
              ["2005 \L$Jan 01",     "ymd", [], 1, ["2005 \L$Jan 01",     '2005', lc($Jan), '01']],
              ["2005 \U\l$Jan 01",   "ymd", [], 1, ["2005 \U\l$Jan 01",   '2005', lcfirst(uc $Jan), '01']],
              # Alternate separators
              ["2005-$Jan-01",       "ymd", [], 1, ["2005-$Jan-01",     '2005', $Jan, '01']],
              ["2005.$Jan.01",       "ymd", [], 1, ["2005.$Jan.01",     '2005', $Jan, '01']],
              # Schmutz before/after the date
              ["blah2005 $Jan 01",   "ymd", [], 1, ["2005 $Jan 01",     '2005', $Jan, '01']],
              ["2005 $Jan 01blah",   "ymd", [], 1, ["2005 $Jan 01",     '2005', $Jan, '01']],
              ["2005 $Jan 011",      "ymd", [], 0, ],
              ["205 $Jan 01",        "ymd", [], 0, ],
              ["02005 $Jan 01",      "ymd", [], 0, ],
              # Bad separator
              ["2005x${Jan}x01",     "ymd", [], 0, ],
              # Bad day
              ["2005-$Jan-00",       "ymd", [], 0, ],
              ["2005-$Jan-0",        "ymd", [], 0, ],
              ["2005-$Jan-32",       "ymd", [], 0, ],
              ["2005-$Jan-40",       "ymd", [], 0, ],
              ["2005-$Jan-99",       "ymd", [], 0, ],

# y4md tests with month names.
              # Basic test case
              ["2005 $Jan 01",       "y4md", [], 1, ["2005 $Jan 01",   '2005', $Jan, '01']],
              # 2-digit year
              [  "05 $Jan 01",       "y4md", [], 0, ],
              # odd number of digits in year
              [   "0 $Jan 01",       "y4md", [], 0, ],
              [ "120 $Jan 01",       "y4md", [], 0, ],
              # Name spelled out
              ["2005 $January 01",   "y4md", [], 1, ["2005 $January 01",   '2005', $January, '01']],
              # Partial name should fail
              ["2005 ${Jan}u 01",    "y4md", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["2005 $February 1",   "y4md", [], 1, ["2005 $February 1",   '2005', $February,   '1']],
              ["2005 $March 2",      "y4md", [], 1, ["2005 $March 2",      '2005', $March,      '2']],
              ["2005 $April 09",     "y4md", [], 1, ["2005 $April 09",     '2005', $April,     '09']],
              ["2005 $May 9",        "y4md", [], 1, ["2005 $May 9",        '2005', $May,        '9']],
              ["2005 $June 10",      "y4md", [], 1, ["2005 $June 10",      '2005', $June,      '10']],
              ["2005 $July 11",      "y4md", [], 1, ["2005 $July 11",      '2005', $July,      '11']],
              ["2005 $August 19",    "y4md", [], 1, ["2005 $August 19",    '2005', $August,    '19']],
              ["2005 $September 20", "y4md", [], 1, ["2005 $September 20", '2005', $September, '20']],
              ["2005 $October 21",   "y4md", [], 1, ["2005 $October 21",   '2005', $October,   '21']],
              ["2005 $November 30",  "y4md", [], 1, ["2005 $November 30",  '2005', $November,  '30']],
              ["2005 $December 31",  "y4md", [], 1, ["2005 $December 31",  '2005', $December,  '31']],
              ["2005 $Feb 1",        "y4md", [], 1, ["2005 $Feb 1",        '2005', $Feb,  '1']],
              ["2005 $Mar 2",        "y4md", [], 1, ["2005 $Mar 2",        '2005', $Mar,  '2']],
              ["2005 $Apr 09",       "y4md", [], 1, ["2005 $Apr 09",       '2005', $Apr, '09']],
              ["2005 $May 9",        "y4md", [], 1, ["2005 $May 9",        '2005', $May,  '9']],
              ["2005 $Jun 10",       "y4md", [], 1, ["2005 $Jun 10",       '2005', $Jun, '10']],
              ["2005 $Jul 11",       "y4md", [], 1, ["2005 $Jul 11",       '2005', $Jul, '11']],
              ["2005 $Aug 19",       "y4md", [], 1, ["2005 $Aug 19",       '2005', $Aug, '19']],
              ["2005 $Sep 20",       "y4md", [], 1, ["2005 $Sep 20",       '2005', $Sep, '20']],
              ["2005 $Oct 21",       "y4md", [], 1, ["2005 $Oct 21",       '2005', $Oct, '21']],
              ["2005 $Nov 30",       "y4md", [], 1, ["2005 $Nov 30",       '2005', $Nov, '30']],
              ["2005 $Dec 31",       "y4md", [], 1, ["2005 $Dec 31",       '2005', $Dec, '31']],
              # Case insensitivity
              ["2005 \L$Jan 01",     "y4md", [], 1, ["2005 \L$Jan 01",     '2005', lc($Jan), '01']],
              ["2005 \U\l$Jan 01",   "y4md", [], 1, ["2005 \U\l$Jan 01",   '2005', lcfirst(uc $Jan), '01']],
              # Alternate separators
              ["2005-$Jan-01",       "y4md", [], 1, ["2005-$Jan-01",       '2005', $Jan, '01']],
              ["2005.$Jan.01",       "y4md", [], 1, ["2005.$Jan.01",       '2005', $Jan, '01']],
              # Schmutz before/after the date
              ["blah2005 $Jan 01",   "y4md", [], 1, ["2005 $Jan 01",       '2005', $Jan, '01']],
              ["2005 $Jan 01blah",   "y4md", [], 1, ["2005 $Jan 01",       '2005', $Jan, '01']],
              ["2005 $Jan 011",      "y4md", [], 0, ],
              ["12005 $Jan 01",      "y4md", [], 1, ["2005 $Jan 01",       '2005', $Jan, '01']],
              # Bad separator
              ["2005x${Jan}x01",     "y4md", [], 0, ],
              # Bad day
              ["2005-$Jan-00",       "y4md", [], 0, ],
              ["2005-$Jan-0",        "y4md", [], 0, ],
              ["2005-$Jan-32",       "y4md", [], 0, ],
              ["2005-$Jan-40",       "y4md", [], 0, ],
              ["2005-$Jan-99",       "y4md", [], 0, ],

# y2md tests with month names.
              # Basic test case
              [  "05 $Jan 01",     "y2md", [], 1, ["05 $Jan 01",   '05', $Jan, '01']],
              # 4-digit year
              ["2005 $Jan 01",     "y2md", [], 1, ["05 $Jan 01",   '05', $Jan, '01']],
              # odd number of digits in year
              [   "0 $Jan 01",     "y2md", [], 0, ],
              [ "120 $Jan 01",     "y2md", [], 1, ["20 $Jan 01",   '20', $Jan, '01']],
              # Name spelled out
              ["05 $January 01",   "y2md", [], 1, ["05 $January 01", '05', $January, '01']],
              # Partial name should fail
              ["05 ${Jan}u 01",    "y2md", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              ["05 $February 1",   "y2md", [], 1, ["05 $February 1",   '05', $February,   '1']],
              ["05 $March 2",      "y2md", [], 1, ["05 $March 2",      '05', $March,      '2']],
              ["05 $April 09",     "y2md", [], 1, ["05 $April 09",     '05', $April,     '09']],
              ["05 $May 9",        "y2md", [], 1, ["05 $May 9",        '05', $May,        '9']],
              ["05 $June 10",      "y2md", [], 1, ["05 $June 10",      '05', $June,      '10']],
              ["05 $July 11",      "y2md", [], 1, ["05 $July 11",      '05', $July,      '11']],
              ["05 $August 19",    "y2md", [], 1, ["05 $August 19",    '05', $August,    '19']],
              ["05 $September 20", "y2md", [], 1, ["05 $September 20", '05', $September, '20']],
              ["05 $October 21",   "y2md", [], 1, ["05 $October 21",   '05', $October,   '21']],
              ["05 $November 30",  "y2md", [], 1, ["05 $November 30",  '05', $November,  '30']],
              ["05 $December 31",  "y2md", [], 1, ["05 $December 31",  '05', $December,  '31']],
              ["05 $Feb 1",        "y2md", [], 1, ["05 $Feb 1",        '05', $Feb,  '1']],
              ["05 $Mar 2",        "y2md", [], 1, ["05 $Mar 2",        '05', $Mar,  '2']],
              ["05 $Apr 09",       "y2md", [], 1, ["05 $Apr 09",       '05', $Apr, '09']],
              ["05 $May 9",        "y2md", [], 1, ["05 $May 9",        '05', $May,  '9']],
              ["05 $Jun 10",       "y2md", [], 1, ["05 $Jun 10",       '05', $Jun, '10']],
              ["05 $Jul 11",       "y2md", [], 1, ["05 $Jul 11",       '05', $Jul, '11']],
              ["05 $Aug 19",       "y2md", [], 1, ["05 $Aug 19",       '05', $Aug, '19']],
              ["05 $Sep 20",       "y2md", [], 1, ["05 $Sep 20",       '05', $Sep, '20']],
              ["05 $Oct 21",       "y2md", [], 1, ["05 $Oct 21",       '05', $Oct, '21']],
              ["05 $Nov 30",       "y2md", [], 1, ["05 $Nov 30",       '05', $Nov, '30']],
              ["05 $Dec 31",       "y2md", [], 1, ["05 $Dec 31",       '05', $Dec, '31']],
              # Case insensitivity
              ["05 \L$Jan 01",     "y2md", [], 1, ["05 \L$Jan 01",     '05', lc($Jan), '01']],
              ["05 \U\l$Jan 01",   "y2md", [], 1, ["05 \U\l$Jan 01",   '05', lcfirst(uc $Jan), '01']],
              # Alternate separators
              ["05-$Jan-01",       "y2md", [], 1, ["05-$Jan-01",     '05', $Jan, '01']],
              ["05.$Jan.01",       "y2md", [], 1, ["05.$Jan.01",     '05', $Jan, '01']],
              # Schmutz before/after the date
              ["blah05 $Jan 01",   "y2md", [], 1, ["05 $Jan 01",     '05', $Jan, '01']],
              ["05 $Jan 01blah",   "y2md", [], 1, ["05 $Jan 01",     '05', $Jan, '01']],
              ["05 $Jan 011",      "y2md", [], 0, ],
              ["05 $Jan 01x",      "y2md", [], 1, ["05 $Jan 01",     '05', $Jan, '01']],
              ["105 $Jan 01",      "y2md", [], 1, ["05 $Jan 01",     '05', $Jan, '01']],
              # Bad separator
              ["05x${Jan}x01",     "y2md", [], 0, ],
              # Bad day
              ["05-$Jan-00",       "y2md", [], 0, ],
              ["05-$Jan-0",        "y2md", [], 0, ],
              ["05-$Jan-32",       "y2md", [], 0, ],
              ["05-$Jan-40",       "y2md", [], 0, ],
              ["05-$Jan-99",       "y2md", [], 0, ],

              # Add"l tests
              # In loose "ymd" format, trailing digits should cause the dd not to match.
              ["10-SEP-2005",     "ymd",  [], 0, ],

             );

    # YMD is an exact synonym for y4m2d2
    my @YMD = grep { $_->[1] eq 'y4m2d2' } @match;
    $_->[1] = 'YMD' for @YMD;
    push @match, @YMD;

    # How many matches will succeed?
    my $to_succeed = scalar grep $_->[3], @match;

    # Run two tests per match, plus two additional per expected success
    $num_tests = 2 * scalar(@match)  +  2 * $to_succeed;
}

use Test::More tests => $num_tests;

use Regexp::Common 'time';

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
