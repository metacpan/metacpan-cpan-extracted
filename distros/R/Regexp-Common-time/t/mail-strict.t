use vars qw(@match $num_tests);

BEGIN
{
    @match = (
              # RFC-2822 (mail format) tests
              # Base case
              ['28 Mar 2008 01:02:03 +0600', 'MAIL', [], 1, [qq(28 Mar 2008 01:02:03 +0600), qw(28 Mar 2008 01 02 03 +0600)]],

              # 11 other months, plus some fun timezone variants.
              ['28 Jan 2008 01:02:03 +0600', 'MAIL', [], 1, [qq(28 Jan 2008 01:02:03 +0600), qw(28 Jan 2008 01 02 03 +0600)]],
              ['28 Feb 2008 01:02:03 -0600', 'MAIL', [], 1, [qq(28 Feb 2008 01:02:03 -0600), qw(28 Feb 2008 01 02 03 -0600)]],
              ['28 Apr 2008 01:02:03 +2300', 'MAIL', [], 1, [qq(28 Apr 2008 01:02:03 +2300), qw(28 Apr 2008 01 02 03 +2300)]],
              ['28 May 2008 01:02:03 -2300', 'MAIL', [], 1, [qq(28 May 2008 01:02:03 -2300), qw(28 May 2008 01 02 03 -2300)]],
              ['28 Jun 2008 01:02:03 +2359', 'MAIL', [], 1, [qq(28 Jun 2008 01:02:03 +2359), qw(28 Jun 2008 01 02 03 +2359)]],
              ['28 Jul 2008 01:02:03 -2359', 'MAIL', [], 1, [qq(28 Jul 2008 01:02:03 -2359), qw(28 Jul 2008 01 02 03 -2359)]],
              ['28 Aug 2008 01:02:03 +0300', 'MAIL', [], 1, [qq(28 Aug 2008 01:02:03 +0300), qw(28 Aug 2008 01 02 03 +0300)]],
              ['28 Sep 2008 01:02:03 +0300', 'MAIL', [], 1, [qq(28 Sep 2008 01:02:03 +0300), qw(28 Sep 2008 01 02 03 +0300)]],
              ['28 Oct 2008 01:02:03 +0300', 'MAIL', [], 1, [qq(28 Oct 2008 01:02:03 +0300), qw(28 Oct 2008 01 02 03 +0300)]],
              ['28 Nov 2008 01:02:03 +0300', 'MAIL', [], 1, [qq(28 Nov 2008 01:02:03 +0300), qw(28 Nov 2008 01 02 03 +0300)]],
              ['28 Dec 2008 01:02:03 +0300', 'MAIL', [], 1, [qq(28 Dec 2008 01:02:03 +0300), qw(28 Dec 2008 01 02 03 +0300)]],

              # Alphanumeric time zones are not permitted
              ['28 Aug 2008 01:02:03 EDT',   'MAIL', [], 0, ],
              ['28 Sep 2008 01:02:03 EST',   'MAIL', [], 0, ],
              ['28 Oct 2008 01:02:03 PDT',   'MAIL', [], 0, ],
              ['28 Nov 2008 01:02:03 PST',   'MAIL', [], 0, ],
              ['28 Dec 2008 01:02:03 Z',     'MAIL', [], 0, ],

              # Two-digit years are not permitted
              ['28 Dec 08 01:02:03 +0500',   'MAIL', [], 0, ],

              # Add weekday, as would be found in the typical case
              ['Wed, 28 Mar 2008 01:02:03 +0600', 'MAIL', [], 1, [qq(28 Mar 2008 01:02:03 +0600), qw(28 Mar 2008 01 02 03 +0600)]],

              # Full month names should not match.  Except for "May"!
              ['28 January 2008 01:02:03 +0600',   'MAIL', [], 0, ],
              ['28 February 2008 01:02:03 +0600',  'MAIL', [], 0, ],
              ['28 March 2008 01:02:03 +0600',     'MAIL', [], 0, ],
              ['28 April 2008 01:02:03 +0600',     'MAIL', [], 0, ],
              ['28 June 2008 01:02:03 +0600',      'MAIL', [], 0, ],
              ['28 July 2008 01:02:03 +0600',      'MAIL', [], 0, ],
              ['28 August 2008 01:02:03 +0600',    'MAIL', [], 0, ],
              ['28 September 2008 01:02:03 +0600', 'MAIL', [], 0, ],
              ['28 October 2008 01:02:03 +0600',   'MAIL', [], 0, ],
              ['28 November 2008 01:02:03 +0600',  'MAIL', [], 0, ],
              ['28 December 2008 01:02:03 +0600',  'MAIL', [], 0, ],

              # Leading/trailing garbage variations
              ['128 Mar 2008 01:02:03 +0600', 'MAIL', [], 0, ],
              ['28 Mar 2008 01:02:03 +06000', 'MAIL', [], 0, ],
             );

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
