use Test::More tests => 13;

BEGIN {
use_ok( 'String::ZeroButTrue' );
}

diag( "Testing String::ZeroButTrue $String::ZeroButTrue::VERSION" );

ok(is_zero_but_true('0e0'), 'sees 0e0 as zero but true');
ok(is_zero_but_true('0E0'), 'sees 0E0 as zero but true');
ok(is_zero_but_true('0 but true'), 'sees "0 but true" as zero but true');
ok(is_zero_but_true('0 BuT trUe'), 'sees "0 but true" (mixed case) as zero but true');

ok(!is_zero_but_true(), 'is_zero_but_true no arg');
ok(!is_zero_but_true(''), 'is_zero_but_true empty string arg');
ok(!is_zero_but_true(0), 'is_zero_but_true 0 arg');
ok(!is_zero_but_true(undef), 'is_zero_but_true explicit undef arg');
ok(!is_zero_but_true('message for you sir'), 'is_zero_but_true string arg');

ok(get_zero_but_true() eq '0e0', 'get_zero_but_true() returns correct string');
ok(String::ZeroButTrue::get_zero_but_true_uc() eq '0E0', 'get_zero_but_true_uc() returns correct string');
ok(String::ZeroButTrue::get_zero_but_true_phrase() eq '0 but true', 'get_zero_but_true_phrase() returns correct string');
