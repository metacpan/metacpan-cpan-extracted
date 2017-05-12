use strict;
use warnings;
my (@match, $num_tests);

BEGIN
{
    @match = (
# hms tests.
              # Base case
              ['10:23:45am', 'hms', [], 1, [qw(10:23:45am 10 23 45 am)]],

              # am/pm variations
              ['10:23:45a',     'hms', [], 1, [q(10:23:45a),     qw(10 23 45 a)]],
              ['10:23:45am',    'hms', [], 1, [q(10:23:45am),    qw(10 23 45 am)]],
              ['10:23:45a.m.',  'hms', [], 1, [q(10:23:45a.m.),  qw(10 23 45 a.m.)]],
              ['10:23:45 a',    'hms', [], 1, [q(10:23:45 a),    qw(10 23 45 a)]],
              ['10:23:45 am',   'hms', [], 1, [q(10:23:45 am),   qw(10 23 45 am)]],
              ['10:23:45 a.m.', 'hms', [], 1, [q(10:23:45 a.m.), qw(10 23 45 a.m.)]],
              ['10:23:45p',     'hms', [], 1, [q(10:23:45p),     qw(10 23 45 p)]],
              ['10:23:45pm',    'hms', [], 1, [q(10:23:45pm),    qw(10 23 45 pm)]],
              ['10:23:45p.m.',  'hms', [], 1, [q(10:23:45p.m.),  qw(10 23 45 p.m.)]],
              ['10:23:45 p',    'hms', [], 1, [q(10:23:45 p),    qw(10 23 45 p)]],
              ['10:23:45 pm',   'hms', [], 1, [q(10:23:45 pm),   qw(10 23 45 pm)]],
              ['10:23:45 p.m.', 'hms', [], 1, [q(10:23:45 p.m.), qw(10 23 45 p.m.)]],
              ['10:23:45A',     'hms', [], 1, [q(10:23:45A),     qw(10 23 45 A)]],
              ['10:23:45AM',    'hms', [], 1, [q(10:23:45AM),    qw(10 23 45 AM)]],
              ['10:23:45A.M.',  'hms', [], 1, [q(10:23:45A.M.),  qw(10 23 45 A.M.)]],
              ['10:23:45 A',    'hms', [], 1, [q(10:23:45 A),    qw(10 23 45 A)]],
              ['10:23:45 AM',   'hms', [], 1, [q(10:23:45 AM),   qw(10 23 45 AM)]],
              ['10:23:45 A.M.', 'hms', [], 1, [q(10:23:45 A.M.), qw(10 23 45 A.M.)]],
              ['10:23:45P',     'hms', [], 1, [q(10:23:45P),     qw(10 23 45 P)]],
              ['10:23:45PM',    'hms', [], 1, [q(10:23:45PM),    qw(10 23 45 PM)]],
              ['10:23:45P.M.',  'hms', [], 1, [q(10:23:45P.M.),  qw(10 23 45 P.M.)]],
              ['10:23:45 P',    'hms', [], 1, [q(10:23:45 P),    qw(10 23 45 P)]],
              ['10:23:45 PM',   'hms', [], 1, [q(10:23:45 PM),   qw(10 23 45 PM)]],
              ['10:23:45 P.M.', 'hms', [], 1, [q(10:23:45 P.M.), qw(10 23 45 P.M.)]],
              # Separators
              ['10.23.45am', 'hms', [], 1, [qw(10.23.45am 10 23 45 am)]],
              ['10 23 45 am','hms', [], 1, [q(10 23 45 am), qw(10 23 45 am)]],
              ['10/23/45 am','hms', [], 0, ],
              # Hour boundaries
              ['0:23:45',  'hms', [], 1, [qw(0:23:45   0 23 45), undef]],
              ['1:23:45',  'hms', [], 1, [qw(1:23:45   1 23 45), undef]],
              ['12:23:45', 'hms', [], 1, [qw(12:23:45 12 23 45), undef]],
              ['13:23:45', 'hms', [], 1, [qw(13:23:45 13 23 45), undef]],
              ['23:23:45', 'hms', [], 1, [qw(23:23:45 23 23 45), undef]],
              ['24:34:45', 'hms', [], 0, ],
              ['25:46:45', 'hms', [], 0, ],
              ['99:46:45', 'hms', [], 0, ],
              # Minute limits
              ['10:00:45am', 'hms', [], 1, [qw(10:00:45am 10 00 45 am)]],
              ['10:59:45am', 'hms', [], 1, [qw(10:59:45am 10 59 45 am)]],
              ['10:60:45am', 'hms', [], 0, ],
              # No second limits!  Because out-of-range means no match; must catch in normalize_hms.
              # Optional seconds
              ['10:23am', 'hms', [], 1, [qw(10:23am 10 23), undef, qw(am)]],
              # Optional am/pm
              ['10:23:45', 'hms', [], 1, [qw(10:23:45 10 23 45), undef]],
              # Optional both
              ['10:23', 'hms', [], 1, [qw(10:23 10 23), undef, undef]],

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
