use TAP::Stream;
use Test::Most;

#
# Failing tests
#

my $stream = create_stream(<<'END' );
ok 1 - foo 1
not ok 2 - foo 2
1..2
END

chomp( my $expected = <<'END' );
    ok 1 - foo 1
    not ok 2 - foo 2
    1..2
not ok 1 - some tests
# Failed 1 out of 2 tests
1..1
END
eq_or_diff $stream->to_string, $expected,
  'If we add TAP with a failing test, the subtest should fail';

#
# Failing TODO tests
#

$stream = create_stream(<<'END' );
ok 1 - foo 1
not ok 2 - foo 2 # TODO ignore
1..2
END

chomp( $expected = <<'END' );
    ok 1 - foo 1
    not ok 2 - foo 2 # TODO ignore
    1..2
ok 1 - some tests
1..1
END
eq_or_diff $stream->to_string, $expected,
  '... but failing TODO tests are should not be failures';

#
# Bad plan
#

$stream = create_stream(<<'END' );
1..3
ok 1 - foo 1
ok 2 - foo 2
END

chomp( $expected = <<'END' );
    1..3
    ok 1 - foo 1
    ok 2 - foo 2
not ok 1 - some tests
# Planned 3 tests and found 2 tests
1..1
END
eq_or_diff $stream->to_string, $expected,
  'Bad plans (wrong number of tests) should fail';

#
# Multiple plans
#

$stream = create_stream(<<'END' );
1..2
ok 1 - foo 1
ok 2 - foo 2
1..2
END

chomp( $expected = <<'END' );
    1..2
    ok 1 - foo 1
    ok 2 - foo 2
    1..2
not ok 1 - some tests
# 2 plans found
1..1
END
eq_or_diff $stream->to_string, $expected,
  'Multiple plans should fail';

#
# Misplaced plan
#

$stream = create_stream(<<'END' );
ok 1 - foo 1
1..2
ok 2 - foo 2
END

chomp( $expected = <<'END' );
    ok 1 - foo 1
    1..2
    ok 2 - foo 2
not ok 1 - some tests
# No plan found
1..1
END
eq_or_diff $stream->to_string, $expected,
  'A plan anywhere but at the beginning or end of the TAP stream should fail';

#
# No plan
#

$stream = create_stream(<<'END' );
ok 1 - foo 1
ok 2 - foo 2
END

chomp( $expected = <<'END' );
    ok 1 - foo 1
    ok 2 - foo 2
not ok 1 - some tests
# No plan found
1..1
END
eq_or_diff $stream->to_string, $expected,
  'Missing plans should fail';

#
# Missing test numbers
#

$stream = create_stream(<<'END' );
1..2
ok - foo 1
ok - foo 2
END

chomp( $expected = <<'END' );
    1..2
    ok - foo 1
    ok - foo 2
ok 1 - some tests
1..1
END
eq_or_diff $stream->to_string, $expected,
  'Missing test numbers are allowed (they are optional in TAP)';

#
# Test numbers out of order
#

$stream = create_stream(<<'END' );
1..2
ok 2 - foo 1
ok 1 - foo 2
END

chomp( $expected = <<'END' );
    1..2
    ok 2 - foo 1
    ok 1 - foo 2
not ok 1 - some tests
# Tests out of sequence
1..1
END

TODO: {
    local $TODO = 'Out-of-sequence test numbers are not yet checked';
    eq_or_diff $stream->to_string, $expected,
      'Tests out of sequence should fail';
}

done_testing;

sub create_stream {
    my $tap = shift;

    my $stream = TAP::Stream->new;
    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'some tests', text => $tap ) );
    return $stream;
}
