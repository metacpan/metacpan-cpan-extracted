use Test;
BEGIN { plan tests => 4 };
use Net::MySQL;

ok(Net::MySQL::Password32->scramble('', 'nextsalt', 0) eq '');
ok(Net::MySQL::Password32->scramble('', 'newsalt',  1) eq '');
ok(Net::MySQL::Password32->scramble('password', 'saltcode', 0) eq '\\WBDNZ\\@');
ok(Net::MySQL::Password32->scramble('yourpassword', 'nextsalt', 1) eq 'ZKBTUFLS');
