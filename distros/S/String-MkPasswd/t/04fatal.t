use Test::More tests => 5;
BEGIN { use_ok('String::MkPasswd') };

String::MkPasswd->import("mkpasswd");

$String::MkPasswd::FATAL = 0;

eval { mkpasswd(-fatal => 1) };
is($@, "", "not fatal, flag");

eval { mkpasswd(-length => 1, -fatal => 1) };
isnt($@, "", "fatal, flag");

$String::MkPasswd::FATAL = 1;

eval { mkpasswd() };
is($@, "", "not fatal, global");

eval { mkpasswd(-length => 1) };
isnt($@, "", "fatal, global");
