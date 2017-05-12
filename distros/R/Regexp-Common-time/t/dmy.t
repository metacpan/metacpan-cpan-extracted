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
            = qw(January February March April May June July August September October November December);
    }

    @match = (
# dmy tests.
              ['19/10/2005', 'dmy', [], 1, [qw(19/10/2005 19 10 2005)]],
              ['19.10.2005', 'dmy', [], 1, [qw(19.10.2005 19 10 2005)]],
              ['19-10-2005', 'dmy', [], 1, [qw(19-10-2005 19 10 2005)]],
              ['19x10x2005', 'dmy', [], 0, ],
              ['19102005',   'dmy', [], 1, [qw(19102005   19 10 2005)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc19/10/2005zyx', 'dmy', [], 1, [qw(19/10/2005 19 10 2005)]],
              ['abc19.10.2005zyx', 'dmy', [], 1, [qw(19.10.2005 19 10 2005)]],
              ['abc19-10-2005zyx', 'dmy', [], 1, [qw(19-10-2005 19 10 2005)]],
              ['abc19x10x2005zyx', 'dmy', [], 0, ],
              ['abc19102005zyx',   'dmy', [], 1, [qw(19102005   19 10 2005)]],
              # However, leading or trailing digits should cause this loose match to fail.
              ['019/10/2005', 'dmy', [], 0, ],
              ['19/10/050',   'dmy', [], 0, ],
              ['19/10/20050', 'dmy', [], 0, ],
              # Two-year date should match dmy as well
              ['19/10/05', 'dmy', [], 1, [qw(19/10/05 19 10 05)]],
              ['19.10.05', 'dmy', [], 1, [qw(19.10.05 19 10 05)]],
              ['19-10-05', 'dmy', [], 1, [qw(19-10-05 19 10 05)]],
              ['19x10x05', 'dmy', [], 0, ],
              ['191005',   'dmy', [], 1, [qw(191005     19 10 05)]],
              # separators
              ['19:10:2005', 'dmy', [],  0, ],
              ['19 10 2005', 'dmy', [],  1, [ q(19 10 2005), qw(19 10 2005)]],
              ['19*10*2005', 'dmy', [],  0, ],
              ['19?10?2005', 'dmy', [],  0, ],
              # one-digit month
              ['19/1/2005', 'dmy', [], 1, [qw(19/1/2005 19 1 2005)]],
              ['19.1.2005', 'dmy', [], 1, [qw(19.1.2005 19 1 2005)]],
              ['19-1-2005', 'dmy', [], 1, [qw(19-1-2005 19 1 2005)]],
              ['19 1 2005', 'dmy', [], 1, [q(19 1 2005), qw(19 1 2005)]],
              ['19x1x2005', 'dmy', [], 0, ],
              ['1912005',   'dmy', [], 0, ],
              # one-digit day
              ['9/10/2005', 'dmy', [], 1, [qw(9/10/2005 9 10 2005)]],
              ['9.10.2005', 'dmy', [], 1, [qw(9.10.2005 9 10 2005)]],
              ['9-10-2005', 'dmy', [], 1, [qw(9-10-2005 9 10 2005)]],
              ['9x10x2005', 'dmy', [], 0, ],
              ['9102005',   'dmy', [], 0, ],
              ['9101205',   'dmy', [], 0, ],
              # one-digit month and day
              ['9/1/2005', 'dmy', [], 1, [qw(9/1/2005 9 1 2005)]],
              ['9.1.2005', 'dmy', [], 1, [qw(9.1.2005 9 1 2005)]],
              ['9-1-2005', 'dmy', [], 1, [qw(9-1-2005 9 1 2005)]],
              ['9x1x2005', 'dmy', [], 0, ],
              ['912005',   'dmy', [], 0, ],
              # dd/m/yy
              ['19/1/05', 'dmy', [], 1, [qw(19/1/05 19 1 05)]],
              ['19.1.05', 'dmy', [], 1, [qw(19.1.05 19 1 05)]],
              ['19-1-05', 'dmy', [], 1, [qw(19-1-05 19 1 05)]],
              ['19x1x05', 'dmy', [], 0, ],
              ['19105',   'dmy', [], 0, ],
              # d/mm/yy
              ['9/10/05', 'dmy', [], 1, [qw(9/10/05 9 10 05)]],
              ['9.10.05', 'dmy', [], 1, [qw(9.10.05 9 10 05)]],
              ['9-10-05', 'dmy', [], 1, [qw(9-10-05 9 10 05)]],
              ['9x10x05', 'dmy', [], 0, ],
              ['91005',   'dmy', [], 0, ],
              # d/m/yy
              ['9/1/05', 'dmy', [], 1, [qw(9/1/05 9 1 05)]],
              ['9.1.05', 'dmy', [], 1, [qw(9.1.05 9 1 05)]],
              ['9-1-05', 'dmy', [], 1, [qw(9-1-05 9 1 05)]],
              ['9x1x05', 'dmy', [], 0, ],
              ['9105',   'dmy', [], 0, ],
              # Invalid month
              ['19/13/2005', 'dmy', [], 0, ],
              ['19/21/2005', 'dmy', [], 0, ],
              ['19/0/2005',  'dmy', [], 0, ],
              ['19/00/2005', 'dmy', [], 0, ],
              # Invalid day
              ['0/12/2005', 'dmy',  [], 0, ],
              ['00/12/2005', 'dmy', [], 0, ],
              ['40/12/2005', 'dmy', [], 0, ],
              ['32/12/2005', 'dmy', [], 0, ],

# dmy4 tests.  Mostly the same as above.
              ['19/10/2005', 'dmy4', [], 1, [qw(19/10/2005 19 10 2005)]],
              ['19.10.2005', 'dmy4', [], 1, [qw(19.10.2005 19 10 2005)]],
              ['19-10-2005', 'dmy4', [], 1, [qw(19-10-2005 19 10 2005)]],
              ['19x10x2005', 'dmy4', [], 0, ],
              ['19102005',   'dmy4', [], 1, [qw(19102005   19 10 2005)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc19/10/2005000', 'dmy4', [], 1, [qw(19/10/2005 19 10 2005)]],
              ['abc19.10.2005xyz', 'dmy4', [], 1, [qw(19.10.2005 19 10 2005)]],
              ['abc19-10-2005xyz', 'dmy4', [], 1, [qw(19-10-2005 19 10 2005)]],
              ['abc19x10x2005xyz', 'dmy4', [], 0, ],
              ['abc19102005000',   'dmy4', [], 1, [qw(19102005   19 10 2005)]],
              # However, leading digits will cause loose d to fail
              ['019/10/2005', 'dmy4', [], 0, ],
              # Two-year date should not match dmy4
              ['19/10/05', 'dmy4', [], 0, ],
              ['19.10.05', 'dmy4', [], 0, ],
              ['19-10-05', 'dmy4', [], 0, ],
              ['19x10x05', 'dmy4', [], 0, ],
              ['191005',   'dmy4', [], 0, ],
              # separators
              ['19:10:2005', 'dmy4', [],  0, ],
              ['19 10 2005', 'dmy4', [],  1, [ q(19 10 2005), qw(19 10 2005)]],
              ['19*10*2005', 'dmy4', [],  0, ],
              ['19?10?2005', 'dmy4', [],  0, ],
              # one-digit month
              ['19/1/2005', 'dmy4', [], 1, [qw(19/1/2005 19 1 2005)]],
              ['19.1.2005', 'dmy4', [], 1, [qw(19.1.2005 19 1 2005)]],
              ['19-1-2005', 'dmy4', [], 1, [qw(19-1-2005 19 1 2005)]],
              ['19x1x2005', 'dmy4', [], 0, ],
              ['1912005',   'dmy4', [], 0, ],
              # one-digit day
              ['9/10/2005', 'dmy4', [], 1, [qw(9/10/2005 9 10 2005)]],
              ['9.10.2005', 'dmy4', [], 1, [qw(9.10.2005 9 10 2005)]],
              ['9-10-2005', 'dmy4', [], 1, [qw(9-10-2005 9 10 2005)]],
              ['9x10x2005', 'dmy4', [], 0, ],
              ['9102005',   'dmy4', [], 0, ],
              # one-digit month and day
              ['9/1/2005', 'dmy4', [], 1, [qw(9/1/2005 9 1 2005)]],
              ['9.1.2005', 'dmy4', [], 1, [qw(9.1.2005 9 1 2005)]],
              ['9-1-2005', 'dmy4', [], 1, [qw(9-1-2005 9 1 2005)]],
              ['9x1x2005', 'dmy4', [], 0, ],
              ['912005',   'dmy4', [], 0, ],
              # dd/m/yy
              ['19/1/05', 'dmy4', [], 0, ],
              ['19.1.05', 'dmy4', [], 0, ],
              ['19-1-05', 'dmy4', [], 0, ],
              ['19x1x05', 'dmy4', [], 0, ],
              ['19105',   'dmy4', [], 0, ],
              # d/mm/yy
              ['9/10/05', 'dmy4', [], 0, ],
              ['9.10.05', 'dmy4', [], 0, ],
              ['9-10-05', 'dmy4', [], 0, ],
              ['9x10x05', 'dmy4', [], 0, ],
              ['91005',   'dmy4', [], 0, ],
              # d/m/yy
              ['9/1/05', 'dmy4', [], 0, ],
              ['9.1.05', 'dmy4', [], 0, ],
              ['9-1-05', 'dmy4', [], 0, ],
              ['9x1x05', 'dmy4', [], 0, ],
              ['9105',   'dmy4', [], 0, ],
              # Invalid month
              ['19/13/2005', 'dmy4', [], 0, ],
              ['19/21/2005', 'dmy4', [], 0, ],
              ['19/0/2005',  'dmy4', [], 0, ],
              ['19/00/2005', 'dmy4', [], 0, ],
              # Invalid day
              ['0/12/2005', 'dmy4',  [], 0, ],
              ['00/12/2005', 'dmy4', [], 0, ],
              ['40/12/2005', 'dmy4', [], 0, ],
              ['32/12/2005', 'dmy4', [], 0, ],

# dmy2 tests
              ['19/10/2005', 'dmy2', [], 1, [qw(19/10/20   19 10 20)]],
              ['19.10.2005', 'dmy2', [], 1, [qw(19.10.20   19 10 20)]],
              ['19-10-2005', 'dmy2', [], 1, [qw(19-10-20   19 10 20)]],
              ['19x10x2005', 'dmy2', [], 0, ],
              ['19102005',   'dmy2', [], 1, [qw(191020     19 10 20)]],
              # Trailing digits will NOT cause y2 to fail
              ['abc191005000',   'dmy2', [], 1, [qw(191005   19 10 05)]],
              ['abc191005xyz',   'dmy2', [], 1, [qw(191005   19 10 05)]],
              # Leading digits WILL cause loose d to fail
              ['abc191005',   'dmy2', [], 1, [qw(191005   19 10 05)]],
              ['000191005',   'dmy2', [], 0, ],
              ['0191005',   'dmy2', [], 0, ],
              # Two-year date should match dmy2
              ['19/10/05', 'dmy2', [], 1, [qw(19/10/05     19 10 05)]],
              ['19.10.05', 'dmy2', [], 1, [qw(19.10.05     19 10 05)]],
              ['19-10-05', 'dmy2', [], 1, [qw(19-10-05     19 10 05)]],
              ['19x10x05', 'dmy2', [], 0, ],
              ['191005',   'dmy2', [], 1, [qw(191005       19 10 05)]],
              # separators
              ['19:10:05', 'dmy2', [],  0, ],
              ['19 10 05', 'dmy2', [],  1, [ q(19 10 05), qw(19 10 05)]],
              ['19*10*05', 'dmy2', [],  0, ],
              ['19x10x05', 'dmy2', [],  0, ],
              ['191005',   'dmy2', [],  1, [qw(191005        19 10 05)]],
              # one-digit month
              ['19/1/05', 'dmy2', [], 1, [qw(19/1/05 19 1 05)]],
              ['19.1.05', 'dmy2', [], 1, [qw(19.1.05 19 1 05)]],
              ['19-1-05', 'dmy2', [], 1, [qw(19-1-05 19 1 05)]],
              ['19x1x05', 'dmy2', [], 0, ],
              ['19105',   'dmy2', [], 0, ],
              # one-digit day
              ['9/10/05', 'dmy2', [], 1, [qw(9/10/05 9 10 05)]],
              ['9.10.05', 'dmy2', [], 1, [qw(9.10.05 9 10 05)]],
              ['9-10-05', 'dmy2', [], 1, [qw(9-10-05 9 10 05)]],
              ['9x10x05', 'dmy2', [], 0, ],
              ['91005',   'dmy2', [], 0, ],
              # one-digit month and day
              ['9/1/05', 'dmy2', [], 1, [qw(9/1/05 9 1 05)]],
              ['9.1.05', 'dmy2', [], 1, [qw(9.1.05 9 1 05)]],
              ['9-1-05', 'dmy2', [], 1, [qw(9-1-05 9 1 05)]],
              ['9x1x05', 'dmy2', [], 0, ],
              ['9105',   'dmy2', [], 0, ],
              # dd/m/yyyy
              ['19/1/2005', 'dmy2', [], 1, [qw(19/1/20   19 1 20)]],
              ['19.1.2005', 'dmy2', [], 1, [qw(19.1.20   19 1 20)]],
              ['19-1-2005', 'dmy2', [], 1, [qw(19-1-20   19 1 20)]],
              ['19x1x2005', 'dmy2', [], 0, ],
              ['1912005',   'dmy2', [], 1, [qw(191200    19 12 00)]],
              # d/mm/yyyy
              ['9/10/2005', 'dmy2', [], 1, [qw(9/10/20   9 10 20)]],
              ['9.10.2005', 'dmy2', [], 1, [qw(9.10.20   9 10 20)]],
              ['9-10-2005', 'dmy2', [], 1, [qw(9-10-20   9 10 20)]],
              ['9x10x2005', 'dmy2', [], 0, ],
              ['9102005',   'dmy2', [], 0, ],
              ['9101205',   'dmy2', [], 0, ],
              # d/m/yyyy
              ['9/1/2005', 'dmy2', [], 1, [qw(9/1/20   9 1 20)]],
              ['9.1.2005', 'dmy2', [], 1, [qw(9.1.20   9 1 20)]],
              ['9-1-2005', 'dmy2', [], 1, [qw(9-1-20   9 1 20)]],
              ['9x1x2005', 'dmy2', [], 0, ],
              ['912005',   'dmy2', [], 0, ],
              # Invalid month
              ['19/13/05', 'dmy2', [], 0, ],
              ['19/21/05', 'dmy2', [], 0, ],
              ['19/0/05',  'dmy2', [], 0, ],
              ['19/00/05', 'dmy2', [], 0, ],
              # Invalid day
              ['0/12/05',  'dmy2', [], 0, ],
              ['00/12/05', 'dmy2', [], 0, ],
              ['40/12/05', 'dmy2', [], 0, ],
              ['32/12/05', 'dmy2', [], 0, ],

# d2m2y4 tests
              ['19/10/2005', 'd2m2y4', [], 1, [qw(19/10/2005 19 10 2005)]],
              ['19.10.2005', 'd2m2y4', [], 1, [qw(19.10.2005 19 10 2005)]],
              ['19-10-2005', 'd2m2y4', [], 1, [qw(19-10-2005 19 10 2005)]],
              ['19x10x2005', 'd2m2y4', [], 0, ],
              ['19102005',   'd2m2y4', [], 1, [qw(19102005   19 10 2005)]],
              # leading/trailing junk shouldn't cause the match to change
              ['abc19/10/2005000', 'd2m2y4', [], 1, [qw(19/10/2005 19 10 2005)]],
              ['abc19.10.2005000', 'd2m2y4', [], 1, [qw(19.10.2005 19 10 2005)]],
              ['00019-10-2005xyz', 'd2m2y4', [], 1, [qw(19-10-2005 19 10 2005)]],
              ['abc19x10x2005000', 'd2m2y4', [], 0, ],
              ['abc19102005000',   'd2m2y4', [], 1, [qw(19102005   19 10 2005)]],
              # Two-year date should not match
              ['19/10/05', 'd2m2y4', [], 0, ],
              ['19.10.05', 'd2m2y4', [], 0, ],
              ['19-10-05', 'd2m2y4', [], 0, ],
              ['19x10x05', 'd2m2y4', [], 0, ],
              ['191005',   'd2m2y4', [], 0, ],
              # separators
              ['19:10:2005', 'd2m2y4', [],  0, ],
              ['19*10*2005', 'd2m2y4', [],  0, ],
              ['19?10?2005', 'd2m2y4', [],  0, ],
              ['19x10x2005', 'd2m2y4', [],  0, ],
              # one-digit month
              ['19/1/2005', 'd2m2y4', [], 0, ],
              ['19.1.2005', 'd2m2y4', [], 0, ],
              ['19-1-2005', 'd2m2y4', [], 0, ],
              ['19x1x2005', 'd2m2y4', [], 0, ],
              ['1912005',   'd2m2y4', [], 0, ],
              # one-digit day
              ['9/10/2005', 'd2m2y4', [], 0, ],
              ['9.10.2005', 'd2m2y4', [], 0, ],
              ['9-10-2005', 'd2m2y4', [], 0, ],
              ['9x10x2005', 'd2m2y4', [], 0, ],
              ['9102005',   'd2m2y4', [], 0, ],
              # one-digit month and day
              ['9/1/2005', 'd2m2y4', [], 0, ],
              ['9.1.2005', 'd2m2y4', [], 0, ],
              ['9-1-2005', 'd2m2y4', [], 0, ],
              ['9x1x2005', 'd2m2y4', [], 0, ],
              ['912005',   'd2m2y4', [], 0, ],
              # m/dd/yy
              ['19/1/05', 'd2m2y4', [], 0, ],
              ['19.1.05', 'd2m2y4', [], 0, ],
              ['19-1-05', 'd2m2y4', [], 0, ],
              ['19x1x05', 'd2m2y4', [], 0, ],
              ['19105',   'd2m2y4', [], 0, ],
              # mm/d/yy
              ['9/10/05', 'd2m2y4', [], 0, ],
              ['9.10.05', 'd2m2y4', [], 0, ],
              ['9-10-05', 'd2m2y4', [], 0, ],
              ['9x10x05', 'd2m2y4', [], 0, ],
              ['91005',   'd2m2y4', [], 0, ],
              # m/d/yy
              ['9/1/05', 'd2m2y4', [], 0, ],
              ['9.1.05', 'd2m2y4', [], 0, ],
              ['9-1-05', 'd2m2y4', [], 0, ],
              ['9x1x05', 'd2m2y4', [], 0, ],
              ['9105',   'd2m2y4', [], 0, ],
              # Invalid month
              ['19/13/2005', 'd2m2y4', [], 0, ],
              ['19/21/2005', 'd2m2y4', [], 0, ],
              ['19/0/2005',  'd2m2y4', [], 0, ],
              ['19/00/2005', 'd2m2y4', [], 0, ],
              # Invalid day
              ['0/12/2005',  'd2m2y4', [], 0, ],
              ['00/12/2005', 'd2m2y4', [], 0, ],
              ['40/12/2005', 'd2m2y4', [], 0, ],
              ['32/12/2005', 'd2m2y4', [], 0, ],

# d2m2y2 tests
              ['19/10/2005', 'd2m2y2', [], 1, [qw(19/10/20 19 10 20)]],
              ['19.10.2005', 'd2m2y2', [], 1, [qw(19.10.20 19 10 20)]],
              ['19-10-2005', 'd2m2y2', [], 1, [qw(19-10-20 19 10 20)]],
              ['19x10x2005', 'd2m2y2', [], 0, ],
              ['19102005',   'd2m2y2', [], 1, [qw(191020   19 10 20)]],
              # leading/trailing junk shouldn't cause the match to change
              # Not even trailing digits, since we're specifying y2.
              ['abc19/10/2005000', 'd2m2y2', [], 1, [qw(19/10/20 19 10 20)]],
              ['0019102005xyz',    'd2m2y2', [], 1, [qw(191020 19 10 20)]],
              ['abc191005abc',     'd2m2y2', [], 1, [qw(191005 19 10 05)]],
              # Two-year date should match
              ['19/10/05', 'd2m2y2', [], 1, [qw(19/10/05 19 10 05)]],
              ['19.10.05', 'd2m2y2', [], 1, [qw(19.10.05 19 10 05)]],
              ['19-10-05', 'd2m2y2', [], 1, [qw(19-10-05 19 10 05)]],
              ['19x10x05', 'd2m2y2', [], 0, ],
              ['191005',   'd2m2y2', [], 1, [qw(191005   19 10 05)]],
              # separators
              ['19:10:05', 'd2m2y2', [],  0, ],
              ['19 10 05', 'd2m2y2', [],  1, [ q(19 10 05), qw(19 10 05)]],
              ['19?10?05', 'd2m2y2', [],  0, ],
              ['19x10x05', 'd2m2y2', [],  0, ],
              # Mismatched separators
              ['19/10 05', 'd2m2y2', [],  0, ],
              ['19-1005',  'd2m2y2', [],  0, ],
              ['19?10-05', 'd2m2y2', [],  0, ],
              ['19/10x05', 'd2m2y2', [],  0, ],
              # one-digit month
              ['19/1/2005', 'd2m2y2', [], 0, ],
              ['19.1.2005', 'd2m2y2', [], 0, ],
              ['19-1-2005', 'd2m2y2', [], 0, ],
              ['19x1x2005', 'd2m2y2', [], 0, ],
              ['1912005',   'd2m2y2', [], 1, [qw(191200 19 12 00)]],
              # one-digit day
              ['9/10/2005', 'd2m2y2', [], 0, ],
              ['9.10.2005', 'd2m2y2', [], 0, ],
              ['9-10-2005', 'd2m2y2', [], 0, ],
              ['9x10x2005', 'd2m2y2', [], 0, ],
              ['9102005',   'd2m2y2', [], 0, ],
              ['9102005',   'd2m2y2', [], 0, ],
              # one-digit month and day
              ['9/1/2005', 'd2m2y2', [], 0, ],
              ['9.1.2005', 'd2m2y2', [], 0, ],
              ['9-1-2005', 'd2m2y2', [], 0, ],
              ['9x1x2005', 'd2m2y2', [], 0, ],
              ['912005',   'd2m2y2', [], 0, ],
              ['912005',   'd2m2y2', [], 0, ],
              # m/dd/yy
              ['19/1/05', 'd2m2y2', [], 0, ],
              ['19.1.05', 'd2m2y2', [], 0, ],
              ['19-1-05', 'd2m2y2', [], 0, ],
              ['19x1x05', 'd2m2y2', [], 0, ],
              ['19105',   'd2m2y2', [], 0, ],
              ['19105',   'd2m2y2', [], 0, ],
              # mm/d/yy
              ['9/10/05', 'd2m2y2', [], 0, ],
              ['9.10.05', 'd2m2y2', [], 0, ],
              ['9-10-05', 'd2m2y2', [], 0, ],
              ['9x10x05', 'd2m2y2', [], 0, ],
              ['91005',   'd2m2y2', [], 0, ],
              # m/d/yy
              ['9/1/05', 'd2m2y2', [], 0, ],
              ['9.1.05', 'd2m2y2', [], 0, ],
              ['9-1-05', 'd2m2y2', [], 0, ],
              ['9x1x05', 'd2m2y2', [], 0, ],
              ['9105',   'd2m2y2', [], 0, ],
              # Invalid month
              ['19/13/05', 'd2m2y2', [], 0, ],
              ['19/21/05', 'd2m2y2', [], 0, ],
              ['19/0/05',  'd2m2y2', [], 0, ],
              ['19/00/05', 'd2m2y2', [], 0, ],
              # Invalid day
              ['0/12/05',  'd2m2y2', [], 0, ],
              ['00/12/05', 'd2m2y2', [], 0, ],
              ['40/12/05', 'd2m2y2', [], 0, ],
              ['32/12/05', 'd2m2y2', [], 0, ],

# month name tests
              # Basic test case
              ["01 $Jan 2005",       "dmy", [], 1, ["01 $Jan 2005",      '01', $Jan, '2005']],
              # 2-digit year
              ["01 $Jan 05",         "dmy", [], 1, ["01 $Jan 05",        '01', $Jan, '05']],
              # odd number of digits in year
              [   "01 $Jan 9",       "dmy", [], 0, ],
              [ "01 $Jan 120",       "dmy", [], 0, ],
              [ "01 $Jan 20051",     "dmy", [], 0, ],
              # Leading/trailing junk
              ["abc01 $Jan 05",      "dmy", [], 1, ["01 $Jan 05",        '01', $Jan, '05']],
              ["01 $Jan 05xyz",      "dmy", [], 1, ["01 $Jan 05",        '01', $Jan, '05']],
              ["001 $Jan 05",        "dmy", [], 0, ],
              ["01 $Jan 050",        "dmy", [], 0, ],
              ["01 $Jan 20050",      "dmy", [], 0, ],
              # Name spelled out
              ["01 $January 2005",   "dmy", [], 1, ["01 $January 2005",   '01',  $January, 2005]],
              # Partial name should fail
              ["01 ${Jan}u 2005",    "dmy", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              [ "1 $February 2005",  "dmy", [], 1, [ "1 $February 2005",   '1', $February , 2005]],
              [ "2 $March 2005",     "dmy", [], 1, [ "2 $March 2005",      '2', $March    , 2005]],
              ["09 $April 2005",     "dmy", [], 1, ["09 $April 2005",     '09', $April    , 2005]],
              [ "9 $MayFull 2005",   "dmy", [], 1, [ "9 $MayFull 2005",        '9', $MayFull      , 2005]],
              ["10 $June 2005",      "dmy", [], 1, ["10 $June 2005",      '10', $June     , 2005]],
              ["11 $July 2005",      "dmy", [], 1, ["11 $July 2005",      '11', $July     , 2005]],
              ["19 $August 2005",    "dmy", [], 1, ["19 $August 2005",    '19', $August   , 2005]],
              ["20 $September 2005", "dmy", [], 1, ["20 $September 2005", '20', $September, 2005]],
              ["21 $October 2005",   "dmy", [], 1, ["21 $October 2005",   '21', $October  , 2005]],
              ["30 $November 2005",  "dmy", [], 1, ["30 $November 2005",  '30', $November , 2005]],
              ["31 $December 2005",  "dmy", [], 1, ["31 $December 2005",  '31', $December , 2005]],
              [ "1 $Feb 2005",       "dmy", [], 1, [ "1 $Feb 2005",        '1', $Feb, 2005]],
              [ "2 $Mar 2005",       "dmy", [], 1, [ "2 $Mar 2005",        '2', $Mar, 2005]],
              ["09 $Apr 2005",       "dmy", [], 1, ["09 $Apr 2005",       '09', $Apr, 2005]],
              [ "9 $MayFull 2005",       "dmy", [], 1, [ "9 $MayFull 2005",        '9', $MayFull, 2005]],
              ["10 $Jun 2005",       "dmy", [], 1, ["10 $Jun 2005",       '10', $Jun, 2005]],
              ["11 $Jul 2005",       "dmy", [], 1, ["11 $Jul 2005",       '11', $Jul, 2005]],
              ["19 $Aug 2005",       "dmy", [], 1, ["19 $Aug 2005",       '19', $Aug, 2005]],
              ["20 $Sep 2005",       "dmy", [], 1, ["20 $Sep 2005",       '20', $Sep, 2005]],
              ["21 $Oct 2005",       "dmy", [], 1, ["21 $Oct 2005",       '21', $Oct, 2005]],
              ["30 $Nov 2005",       "dmy", [], 1, ["30 $Nov 2005",       '30', $Nov, 2005]],
              ["31 $Dec 2005",       "dmy", [], 1, ["31 $Dec 2005",       '31', $Dec, 2005]],
              # Case insensitivity
              ["01 \L$Jan 2005",     "dmy", [], 1, ["01 \L$Jan 2005",     qw(01), lc($Jan), 2005]],
              ["01 \U\l$Jan 2005",   "dmy", [], 1, ["01 \U\l$Jan 2005",   qw(01), lcfirst(uc($Jan)), 2005]],
              # Alternate separators
              ["01:$Jan:2005",      "dmy", [], 0, ],
              ["01-$Jan-2005",      "dmy", [], 1, ["01-$Jan-2005",       '01', $Jan, '2005']],
              ["01.$Jan.2005",      "dmy", [], 1, ["01.$Jan.2005",       '01', $Jan, '2005']],
              # Schmutz before/after the date
              ["01 blah$Jan 2005",   "dmy", [], 0, ],
              ["01 $Jan 2005blah",   "dmy", [], 1, ["01 $Jan 2005",       '01', $Jan, '2005']],
              # Bad separator
              ["01 $Jan   2005",  "dmy", [], 0, ],
              # Bad day
              ["00 $Jan 2005",       "dmy", [], 0, ],
              [ "0 $Jan 2005",       "dmy", [], 0, ],
              ["32 $Jan 2005",       "dmy", [], 0, ],
              ["40 $Jan 2005",       "dmy", [], 0, ],
              ["99 $Jan 2005",       "dmy", [], 0, ],

# month name tests
              # Basic test case
              ["01 $Jan 2005",       "dmy4", [], 1, ["01 $Jan 2005",      '01', $Jan, '2005']],
              # 2-digit year
              ["01 $Jan 05",         "dmy4", [], 0, ],
              # odd number of digits in year
              [   "01 $Jan 9",       "dmy4", [], 0, ],
              [ "01 $Jan 120",       "dmy4", [], 0, ],
              [ "01 $Jan 20051",     "dmy4", [], 1, ["01 $Jan 2005",      '01', $Jan, '2005']],
              # Leading/trailing junk
              ["abc01 $Jan 2005",    "dmy4", [], 1, ["01 $Jan 2005",      '01', $Jan, '2005']],
              ["01 $Jan 2005xyz",    "dmy4", [], 1, ["01 $Jan 2005",      '01', $Jan, '2005']],
              ["001 $Jan 2005",      "dmy4", [], 0, ],
              ["01 $Jan 20050",      "dmy4", [], 1, ["01 $Jan 2005",      '01', $Jan, '2005']],
              # Name spelled out
              ["01 $January 2005",   "dmy4", [], 1, ["01 $January 2005",   '01', $January, '2005']],
              # Partial name should fail
              ["01 ${Jan}u 2005",    "dmy4", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              [ "1 $February 2005",  "dmy4", [], 1, [ "1 $February 2005",  '1', $February, '2005']],
              [ "2 $March 2005",     "dmy4", [], 1, [ "2 $March 2005",     '2', $March, '2005']],
              ["09 $April 2005",     "dmy4", [], 1, ["09 $April 2005",     '09', $April, '2005']],
              [ "9 $MayFull 2005",       "dmy4", [], 1, [ "9 $MayFull 2005",       '9', $MayFull, '2005']],
              ["10 $June 2005",      "dmy4", [], 1, ["10 $June 2005",      '10', $June, '2005']],
              ["11 $July 2005",      "dmy4", [], 1, ["11 $July 2005",      '11', $July, '2005']],
              ["19 $August 2005",    "dmy4", [], 1, ["19 $August 2005",    '19', $August, '2005']],
              ["20 $September 2005", "dmy4", [], 1, ["20 $September 2005", '20', $September, '2005']],
              ["21 $October 2005",   "dmy4", [], 1, ["21 $October 2005",   '21', $October, '2005']],
              ["30 $November 2005",  "dmy4", [], 1, ["30 $November 2005",  '30', $November, '2005']],
              ["31 $December 2005",  "dmy4", [], 1, ["31 $December 2005",  '31', $December, '2005']],
              [ "1 $Feb 2005",       "dmy4", [], 1, [ "1 $Feb 2005",       '1', $Feb, '2005']],
              [ "2 $Mar 2005",       "dmy4", [], 1, [ "2 $Mar 2005",       '2', $Mar, '2005']],
              ["09 $Apr 2005",       "dmy4", [], 1, ["09 $Apr 2005",       '09', $Apr, '2005']],
              [ "9 $MayFull 2005",       "dmy4", [], 1, [ "9 $MayFull 2005",       '9', $MayFull, '2005']],
              ["10 $Jun 2005",       "dmy4", [], 1, ["10 $Jun 2005",       '10', $Jun, '2005']],
              ["11 $Jul 2005",       "dmy4", [], 1, ["11 $Jul 2005",       '11', $Jul, '2005']],
              ["19 $Aug 2005",       "dmy4", [], 1, ["19 $Aug 2005",       '19', $Aug, '2005']],
              ["20 $Sep 2005",       "dmy4", [], 1, ["20 $Sep 2005",       '20', $Sep, '2005']],
              ["21 $Oct 2005",       "dmy4", [], 1, ["21 $Oct 2005",       '21', $Oct, '2005']],
              ["30 $Nov 2005",       "dmy4", [], 1, ["30 $Nov 2005",       '30', $Nov, '2005']],
              ["31 $Dec 2005",       "dmy4", [], 1, ["31 $Dec 2005",       '31', $Dec, '2005']],
              # Case insensitivity
              ["01 \L$Jan 2005",     "dmy4", [], 1, ["01 \L$Jan 2005",     '01', lc($Jan), '2005']],
              ["01 \U\l$Jan 2005",   "dmy4", [], 1, ["01 \U\l$Jan 2005",   '01', lcfirst(uc($Jan)), '2005']],
              # Alternate separators
              ["01:$Jan:2005",      "dmy4", [], 0, ],
              ["01-$Jan-2005",      "dmy4", [], 1, ["01-$Jan-2005",        '01', $Jan, '2005']],
              ["01.$Jan.2005",      "dmy4", [], 1, ["01.$Jan.2005",        '01', $Jan, '2005']],
              # Schmutz before/after the date
              ["01 blah$Jan 2005",   "dmy4", [], 0, ],
              ["01 $Jan 2005blah",   "dmy4", [], 1, ["01 $Jan 2005",       '01', $Jan, '2005']],
              # Bad separator
              ["01 $Jan   2005",  "dmy4", [], 0, ],
              # Bad day
              ["00 $Jan 2005",       "dmy4", [], 0, ],
              [ "0 $Jan 2005",       "dmy4", [], 0, ],
              ["32 $Jan 2005",       "dmy4", [], 0, ],
              ["40 $Jan 2005",       "dmy4", [], 0, ],
              ["99 $Jan 2005",       "dmy4", [], 0, ],

# month name tests
              # Basic test case
              ["01 $Jan 2005",       "dmy2", [], 1, ["01 $Jan 20",      '01', $Jan, '20']],
              # 2-digit year
              ["01 $Jan 05",         "dmy2", [], 1, ["01 $Jan 05",      '01', $Jan, '05']],
              # odd number of digits in year
              [   "01 $Jan 9",       "dmy2", [], 0, ],
              [ "01 $Jan 120",       "dmy2", [], 1, ["01 $Jan 12",      '01', $Jan, '12']],
              # Leading/trailing junk
              ["abc01 $Jan 05",      "dmy2", [], 1, ["01 $Jan 05",      '01', $Jan, '05']],
              ["01 $Jan 05xyz",      "dmy2", [], 1, ["01 $Jan 05",      '01', $Jan, '05']],
              ["001 $Jan 05",        "dmy2", [], 0, ],
              ["01 $Jan 050",        "dmy2", [], 1, ["01 $Jan 05",      '01', $Jan, '05']],
              # Name spelled out
              ["01 $January 05",   "dmy2", [], 1, ["01 $January 05",   '01', $January, '05']],
              # Partial name should fail
              ["01 ${Jan}u 05",    "dmy2", [], 0, ],
              # All twelve names (and abbreviations)  Also valid day formats.
              [ "1 $February 05",  "dmy2", [], 1, [ "1 $February 05",   '1', $February, '05']],
              [ "2 $March 05",     "dmy2", [], 1, [ "2 $March 05",      '2', $March, '05']],
              ["09 $April 05",     "dmy2", [], 1, ["09 $April 05",     '09', $April, '05']],
              [ "9 $MayFull 05",       "dmy2", [], 1, [ "9 $MayFull 05",        '9', $MayFull, '05']],
              ["10 $June 05",      "dmy2", [], 1, ["10 $June 05",      '10', $June, '05']],
              ["11 $July 05",      "dmy2", [], 1, ["11 $July 05",      '11', $July, '05']],
              ["19 $August 05",    "dmy2", [], 1, ["19 $August 05",    '19', $August, '05']],
              ["20 $September 05", "dmy2", [], 1, ["20 $September 05", '20', $September, '05']],
              ["21 $October 05",   "dmy2", [], 1, ["21 $October 05",   '21', $October, '05']],
              ["30 $November 05",  "dmy2", [], 1, ["30 $November 05",  '30', $November, '05']],
              ["31 $December 05",  "dmy2", [], 1, ["31 $December 05",  '31', $December, '05']],
              [ "1 $Feb 05",       "dmy2", [], 1, [ "1 $Feb 05",        '1', $Feb, '05']],
              [ "2 $Mar 05",       "dmy2", [], 1, [ "2 $Mar 05",        '2', $Mar, '05']],
              ["09 $Apr 05",       "dmy2", [], 1, ["09 $Apr 05",       '09', $Apr, '05']],
              [ "9 $MayFull 05",       "dmy2", [], 1, [ "9 $MayFull 05",        '9', $MayFull, '05']],
              ["10 $Jun 05",       "dmy2", [], 1, ["10 $Jun 05",       '10', $Jun, '05']],
              ["11 $Jul 05",       "dmy2", [], 1, ["11 $Jul 05",       '11', $Jul, '05']],
              ["19 $Aug 05",       "dmy2", [], 1, ["19 $Aug 05",       '19', $Aug, '05']],
              ["20 $Sep 05",       "dmy2", [], 1, ["20 $Sep 05",       '20', $Sep, '05']],
              ["21 $Oct 05",       "dmy2", [], 1, ["21 $Oct 05",       '21', $Oct, '05']],
              ["30 $Nov 05",       "dmy2", [], 1, ["30 $Nov 05",       '30', $Nov, '05']],
              ["31 $Dec 05",       "dmy2", [], 1, ["31 $Dec 05",       '31', $Dec, '05']],
              # Case insensitivity
              ["01 \L$Jan 05",     "dmy2", [], 1, ["01 \L$Jan 05",     '01', lc($Jan), '05']],
              ["01 \U\l$Jan 05",   "dmy2", [], 1, ["01 \U\l$Jan 05",   '01', lcfirst(uc($Jan)), '05']],
              # Alternate separators
              ["01:$Jan:05",      "dmy2", [], 0, ],
              ["01-$Jan-05",      "dmy2", [], 1, ["01-$Jan-05",       '01', $Jan, '05']],
              ["01.$Jan.05",      "dmy2", [], 1, ["01.$Jan.05",       '01', $Jan, '05']],
              # Schmutz before/after the date
              ["01 blah$Jan 05",   "dmy2", [], 0, ],
              ["01 $Jan 05blah",   "dmy2", [], 1, ["01 $Jan 05",       '01', $Jan, '05']],
              # Bad separator
              ["01 $Jan   05",  "dmy2", [], 0, ],
              # Bad day
              ["00 $Jan 05",       "dmy2", [], 0, ],
              [ "0 $Jan 05",       "dmy2", [], 0, ],
              ["32 $Jan 05",       "dmy2", [], 0, ],
              ["40 $Jan 05",       "dmy2", [], 0, ],
              ["99 $Jan 05",       "dmy2", [], 0, ],

             );

    # DMY is an exact synonym for d2m2y4
    my @DMY = grep { $_->[1] eq 'd2m2y4' } @match;
    $_->[1] = 'DMY' for @DMY;
    push @match, @DMY;

    # How many matches will succeed?
    my $to_succeed = scalar grep $_->[3], @match;

    # Run two tests per match, plus two additional per expected success
    $num_tests = 2 * scalar(@match)  +  2 * $to_succeed;
}

use Test::More tests => $num_tests;

diag $January;
diag $February;
diag $March;
diag $April;
diag $MayFull;
diag $June;
diag $July;
diag $August;
diag $September;
diag $October;
diag $November;
diag $December;
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
