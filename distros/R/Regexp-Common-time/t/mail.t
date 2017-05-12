use strict;
use warnings;
my (@match, $num_tests);

BEGIN
{
    @match = (
              # RFC-2822 (mail format) tests
              # Base case
              ['28 Mar 2008 01:02:03 +0600', 'mail', [], 1, [qq(28 Mar 2008 01:02:03 +0600), qw(28 Mar 2008 01 02 03 +0600)]],

              # 11 other months, plus some fun timezone variants.
              ['28 Jan 2008 01:02:03 +0600', 'mail', [], 1, [qq(28 Jan 2008 01:02:03 +0600), qw(28 Jan 2008 01 02 03 +0600)]],
              ['28 Feb 2008 01:02:03 -0600', 'mail', [], 1, [qq(28 Feb 2008 01:02:03 -0600), qw(28 Feb 2008 01 02 03 -0600)]],
              ['28 Apr 2008 01:02:03 +2300', 'mail', [], 1, [qq(28 Apr 2008 01:02:03 +2300), qw(28 Apr 2008 01 02 03 +2300)]],
              ['28 May 2008 01:02:03 -2300', 'mail', [], 1, [qq(28 May 2008 01:02:03 -2300), qw(28 May 2008 01 02 03 -2300)]],
              ['28 Jun 2008 01:02:03 +2359', 'mail', [], 1, [qq(28 Jun 2008 01:02:03 +2359), qw(28 Jun 2008 01 02 03 +2359)]],
              ['28 Jul 2008 01:02:03 -2359', 'mail', [], 1, [qq(28 Jul 2008 01:02:03 -2359), qw(28 Jul 2008 01 02 03 -2359)]],
              ['28 Aug 2008 01:02:03 EDT',   'mail', [], 1, [qq(28 Aug 2008 01:02:03 EDT),   qw(28 Aug 2008 01 02 03 EDT)]],
              ['28 Sep 2008 01:02:03 EST',   'mail', [], 1, [qq(28 Sep 2008 01:02:03 EST),   qw(28 Sep 2008 01 02 03 EST)]],
              ['28 Oct 2008 01:02:03 PDT',   'mail', [], 1, [qq(28 Oct 2008 01:02:03 PDT),   qw(28 Oct 2008 01 02 03 PDT)]],
              ['28 Nov 2008 01:02:03 PST',   'mail', [], 1, [qq(28 Nov 2008 01:02:03 PST),   qw(28 Nov 2008 01 02 03 PST)]],
              ['28 Dec 2008 01:02:03 Z',     'mail', [], 1, [qq(28 Dec 2008 01:02:03 Z),     qw(28 Dec 2008 01 02 03 Z)]],

              # Add weekday, as would be found in the typical case
              ['Wed, 28 Mar 2008 01:02:03 +0600', 'mail', [], 1, [qq(28 Mar 2008 01:02:03 +0600), qw(28 Mar 2008 01 02 03 +0600)]],

              # Two-digit years are allowed, though the standard frowns upon them.
              ['28 Dec 08 01:02:03 +0500',   'mail', [], 1, [qq(28 Dec 08 01:02:03 +0500),     qw(28 Dec 08 01 02 03 +0500)]],

              # Full month names should not match.  Except for "May"!
              ['28 January 2008 01:02:03 +0600',   'mail', [], 0, ],
              ['28 February 2008 01:02:03 +0600',  'mail', [], 0, ],
              ['28 March 2008 01:02:03 +0600',     'mail', [], 0, ],
              ['28 April 2008 01:02:03 +0600',     'mail', [], 0, ],
              ['28 June 2008 01:02:03 +0600',      'mail', [], 0, ],
              ['28 July 2008 01:02:03 +0600',      'mail', [], 0, ],
              ['28 August 2008 01:02:03 +0600',    'mail', [], 0, ],
              ['28 September 2008 01:02:03 +0600', 'mail', [], 0, ],
              ['28 October 2008 01:02:03 +0600',   'mail', [], 0, ],
              ['28 November 2008 01:02:03 +0600',  'mail', [], 0, ],
              ['28 December 2008 01:02:03 +0600',  'mail', [], 0, ],

              # Leading/trailing garbage variations
              ['128 Mar 2008 01:02:03 +0600', 'mail', [], 0, ],
              ['28 Mar 2008 01:02:03 +06000', 'mail', [], 0, ],
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
