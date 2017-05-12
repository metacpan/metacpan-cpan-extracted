use Test::Most;
use TAP::Stream;
use TAP::Stream::Text;

my $tap1 = <<'END';
ok 1 - foo 1
ok 2 - foo 2
1..2
END

my $tap2 = <<'END';
ok 1 - bar 1
ok 2 - bar 2
    1..3
    ok 1 - bar subtest 1
    ok 2 - bar subtest 2
    not ok 3 - bar subtest 3 #TODO ignore
ok 3 - bar subtest
not ok 4 - bar 4
1..4
END

my $stream = TAP::Stream->new;

$stream->add_to_stream(
    TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
    TAP::Stream::Text->new( name => 'bar tests', text => $tap2 ),
);

chomp( my $expected = <<'END' );
    ok 1 - foo 1
    ok 2 - foo 2
    1..2
ok 1 - foo tests
    ok 1 - bar 1
    ok 2 - bar 2
        1..3
        ok 1 - bar subtest 1
        ok 2 - bar subtest 2
        not ok 3 - bar subtest 3 #TODO ignore
    ok 3 - bar subtest
    not ok 4 - bar 4
    1..4
not ok 2 - bar tests
# Failed 1 out of 4 tests
1..2
END

eq_or_diff $stream->to_string, $expected,
    'The code listed in our synopsis works.';

done_testing;
