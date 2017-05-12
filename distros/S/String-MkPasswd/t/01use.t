use Test::More tests => 3;
BEGIN { use_ok('String::MkPasswd') };

my $passwd = String::MkPasswd::mkpasswd();

ok(defined $passwd, "defined");
ok(length $passwd > 0, "length");
