use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Net::ACME2::RetryAfter ();

# --- delay-seconds format ---

is( Net::ACME2::RetryAfter::parse(undef), undef, 'undef returns undef' );
is( Net::ACME2::RetryAfter::parse('0'), 0, 'delay-seconds: 0' );
is( Net::ACME2::RetryAfter::parse('120'), 120, 'delay-seconds: 120' );
is( Net::ACME2::RetryAfter::parse('3600'), 3600, 'delay-seconds: 3600' );

# --- non-parseable values ---

is( Net::ACME2::RetryAfter::parse('not-a-date'), undef, 'garbage returns undef' );
is( Net::ACME2::RetryAfter::parse(''), undef, 'empty string returns undef' );
is( Net::ACME2::RetryAfter::parse('-1'), undef, 'negative number returns undef' );

# --- HTTP-date: IMF-fixdate ---

{
    # Use a date far in the future so the delta is positive
    my $seconds = Net::ACME2::RetryAfter::parse('Sun, 06 Nov 2044 08:49:37 GMT');
    ok( defined $seconds, 'IMF-fixdate: returns defined value for future date' );
    ok( $seconds > 0, 'IMF-fixdate: future date yields positive seconds' );
}

{
    # A date in the past should return 0
    my $seconds = Net::ACME2::RetryAfter::parse('Sun, 06 Nov 1994 08:49:37 GMT');
    is( $seconds, 0, 'IMF-fixdate: past date yields 0' );
}

# --- HTTP-date: RFC 850 ---

{
    my $seconds = Net::ACME2::RetryAfter::parse('Sunday, 06-Nov-44 08:49:37 GMT');
    ok( defined $seconds, 'RFC 850: returns defined value for future date' );
    ok( $seconds > 0, 'RFC 850: future date yields positive seconds' );
}

{
    my $seconds = Net::ACME2::RetryAfter::parse('Sunday, 06-Nov-94 08:49:37 GMT');
    is( $seconds, 0, 'RFC 850: past date yields 0' );
}

# --- HTTP-date: asctime ---

{
    my $seconds = Net::ACME2::RetryAfter::parse('Sun Nov  6 08:49:37 2044');
    ok( defined $seconds, 'asctime: returns defined value for future date' );
    ok( $seconds > 0, 'asctime: future date yields positive seconds' );
}

{
    my $seconds = Net::ACME2::RetryAfter::parse('Sun Nov  6 08:49:37 1994');
    is( $seconds, 0, 'asctime: past date yields 0' );
}

# --- Verify delay-seconds returns exact integer (no date parsing) ---

{
    my $result = Net::ACME2::RetryAfter::parse('42');
    is( $result, 42, 'delay-seconds: exact integer returned' );
}

done_testing();
