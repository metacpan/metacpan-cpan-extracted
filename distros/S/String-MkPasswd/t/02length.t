use Test::More tests => 22;
BEGIN { use_ok('String::MkPasswd') };

String::MkPasswd->import("mkpasswd");

ok(length mkpasswd(-length => 0) == 9, "length = 0");

for ( 1 .. 6 ) {
	ok(!defined mkpasswd(-length => $_), "length = $_");
}

for ( 7 .. 20 ) {
	ok(length mkpasswd(-length => $_) == $_, "length = $_");
}
