#!/usr/bin/env perl
use Test::Simple tests => 2;

if (!eval q{ require Test::Without::Module;1 }) {
    ok(1, 'Test::Without::Module not installed.');
    ok(2, 'Test::Without::Module not installed.');
    exit 0;
}

my $str;
$str .= "use Test::Without::Module '$_';" for qw{
Devel::Peek
Devel::Size
IO::Scalar
Lexical::Persistence
LWP::Simple
Module::CoreList
Module::Info
PadWalker
BSD::Resource
Time::HiRes
};
eval $str;
my $res = eval q{use Time::HiRes;1};
ok(!$res, "Test::Without::Module works.");
$res = eval "use Sepia;1";
ok($res && !$@, "loads without optional prereqs? ($res, $@)");
