#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 24;

use Symbol::Util 'delete_sub';

{
    package Symbol::Util::Test50;
    no warnings 'once';
    open FOO, __FILE__ or die $!;
    *FOO = sub { "code" };
    our $FOO = "scalar";
    our @FOO = ("array");
    our %FOO = ("hash" => 1);
};

foreach my $slot (qw{ SCALAR ARRAY HASH CODE IO }) {
    ok( defined *Symbol::Util::Test50::FOO{$slot}, "defined *Symbol::Util::Test50::FOO{$slot}" );
};

is( eval { Symbol::Util::Test50->FOO }, 'code', 'Symbol::Util::Test50->FOO is ok [1]' );
is( eval { &Symbol::Util::Test50::FOO }, 'code', '&Symbol::Util::Test50::FOO is ok [1]' );
is( $Symbol::Util::Test50::FOO, "scalar", '$Symbol::Util::Test50::FOO is ok [1]' );
is_deeply( \@Symbol::Util::Test50::FOO, ["array"], '@Symbol::Util::Test50::FOO is ok [1]' );
is_deeply( \%Symbol::Util::Test50::FOO, {"hash"=>1}, '%Symbol::Util::Test50::FOO is ok [1]' );
ok( fileno Symbol::Util::Test50::FOO, '*Symbol::Util::Test50::FOO{IO} is ok [1]' );

{
    package Symbol::Util::Test50;
    Test::More::ok( defined Symbol::Util::delete_sub("FOO"), 'Symbol:Util::delete_sub("Test50::FOO [1]")' );
};

ok( ! eval { Symbol::Util::Test50->FOO }, 'Can\'t locate method Symbol::Util::Test50->FOO' );
is( eval { &Symbol::Util::Test50::FOO }, 'code', '&Symbol::Util::Test50::FOO is ok [2]' );
is( $Symbol::Util::Test50::FOO, "scalar", '$Symbol::Util::Test50::FOO is ok [2]' );
is_deeply( \@Symbol::Util::Test50::FOO, ["array"], '@Symbol::Util::Test50::FOO is ok [2]' );
is_deeply( \%Symbol::Util::Test50::FOO, {"hash"=>1}, '%Symbol::Util::Test50::FOO is ok [2]' );
ok( fileno Symbol::Util::Test50::FOO, '*Symbol::Util::Test50::FOO{IO} is ok [2]' );

ok( ! defined delete_sub("Symbol::Util::Test50::FOO"), 'delete_sub("Symbol::Util::Test50::FOO [2]")' );

*FOO = sub { "code" };
is( eval { main->FOO }, 'code', 'main->FOO is ok [1]' );
is( eval { &main::FOO }, 'code', '&main::FOO is ok [1]' );

ok( ! defined delete_sub("::FOO"), 'delete_sub("::FOO")' );

ok( ! defined eval { main->FOO }, 'main->FOO is ok [2]' );
is( eval { &main::FOO }, 'code', '&main::FOO is ok [2]' );
