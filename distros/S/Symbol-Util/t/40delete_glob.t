#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 63;

use Symbol::Util 'delete_glob';

{
    package Symbol::Util::Test40;
    no warnings 'once';
    open FOO, __FILE__ or die $!;
    *FOO = sub { "code" };
    our $FOO = "scalar";
    our @FOO = ("array");
    our %FOO = ("hash" => 1);
};

foreach my $slot (qw{ SCALAR ARRAY HASH CODE IO }) {
    ok( defined *Symbol::Util::Test40::FOO{$slot}, "defined *Symbol::Util::Test40::FOO{$slot}" );
};
is( $Symbol::Util::Test40::FOO, "scalar", '$Symbol::Util::Test40::FOO is ok [1]' );
is_deeply( \@Symbol::Util::Test40::FOO, ["array"], '@Symbol::Util::Test40::FOO is ok [1]' );
is_deeply( \%Symbol::Util::Test40::FOO, {"hash"=>1}, '%Symbol::Util::Test40::FOO is ok [1]' );
is( eval { &Symbol::Util::Test40::FOO }, 'code', '&Symbol::Util::Test40::FOO is ok [1]' );
ok( fileno Symbol::Util::Test40::FOO, '*Symbol::Util::Test40::FOO{IO} is ok [1]' );

ok( defined delete_glob("Symbol::Util::Test40::FOO", "SCALAR"), 'delete_glob("Symbol::Util::Test40::FOO", "SCALAR")' );
ok( ! defined $Symbol::Util::Test40::FOO, '$Symbol::Util::Test40::FOO is ok [2]' );
is_deeply( \@Symbol::Util::Test40::FOO, ["array"], '@Symbol::Util::Test40::FOO is ok [2]' );
is_deeply( \%Symbol::Util::Test40::FOO, {"hash"=>1}, '%Symbol::Util::Test40::FOO is ok [2]' );
is( eval { &Symbol::Util::Test40::FOO }, 'code', '&Symbol::Util::Test40::FOO is ok [2]' );
ok( fileno Symbol::Util::Test40::FOO, '*Symbol::Util::Test40::FOO{IO} is ok [2]' );

ok( defined delete_glob("Symbol::Util::Test40::FOO", "ARRAY", "HASH"), 'delete_glob("Symbol::Util::Test40::FOO", "ARRAY", "HASH")' );
ok( ! defined $Symbol::Util::Test40::FOO, '$Symbol::Util::Test40::FOO is ok [3]' );
ok( ! @Symbol::Util::Test40::FOO, '@Symbol::Util::Test40::FOO is ok [3]' );
ok( ! %Symbol::Util::Test40::FOO, '%Symbol::Util::Test40::FOO is ok [3]' );
is( eval { &Symbol::Util::Test40::FOO }, 'code', '&Symbol::Util::Test40::FOO is ok [3]' );
ok( fileno Symbol::Util::Test40::FOO, '*Symbol::Util::Test40::FOO{IO} is ok [3]' );

ok( defined delete_glob("Symbol::Util::Test40::FOO", "CODE"), 'delete_glob("Symbol::Util::Test40::FOO", "CODE")' );
ok( ! defined $Symbol::Util::Test40::FOO, '$Symbol::Util::Test40::FOO is ok [4]' );
ok( ! @Symbol::Util::Test40::FOO, '@Symbol::Util::Test40::FOO is ok [4]' );
ok( ! %Symbol::Util::Test40::FOO, '%Symbol::Util::Test40::FOO is ok [4]' );
ok( ! eval { &Symbol::Util::Test40::FOO }, '&Symbol::Util::Test40::FOO is ok [4]' );
ok( fileno Symbol::Util::Test40::FOO, '*Symbol::Util::Test40::FOO{IO} is ok [4]' );

ok( defined delete_glob("Symbol::Util::Test40::FOO", "IO"), 'delete_glob("Symbol::Util::Test40::FOO", "IO")' );
ok( ! defined $Symbol::Util::Test40::FOO, '$Symbol::Util::Test40::FOO is ok [5]' );
ok( ! @Symbol::Util::Test40::FOO, '@Symbol::Util::Test40::FOO is ok [5]' );
ok( ! %Symbol::Util::Test40::FOO, '%Symbol::Util::Test40::FOO is ok [5]' );
ok( ! eval { &Symbol::Util::Test40::FOO }, '&Symbol::Util::Test40::FOO is ok [5]' );
ok( ! fileno Symbol::Util::Test40::FOO, '*Symbol::Util::Test40::FOO{IO} is ok [5]' );

