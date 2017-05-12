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
              # Base case
              ["$March 23, 2008",      'american', [], 1, [qq($March 23, 2008), $March, qw(23 2008)]],

              # Short month name
              ["$Mar 23, 2008",        'american', [], 1, [qq($Mar 23, 2008),   $Mar,   qw(23 2008)]],

              # Bad month name.  I hope that "Blorxzt" isn't a real month name in any locale.
              ["Blorxzt 23, 2008",     'american', [], 0, ],

              # Year variations
              ["$Jan 12, 1900",        'american', [], 1, [qq($Jan 12, 1900),    $Jan,       qw(12 1900)]],
              ["$Jan 12, '00",         'american', [], 1, [qq($Jan 12, '00),     $Jan,       qw(12 '00)]],
              ["$January 12, 00",      'american', [], 1, [qq($January 12, 00),  $January,   qw(12 00)]],

              # All 12 months:
              ["$January 1, 2099",     'american', [], 1, [qq($January 1, 2099),    $January,     qw(1 2099)]],
              ["$February 2, 2098",    'american', [], 1, [qq($February 2, 2098),   $February,    qw(2 2098)]],
              ["$March 3, 2097",       'american', [], 1, [qq($March 3, 2097),      $March,       qw(3 2097)]],
              ["$April 4, 2096",       'american', [], 1, [qq($April 4, 2096),      $April,       qw(4 2096)]],
              ["$MayFull 5, 2095",     'american', [], 1, [qq($MayFull 5, 2095),    $MayFull,     qw(5 2095)]],
              ["$June 6, 2094",        'american', [], 1, [qq($June 6, 2094),       $June,        qw(6 2094)]],
              ["$July 7, 2093",        'american', [], 1, [qq($July 7, 2093),       $July,        qw(7 2093)]],
              ["$August 8, 2092",      'american', [], 1, [qq($August 8, 2092),     $August,      qw(8 2092)]],
              ["$September 9, 2091",   'american', [], 1, [qq($September 9, 2091),  $September,   qw(9 2091)]],
              ["$October 10, 2090",    'american', [], 1, [qq($October 10, 2090),   $October,     qw(10 2090)]],
              ["$November 11, '89",    'american', [], 1, [qq($November 11, '89),   $November,    qw(11 '89)]],
              ["$December 12, 87",     'american', [], 1, [qq($December 12, 87),    $December,    qw(12 87)]],

              # All 12 month abbreviations:
              ["$Jan 1, 2099",         'american', [], 1, [qq($Jan 1, 2099),   $Jan,   qw(1 2099)]],
              ["$Feb 2, 2098",         'american', [], 1, [qq($Feb 2, 2098),   $Feb,   qw(2 2098)]],
              ["$Mar 3, 2097",         'american', [], 1, [qq($Mar 3, 2097),   $Mar,   qw(3 2097)]],
              ["$Apr 4, 2096",         'american', [], 1, [qq($Apr 4, 2096),   $Apr,   qw(4 2096)]],
              ["$May 5, 2095",         'american', [], 1, [qq($May 5, 2095),   $May,   qw(5 2095)]],
              ["$Jun 6, 2094",         'american', [], 1, [qq($Jun 6, 2094),   $Jun,   qw(6 2094)]],
              ["$Jul 7, 2093",         'american', [], 1, [qq($Jul 7, 2093),   $Jul,   qw(7 2093)]],
              ["$Aug 8, 2092",         'american', [], 1, [qq($Aug 8, 2092),   $Aug,   qw(8 2092)]],
              ["$Sep 9, 2091",         'american', [], 1, [qq($Sep 9, 2091),   $Sep,   qw(9 2091)]],
              ["$Oct 10, 2090",        'american', [], 1, [qq($Oct 10, 2090),  $Oct,   qw(10 2090)]],
              ["$Nov 11, '89",         'american', [], 1, [qq($Nov 11, '89),   $Nov,   qw(11 '89)]],
              ["$Dec 12, 87",          'american', [], 1, [qq($Dec 12, 87),    $Dec,   qw(12 87)]],

              # Comma variations
              ["$MayFull 5, 2001",     'american', [], 1, [qq($MayFull 5, 2001),   $MayFull,   qw(5 2001)]],
              ["$MayFull 5 2001",      'american', [], 1, [qq($MayFull 5 2001),    $MayFull,   qw(5 2001)]],
              ["$MayFull 5  2001",     'american', [], 0, ],
              ["$MayFull 5,2001",      'american', [], 1, [qq($MayFull 5,2001),    $MayFull,   qw(5 2001)]],
              ["$MayFull 5 ,2001",     'american', [], 0, ],

              # Whitespace variations
              ["$Sep 9, 1945",         'american', [], 1, [qq($Sep 9, 1945),   $Sep,   qw(9 1945)]],
              ["${Sep}9, 1945",        'american', [], 0, ],
              ["$Sep  9, 1945",        'american', [], 1, [qq($Sep  9, 1945),  $Sep,   qw(9 1945)]],
              ["$Sep  19, 1945",       'american', [], 1, [qq($Sep  19, 1945), $Sep,   qw(19 1945)]],
              ["$Sep   9, 1945",       'american', [], 0, ],
              ["$Sep 9,  1945",        'american', [], 0, ],

              # Extraneous stuff before & after
              ["abcd$March 13, 2008",  'american', [], 0, ],
              ["0123$March 13, 2008",  'american', [], 0, ],
              ["$March 13, 200",       'american', [], 0, ],
              ["$March 13, 2008abcd",  'american', [], 1, [qq($March 13, 2008),   $March,   qw(13 2008)]],
              ["$March 13, 20080",     'american', [], 0, ],

             );

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