{
    package Symbol::Util::Test40;
    no warnings 'once';
    open BAR, __FILE__ or die $!;
    *BAR = sub { "code" };
    our $BAR = "scalar";
    our @BAR = ("array");
    our %BAR = ("hash" => 1);
};

foreach my $slot (qw{ SCALAR ARRAY HASH CODE IO }) {
    ok( defined *Symbol::Util::Test40::BAR{$slot}, "defined *Symbol::Util::Test40::BAR{$slot}" );
};
is( $Symbol::Util::Test40::BAR, "scalar", '$Symbol::Util::Test40::BAR is ok [1]' );
is_deeply( \@Symbol::Util::Test40::BAR, ["array"], '@Symbol::Util::Test40::BAR is ok [1]' );
is_deeply( \%Symbol::Util::Test40::BAR, {"hash"=>1}, '%Symbol::Util::Test40::BAR is ok [1]' );
is( eval { &Symbol::Util::Test40::BAR }, 'code', '&Symbol::Util::Test40::BAR is ok [1]' );
ok( fileno Symbol::Util::Test40::BAR, '*Symbol::Util::Test40::BAR{IO} is ok [1]' );

ok( defined delete_glob("Symbol::Util::Test40::BAR", "IO"), 'delete_glob("Symbol::Util::Test40::BAR", "IO")' );
is( $Symbol::Util::Test40::BAR, "scalar", '$Symbol::Util::Test40::BAR is ok [2]' );
is_deeply( \@Symbol::Util::Test40::BAR, ["array"], '@Symbol::Util::Test40::BAR is ok [2]' );
is_deeply( \%Symbol::Util::Test40::BAR, {"hash"=>1}, '%Symbol::Util::Test40::BAR is ok [2]' );
is( eval { &Symbol::Util::Test40::BAR }, 'code', '&Symbol::Util::Test40::BAR is ok [2]' );
ok( ! fileno Symbol::Util::Test40::BAR, '*Symbol::Util::Test40::BAR{IO} is ok [2]' );

{
    package Symbol::Util::Test40;
    Test::More::ok( defined Symbol::Util::delete_glob("BAR", "SCALAR"), 'Symbol::Util::delete_glob("BAR", "SCALAR")' );
}
ok( ! defined $Symbol::Util::Test40::BAR, '$Symbol::Util::Test40::BAR is ok [3]' );
is_deeply( \@Symbol::Util::Test40::BAR, ["array"], '@Symbol::Util::Test40::BAR is ok [3]' );
is_deeply( \%Symbol::Util::Test40::BAR, {"hash"=>1}, '%Symbol::Util::Test40::BAR is ok [3]' );
is( eval { &Symbol::Util::Test40::BAR }, 'code', '&Symbol::Util::Test40::BAR is ok [3]' );
ok( ! fileno Symbol::Util::Test40::BAR, '*Symbol::Util::Test40::BAR{IO} is ok [3]' );

ok( ! defined delete_glob("Symbol::Util::Test40::BAR"), 'delete_glob("Symbol::Util::Test40::BAR") [1]' );
ok( ! defined $Symbol::Util::Test40::BAR, '$Symbol::Util::Test40::BAR is ok [4]' );
ok( ! @Symbol::Util::Test40::BAR, '@Symbol::Util::Test40::BAR is ok [4]' );
ok( ! %Symbol::Util::Test40::BAR, '%Symbol::Util::Test40::BAR is ok [4]' );
ok( ! eval { &Symbol::Util::Test40::BAR }, '&Symbol::Util::Test40::BAR is ok [4]' );
ok( ! fileno Symbol::Util::Test40::BAR, '*Symbol::Util::Test40::BAR{IO} is ok [4]' );

ok( ! defined delete_glob("Symbol::Util::Test40::BAR"), 'delete_glob("Symbol::Util::Test40::BAR") [2]' );
